import Foundation
import WebRTC

public class MediaOption {
    
    public var videoEnabled: Bool = true
    public var audioEnabled: Bool = true
    public var configuration: RTCConfiguration?
    public var signalingAnswerMediaConstraints: RTCMediaConstraints?
    public var videoCaptureSourceMediaConstraints: RTCMediaConstraints?
    public var peerConnectionMediaConstraints: RTCMediaConstraints?
    public var videoCaptureTrackId: String?
    public var audioCaptureTrackId: String?
    
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
 
    public static var defaultVideoCaptureTrackId: String = "mainVideoCaptureTrack"
    public static var defaultAudioCaptureTrackId: String = "mainAudioCaptureTrack"

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
    
    public var connection: Connection
    public weak var mediaChannel: MediaChannel!
    public var mediaStream: MediaStream?
    public var mediaOption: MediaOption?
    
    private var _state: State
    
    public var state: State {
        get {
            return _state
        }
        set {
            _state = newValue
            onChangeStateHandler?(state)
        }
    }
    
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
    
    init(connection: Connection,
         mediaChannel: MediaChannel,
         mediaOption: MediaOption?) {
        self.connection = connection
        self.mediaChannel = mediaChannel
        self.mediaOption = mediaOption
        _state = .disconnected
    }
    
    func role() -> Role {
        assertionFailure("subclass must implement role()")
        return Role.upstream
    }
    
    // MARK: 接続
    
    public func connect(accessToken: String? = nil,
                        mediaStreamId: String? = nil,
                        handler: @escaping ((ConnectionError?) -> Void)) {
        state = .connecting
        mediaStream = MediaStream(connection: connection,
                                  mediaConnection: self,
                                  role: role(),
                                  accessToken: accessToken,
                                  mediaStreamId: mediaStreamId,
                                  mediaOption: mediaOption)
        mediaStream!.connect {
            peerConn, error in
            if let error = error {
                self.state = .disconnected
                self.mediaStream = nil
                self.onFailureHandler?(error)
                self.mediaChannel.onMediaConnectionFailureHandler?(self, error)
                self.onDisconnectHandler?(error)
                self.mediaChannel.onMediaConnectionDisconnectHandler?(self, error)
            } else {
                self.state = .connected
                self.onConnectHandler?(nil)
                self.mediaChannel.onMediaConnectionConnectHandler?(self, nil)
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
    
    private var onChangeStateHandler: ((State) -> Void)?
    private var onConnectHandler: ((ConnectionError?) -> Void)?
    private var onDisconnectHandler: ((ConnectionError?) -> Void)?
    private var onFailureHandler: ((ConnectionError) -> Void)?
    private var onUpdateHandler: ((Statistics) -> Void)?
    private var onNotifyHandler: ((Notification) -> Void)?

    public func onChangeState(handler: @escaping (State) -> Void) {
        onChangeStateHandler = handler
    }
    
    public func onConnect(handler: @escaping (ConnectionError?) -> Void) {
        onConnectHandler = handler
    }
    
    func callOnConnectHandler(error: ConnectionError?) {
        onConnectHandler?(error)
        mediaChannel.onMediaConnectionConnectHandler?(self, error)
    }
    
    public func onDisconnect(handler: @escaping (ConnectionError?) -> Void) {
        onDisconnectHandler = handler
    }
    
    func callOnDisonnectHandler(error: ConnectionError?) {
        onDisconnectHandler?(error)
        mediaChannel.onMediaConnectionDisconnectHandler?(self, error)
    }
    
    // この次に必ず onDisconnect が呼ばれる
    public func onFailure(handler: @escaping (ConnectionError) -> Void) {
        onFailureHandler = handler
    }
    
    func callOnFailureHandler(error: ConnectionError) {
        onFailureHandler?(error)
        mediaChannel.onMediaConnectionFailureHandler?(self, error)
    }
    
    public func onUpdate(handler: @escaping ((Statistics) -> Void)) {
        onUpdateHandler = handler
    }
    
    func callOnUpdateHandler(stats: Statistics) {
        onUpdateHandler?(stats)
        mediaChannel.onMediaConnectionUpdateHandler?(self, stats)
    }
    
    public func onNotify(handler: @escaping ((Notification) -> Void)) {
        onNotifyHandler = handler
    }
    
    func callOnNotifyHandler(notification: Notification) {
        onNotifyHandler?(notification)
        mediaChannel.onMediaConnectionNotifyHandler?(self, notification)
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
    
    init(factory: RTCPeerConnectionFactory, mediaOption: MediaOption?) {
        videoCaptureSource = factory
            .avFoundationVideoSource(with:
                mediaOption?.videoCaptureSourceMediaConstraints ??
                    MediaOption.defaultMediaConstraints)
        videoCaptureTrack = factory
            .videoTrack(with: videoCaptureSource,
                        trackId: mediaOption?.videoCaptureTrackId ??
                            MediaOption.defaultVideoCaptureTrackId)
        audioCaptureTrack = factory
            .audioTrack(withTrackId: mediaOption?.audioCaptureTrackId ??
                MediaOption.defaultAudioCaptureTrackId)
    }
    
}

public enum CameraPosition {
    case front
    case back
}

public class MediaPublisher: MediaConnection {
    
    public var videoPreset: VideoPreset =  VideoPreset.vga
    
    public var mediaCapturer: MediaCapturer? {
        get { return mediaStream?.mediaCapturer }
    }

    public var canUseBackCamera: Bool {
        get { return mediaCapturer!.videoCaptureSource.canUseBackCamera }
    }
    
    public var captureSession: AVCaptureSession {
        get { return mediaCapturer!.videoCaptureSource.captureSession }
    }
    
    var eventLog: EventLog {
        get { return mediaChannel.connection.eventLog }
    }
    
    override func role() -> Role {
        return .upstream
    }
    
    public func switchCamera(_ position: CameraPosition? = nil) {
        eventLog.markFormat(type: .MediaConnection,
                            format: "switch camera to %@",
                            arguments: position.debugDescription)
        switch position {
        case nil:
            mediaCapturer!.videoCaptureSource.useBackCamera =
                !mediaCapturer!.videoCaptureSource.useBackCamera
        case CameraPosition.front?:
            mediaCapturer!.videoCaptureSource.useBackCamera = false
        case CameraPosition.back?:
            mediaCapturer!.videoCaptureSource.useBackCamera = true
        }
    }
    
}

public class MediaSubscriber: MediaConnection {
    
    override func role() -> Role {
        return .downstream
    }
    
}
