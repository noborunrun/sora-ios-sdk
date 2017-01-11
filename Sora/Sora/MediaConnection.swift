import Foundation
import WebRTC

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
    
    public weak var connection: Connection!
    public var peerConnection: PeerConnection?
    public var mediaOption: MediaOption = MediaOption()
    public var multistreamEnabled: Bool = false
    public var mediaStreams: [MediaStream] = []
    
    public var state: State {
        willSet {
            onChangeStateHandler?(newValue)
        }
    public var mainMediaStream: MediaStream? {
        get { return mediaStreams.first }
    }

    public var webSocketEventHandlers: WebSocketEventHandlers?
    public var signalingEventHandlers: SignalingEventHandlers?
    public var peerConnectionEventHandlers: PeerConnectionEventHandlers?
    
    public var isAvailable: Bool {
        get { return state == .connected }
    }
    
    public var videoRenderer: VideoRenderer? {
        get { return peerConnection?.videoRenderer }
        set { peerConnection?.videoRenderer = newValue }
    }
    
    var eventLog: EventLog {
        get { return connection.eventLog }
    }
    
    var eventType: Event.EventType {
        get {
            assert(false, "must be override")
            return .MediaPublisher
        }
    }
    
    var role: MediaStreamRole {
        get {
            assertionFailure("subclass must implement role()")
            return .upstream
        }
    }
    
    init(connection: Connection) {
        self.connection = connection
        state = .disconnected
    }
    
    // MARK: 接続
    
    public func connect(accessToken: String? = nil,
                        timeout: Int = 30,
                        handler: @escaping ((ConnectionError?) -> Void)) {
        state = .connecting
        peerConnection = PeerConnection(connection: connection,
                                        mediaConnection: self,
                                        role: role,
                                        accessToken: accessToken,
                                        mediaStreamId: nil,
                                        mediaOption: mediaOption)
        peerConnection!.connect(timeout: timeout) {
            error in
            if let error = error {
                self.state = .disconnected
                self.peerConnection = nil
                self.onFailureHandler?(error)
                self.onConnectHandler?(error)
                handler(error)
            } else {
                self.state = .connected
                self.onConnectHandler?(nil)
                handler(nil)
            }
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
            stopConnectionTimer()
            for stream in mediaStreams {
                stream.terminate()
            }
            mediaStreams = []
            peerConnection!.disconnect {
                error in
                self.state = .disconnected
                handler(error)
            }
        }
    }
    
    public func send(message: Messageable) -> ConnectionError? {
        if isAvailable {
            return peerConnection!.send(message: message)
        } else {
            return ConnectionError.connectionDisconnected
        }
    }
    
    // MARK: マルチストリーム
    
    func addMediaStream(mediaStream: MediaStream) {
        mediaStreams.append(mediaStream)
    }
    
    func removeMediaStream(mediaStreamId: String) {
        mediaStreams = mediaStreams.filter {
            e in
            return e.mediaStreamId != mediaStreamId
        }
    }
    
    // MARK: イベントハンドラ
    
    var onChangeStateHandler: ((State) -> Void)?
    var onConnectHandler: ((ConnectionError?) -> Void)?
    var onDisconnectHandler: ((ConnectionError?) -> Void)?
    var onFailureHandler: ((ConnectionError) -> Void)?
    var onUpdateHandler: ((Statistics) -> Void)?
    var onNotifyHandler: ((Notification) -> Void)?

    public func onChangeState(handler: @escaping (State) -> Void) {
        onChangeStateHandler = handler
    }
    
    public func onConnect(handler: @escaping (ConnectionError?) -> Void) {
        onConnectHandler = handler
    }
    
    public func onDisconnect(handler: @escaping (ConnectionError?) -> Void) {
        onDisconnectHandler = handler
    }
    
    public func onFailure(handler: @escaping (ConnectionError) -> Void) {
        onFailureHandler = handler
    }
    
    public func onUpdate(handler: @escaping ((Statistics) -> Void)) {
        onUpdateHandler = handler
    }
    
    public func onNotify(handler: @escaping ((Notification) -> Void)) {
        onNotifyHandler = handler
    }
    
}

class MediaCapturer {
    
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

public enum CameraPosition: String {
    case front
    case back
    
    public func flip() -> CameraPosition {
        switch self {
        case .front: return .back
        case .back: return .front
        }
    }
    
}

public class MediaPublisher: MediaConnection {
    
    public var canUseBackCamera: Bool? {
        get { return mediaCapturer?.videoCaptureSource.canUseBackCamera }
    }
    
    public var captureSession: AVCaptureSession? {
        get { return mediaCapturer?.videoCaptureSource.captureSession }
    }
    
    var _cameraPosition: CameraPosition?
    
    public var cameraPosition: CameraPosition? {
        
        get {
            if mediaCapturer != nil {
                if _cameraPosition == nil {
                    _cameraPosition = .front
                }
            } else {
                _cameraPosition = nil
            }
            return _cameraPosition
        }
        
        set {
            if let capturer = mediaCapturer {
                if let value = newValue {
                    eventLog.markFormat(type: eventType,
                                        format: "switch camera to %@",
                                        arguments: value.rawValue)
                    switch value {
                    case .front:
                        capturer.videoCaptureSource.useBackCamera = false
                    case .back:
                        capturer.videoCaptureSource.useBackCamera = true
                    }
                    _cameraPosition = newValue
                }
            }
        }
        
    }
    
    override var eventType: Event.EventType {
        get { return .MediaPublisher }
    }
    
    override var role: MediaStreamRole {
        get { return .upstream }
    }
    
    var mediaCapturer: MediaCapturer? {
        get { return peerConnection?.mediaCapturer }
    }

    public func flipCameraPosition() {
        cameraPosition = cameraPosition?.flip()
    }
    
}

public class MediaSubscriber: MediaConnection {
    
    override var role: MediaStreamRole {
        get { return .downstream }
    }
    
}
