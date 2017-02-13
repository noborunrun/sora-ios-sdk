import Foundation
import WebRTC

public class MediaConnection {

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
    
    public var mainMediaStream: MediaStream? {
        get { return mediaStreams.first }
    }

    public var webSocketEventHandlers: WebSocketEventHandlers
        = WebSocketEventHandlers()
    public var signalingEventHandlers: SignalingEventHandlers
        = SignalingEventHandlers()
    public var peerConnectionEventHandlers: PeerConnectionEventHandlers
        = PeerConnectionEventHandlers()
    
    public var isAvailable: Bool {
        get { return peerConnection?.isAvailable ?? false }
    }
    
    var eventLog: EventLog? {
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
    }
    
    // MARK: 接続
    
    public func connect(accessToken: String? = nil,
                        timeout: Int = 30,
                        handler: @escaping ((ConnectionError?) -> Void)) {
        eventLog?.markFormat(type: eventType, format: "try connect")
        peerConnection = PeerConnection(connection: connection,
                                        mediaConnection: self,
                                        role: role,
                                        accessToken: accessToken,
                                        mediaStreamId: nil,
                                        mediaOption: mediaOption)
        peerConnection!.connect(timeout: timeout) {
            error in
            if let error = error {
                self.eventLog?.markFormat(type: self.eventType,
                                          format: "connect error: %@",
                                          arguments: error.localizedDescription)
                self.peerConnection = nil
                self.onFailureHandler?(error)
                self.onConnectHandler?(error)
                handler(error)
            } else {
                self.eventLog?.markFormat(type: self.eventType, format: "connect ok")
                self.internalOnConnect()
                self.onConnectHandler?(nil)
                handler(nil)
            }
        }
    }
    
    // 内部用のコールバック
    func internalOnConnect() {}
    
    public func disconnect(handler: @escaping (ConnectionError?) -> Void) {
        eventLog?.markFormat(type: eventType, format: "try disconnect")
        switch peerConnection?.state {
        case nil, .disconnected?:
            eventLog?.markFormat(type: eventType,
                                 format: "error: already disconnected")
            handler(ConnectionError.connectionDisconnected)
        case .disconnecting?:
            eventLog?.markFormat(type: eventType,
                                 format: "error: connection is busy")
            handler(ConnectionError.connectionBusy)
        case .connected?, .connecting?:
            eventLog?.markFormat(type: eventType, format: "disconnect ok")
            for stream in mediaStreams {
                stream.terminate()
            }
            mediaStreams = []
            peerConnection!.disconnect {
                error in
                handler(error)
            }
        }
    }
    
    public func send(message: Messageable) -> ConnectionError? {
        eventLog?.markFormat(type: eventType, format: "send message")
        if isAvailable {
            return peerConnection!.send(message: message)
        } else {
            return ConnectionError.connectionDisconnected
        }
    }
    
    // MARK: マルチストリーム
    
    func addMediaStream(mediaStream: MediaStream) {
        eventLog?.markFormat(type: eventType, format: "add media stream")
        mediaStreams.append(mediaStream)
    }
    
    func removeMediaStream(mediaStreamId: String) {
        eventLog?.markFormat(type: eventType, format: "remove media stream")
        mediaStreams = mediaStreams.filter {
            e in
            return e.mediaStreamId != mediaStreamId
        }
    }
    
    // MARK: イベントハンドラ
    
    var onConnectHandler: ((ConnectionError?) -> Void)?
    var onDisconnectHandler: ((ConnectionError?) -> Void)?
    var onFailureHandler: ((ConnectionError) -> Void)?
    var onStatisticsHandler: ((Statistics) -> Void)?
    var onNotifyHandler: ((Notification) -> Void)?

    public func onConnect(handler: @escaping (ConnectionError?) -> Void) {
        onConnectHandler = handler
    }
    
    public func onDisconnect(handler: @escaping (ConnectionError?) -> Void) {
        onDisconnectHandler = handler
    }
    
    public func onFailure(handler: @escaping (ConnectionError) -> Void) {
        onFailureHandler = handler
    }
    
    public func onStatistics(handler: @escaping (Statistics) -> Void) {
        onStatisticsHandler = handler
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
                            MediaOption.createCaptureTrackId())
        audioCaptureTrack = factory
            .audioTrack(withTrackId: mediaOption?.audioCaptureTrackId ??
                MediaOption.createCaptureTrackId())
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
                    eventLog?.markFormat(type: eventType,
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
    
    public var autofocusEnabled = false {
        didSet {
            if let session = captureSession {
                for input in session.inputs {
                    if let device = input as? AVCaptureDevice {
                        if autofocusEnabled {
                            device.focusMode = .autoFocus
                        } else {
                            device.focusMode = .locked
                        }
                    }
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

    override func internalOnConnect() {
        autofocusEnabled = false
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
