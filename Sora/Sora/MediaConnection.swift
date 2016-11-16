import Foundation
import WebRTC

public class MediaOption {
    
    public var videoEnabled: Bool
    public var audioEnabled: Bool
    public var configuration: RTCConfiguration
    public var signalingAnswerMediaConstraints: RTCMediaConstraints
    public var videoCaptureSourceMediaConstraints: RTCMediaConstraints
    public var peerConnectionMediaConstraints: RTCMediaConstraints

    public static var defaultConfiguration: RTCConfiguration = {
        () -> RTCConfiguration in
        let config = RTCConfiguration()
        config.iceServers = [
            RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"],
                username: nil, credential: nil)]
        return config
    }()
    
    public static var defaultMediaConstraints: RTCMediaConstraints =
        RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
    
    public init(videoEnabled: Bool = true, audioEnabled: Bool = true,
                configuration: RTCConfiguration? = nil,
                signalingAnswerMediaConstraints: RTCMediaConstraints? = nil,
                videoCaptureSourceMediaConstraints: RTCMediaConstraints? = nil,
                peerConnectionMediaConstraints: RTCMediaConstraints? = nil) {
        self.videoEnabled = videoEnabled
        self.audioEnabled = audioEnabled
        self.configuration = configuration ?? MediaOption.defaultConfiguration
        self.signalingAnswerMediaConstraints = signalingAnswerMediaConstraints
            ?? MediaOption.defaultMediaConstraints
        self.videoCaptureSourceMediaConstraints = videoCaptureSourceMediaConstraints
            ?? MediaOption.defaultMediaConstraints
        self.peerConnectionMediaConstraints = peerConnectionMediaConstraints
            ?? MediaOption.defaultMediaConstraints
    }
    
}

public class MediaConnection {
    
    public enum State {
        case connected
        case connecting
        case disconnected
        case disconnecting
    }
    
    public struct Statistics {
        
        public var numberOfUpstreamConnections: Int?
        public var numberOfDownstreamConnections: Int?
        
        init(signalingStats: SignalingStats) {
            self.numberOfUpstreamConnections = signalingStats.numberOfUpstreamConnections
            self.numberOfDownstreamConnections = signalingStats.numberOfUpstreamConnections
        }
        
    }
    
    public enum Notification: String {
        case disconnectedUpstream = "DISCONNECTED-UPSTREAM"
    }
    
    public weak var mediaChannel: MediaChannel!
    public var mediaChannelId: String
    public var mediaStream: MediaStream?
    public var mediaOption: MediaOption?
    public var state: State
    
    public var webSocketEventHandlers: WebSocketEventHandlers?
    public var signalingEventHandlers: SignalingEventHandlers?
    public var peerConnectionEventHandlers: PeerConnectionEventHandlers?
    
    public var isAvailable: Bool {
        get { return state == .connected }
    }
    
    public var videoRenderer: VideoRenderer? {
        willSet {
            self.mediaStream?.setVideoRenderer(newValue)
        }
    }
    
    init(mediaChannel: MediaChannel,
         mediaChannelId: String,
         mediaOption: MediaOption?) {
        self.mediaChannel = mediaChannel
        self.mediaChannelId = mediaChannelId
        self.mediaOption = mediaOption
        state = .disconnected
    }
    
    func role() -> Role {
        assertionFailure("subclass must implement role()")
        return Role.upstream
    }
    
    public func connect(accessToken: String? = nil,
                        mediaStreamId: String? = nil,
                        handler: @escaping ((Error?) -> Void)) {
        state = .connecting
        mediaStream = MediaStream(mediaConnection: self,
                                  role: role(),
                                  mediaChannelId: mediaChannelId,
                                  accessToken: accessToken,
                                  mediaStreamId: mediaStreamId,
                                  mediaOption: mediaOption)
        mediaStream!.connect {
            error in
            if let error = error {
                self.state = .disconnected
                self.mediaStream = nil
                self.onFailureHandler?(error)
                self.onDisconnectHandler?()
            } else {
                self.state = .connected
                self.onConnectHandler?()
            }
            handler(error)
        }
    }
    
    public func disconnect(handler: @escaping (ConnectionError?) -> Void) {
        switch state {
        case .disconnected:
            handler(ConnectionError.connectionDisconnected)
        case .disconnecting:
            handler(ConnectionError.connectionBusy)
        case .connected, .connecting:
            state = .disconnecting
            mediaStream!.disconnect {
                error in
                self.state = .disconnected
                handler(error)
            }
        }
    }
    
    public func send(messageable: Messageable) -> ConnectionError? {
        if isAvailable {
            return mediaStream!.send(messageable: messageable)
        } else {
            return ConnectionError.connectionDisconnected
        }
    }
    
    // MARK: タイマー
    
    var connectionTimer: Timer?
    var connectionTimerHandler: ((Int) -> Void)?
    
    @available(iOS 10.0, *)
    public func startConnectionTimer(timeInterval: TimeInterval,
                                     handler: @escaping ((Int) -> Void)) {
        connectionTimerHandler = handler
        connectionTimer?.invalidate()
        connectionTimer = Timer(timeInterval: timeInterval, repeats: true) {
            timer in
            if let stream = self.mediaStream {
                if stream.isAvailable {
                    let diff = Date(timeIntervalSinceNow: 0)
                        .timeIntervalSince(stream.creationTime!)
                    handler(Int(diff))
                }
            }
        }
        RunLoop.main.add(connectionTimer!, forMode: .commonModes)
        RunLoop.main.run()
    }
    
    @available(iOS 10.0, *)
    public func stopConnectionTimer() {
        connectionTimer?.invalidate()
    }
    
    
    // MARK: 統計情報
    
    public func statisticsReports(level: StatisticsReport.Level)
        -> ([StatisticsReport], [StatisticsReport])
    {
        if !isAvailable {
            return ([], [])
        }
        
        func getReports(track: RTCMediaStreamTrack) -> [StatisticsReport] {
            var reports: [StatisticsReport] = []
            mediaStream!.peerConnection!
                .stats(for: track, statsOutputLevel: level.nativeOutputLevel) {
                nativeReports in
                for nativeReport in nativeReports {
                    if let report = StatisticsReport.parse(report: nativeReport) {
                        reports.append(report)
                    }
                }
            }
            return reports
        }
        
        var videoReports: [StatisticsReport] = []
        if let track = mediaStream!.nativeVideoTrack {
            videoReports = getReports(track: track)
        }
        
        var audioReports: [StatisticsReport] = []
        if let track = mediaStream!.nativeAudioTrack {
            audioReports = getReports(track: track)
        }
        
        return (videoReports, audioReports)
    }

    // MARK: イベントハンドラ
    
    var onConnectHandler: ((Void) -> Void)?
    var onDisconnectHandler: ((Void) -> Void)?
    var onFailureHandler: ((ConnectionError) -> Void)?
    var onUpdateHandler: ((Statistics) -> Void)?
    var onNotifyHandler: ((Notification) -> Void)?

    public func onConnect(handler: @escaping ((Void) -> Void)) {
        onConnectHandler = handler
    }
    
    public func onDisconnect(handler: @escaping ((Void) -> Void)) {
        onDisconnectHandler = handler
    }
    
    // この次に必ず onDisconnect が呼ばれる
    public func onFailure(handler: @escaping ((ConnectionError) -> Void)) {
        onFailureHandler = handler
    }
    
    public func onUpdate(handler: @escaping ((Statistics) -> Void)) {
        onUpdateHandler = handler
    }
    
    public func onNotify(handler: @escaping ((Notification) -> Void)) {
        onNotifyHandler = handler
    }
    
}

public enum VideoPreset {
    case vga
    // TODO: etc.
}

public class MediaCapturer {
    
    public var videoCaptureTrack: RTCVideoTrack
    public var videoCaptureSource: RTCAVFoundationVideoSource
    public var audioCaptureTrack: RTCAudioTrack
    
    static var defaultVideoCaptureTrackId: String = "mainVideoCaptureTrack"
    static var defaultAudioCaptureTrackId: String = "mainAudioCaptureTrack"

    init(factory: RTCPeerConnectionFactory,
         videoCaptureSourceMediaConstraints: RTCMediaConstraints) {
        videoCaptureSource = factory
            .avFoundationVideoSource(with: videoCaptureSourceMediaConstraints)
        videoCaptureTrack = factory
            .videoTrack(with: videoCaptureSource,
                        trackId: MediaCapturer.defaultVideoCaptureTrackId)
        audioCaptureTrack = factory
            .audioTrack(withTrackId: MediaCapturer.defaultAudioCaptureTrackId)
    }
    
}

public enum CameraPosition {
    case front
    case back
}

public class MediaPublisher: MediaConnection {
    
    public var videoPreset: VideoPreset =  VideoPreset.vga
    public var mediaCapturer: MediaCapturer

    public var canUseBackCamera: Bool {
        get { return mediaCapturer.videoCaptureSource.canUseBackCamera }
    }
    
    public var captureSession: AVCaptureSession {
        get { return mediaCapturer.videoCaptureSource.captureSession }
    }
    
    init(mediaChannel: MediaChannel, mediaChannelId: String,
         mediaOption: MediaOption, mediaCapturer: MediaCapturer) {
        self.mediaCapturer = mediaCapturer
        mediaCapturer.videoCaptureSource.useBackCamera = false
        super.init(mediaChannel: mediaChannel,
                   mediaChannelId: mediaChannelId,
                   mediaOption: mediaOption)
    }
    
    override func role() -> Role {
        return .upstream
    }
    
    public func switchCamera(_ position: CameraPosition? = nil) {
        switch position {
        case nil:
            mediaCapturer.videoCaptureSource.useBackCamera =
                !mediaCapturer.videoCaptureSource.useBackCamera
        case CameraPosition.front?:
            mediaCapturer.videoCaptureSource.useBackCamera = false
        case CameraPosition.back?:
            mediaCapturer.videoCaptureSource.useBackCamera = true
        }
    }
    
}

public class MediaSubscriber: MediaConnection {
    
    override func role() -> Role {
        return .downstream
    }
    
}
