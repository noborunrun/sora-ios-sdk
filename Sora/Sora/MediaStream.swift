import Foundation
import WebRTC
import SocketRocket
import Unbox

public class MediaStream {
    
    public enum State {
        case connecting
        case connected
        case disconnecting
        case disconnected
    }
    
    static var defaultStreamId: String = "mainStream"
    static var defaultVideoTrackId: String = "mainVideo"
    static var defaultAudioTrackId: String = "mainAudio"

    public var connection: Connection
    public weak var mediaConnection: MediaConnection?
    public var role: Role
    public var accessToken: String?
    public var mediaStreamlId: String?
    public var mediaOption: MediaOption?
    public var creationTime: Date?
    public var clientId: String?
    public var state: State

    public var isAvailable: Bool {
        get { return state == .connected }
    }
    
    public var mediaCapturer: MediaCapturer? {
        get { return context?.mediaCapturer }
    }
    
    public var peerConnection: RTCPeerConnection? {
        get { return context?.peerConnection }
    }
    
    public var peerConnectionFactory: RTCPeerConnectionFactory? {
        get { return context?.peerConnectionFactory }
    }
    
    public var nativeVideoTrack: RTCVideoTrack? {
        get {
            if let stream = nativeMediaStream {
                if stream.videoTracks.isEmpty {
                    return nil
                }
                return stream.videoTracks[0]
            } else {
                return nil
            }
        }
    }
    
    public var nativeAudioTrack: RTCAudioTrack? {
        get {
            if let stream = nativeMediaStream {
                if stream.audioTracks.isEmpty {
                    return nil
                }
                return stream.audioTracks[0]
            } else {
                return nil
            }
        }
    }

    var context: MediaStreamContext?
    var videoRendererSupport: VideoRendererSupport?
    var nativeMediaStream: RTCMediaStream?
    
    init(connection: Connection,
         mediaConnection: MediaConnection,
         role: Role,
         accessToken: String? = nil,
         mediaStreamId: String? = nil,
         mediaOption: MediaOption? = MediaOption()) {
        self.connection = connection
        self.mediaConnection = mediaConnection
        self.role = role
        self.accessToken = accessToken
        self.mediaStreamlId = mediaStreamId
        self.mediaOption = mediaOption
        state = .disconnected
    }
    
    func setVideoRenderer(_ videoRenderer: VideoRenderer?) {
        if let videoTrack = nativeVideoTrack {
            if let renderer = videoRenderer {
                videoRendererSupport = VideoRendererSupport(videoRenderer: renderer)
                videoTrack.add(videoRendererSupport!)
            } else if let support = videoRendererSupport {
                videoTrack.remove(support)
            }
        }
    }
    
    // MARK: ピア接続
    
    // 接続に成功すると peerConnection プロパティがセットされる
    func connect(handler:
        @escaping ((RTCPeerConnection?, ConnectionError?) -> Void)) {
        switch state {
        case .connected, .connecting, .disconnecting:
            handler(nil, ConnectionError.connectionBusy)
        case .disconnected:
            state = .connecting
            context = MediaStreamContext(mediaStream: self, role: role)
            context!.connect(handler: handler)
        }
    }
    
    func disconnect(handler: @escaping (ConnectionError?) -> Void) {
        switch state {
        case .disconnecting:
            handler(ConnectionError.connectionBusy)
        case .disconnected:
            handler(ConnectionError.connectionDisconnected)
        case .connecting, .connected:
            assert(peerConnection == nil, "peerConnection must not be nil")
            state = .disconnected
            creationTime = nil
            videoRendererSupport = nil
            context?.disconnect(handler: handler)
        }
    }
    
    // MARK: WebSocket
    
    func send(message: Message) -> ConnectionError? {
        switch state {
        case .connected:
            return context!.send(message)
        case .disconnected:
            return ConnectionError.connectionDisconnected
        default:
            return ConnectionError.connectionBusy
        }
    }
    
    func send(messageable: Messageable) -> ConnectionError? {
        return send(message: messageable.message())
    }
    
}

class MediaStreamContext: NSObject, SRWebSocketDelegate, RTCPeerConnectionDelegate {
    
    enum State: String {
        case signalingConnecting
        case signalingConnected
        case peerConnectionReady
        case peerConnectionOffered
        case peerConnectionAnswering
        case peerConnectionAnswered
        case peerConnectionConnecting
        case connected
        case disconnecting
        case disconnected
        case terminating
    }
    
    weak var mediaStream: MediaStream!
    var role: Role
    
    var webSocket: SRWebSocket?
    var state: State = .disconnected
    var peerConnectionFactory: RTCPeerConnectionFactory
    var peerConnection: RTCPeerConnection!
    var upstream: RTCMediaStream?
    var mediaCapturer: MediaCapturer?
    
    var onConnectHandler: ((RTCPeerConnection?, ConnectionError?) -> Void)?
    var onDisconnectHandler: ((ConnectionError?) -> Void)?
    var onSentHandler: ((ConnectionError?) -> Void)?
    
    var connection: Connection {
        get { return mediaStream.connection }
    }
    
    var eventLog: EventLog {
        get { return connection.eventLog }
    }
    
    var mediaConnection: MediaConnection? {
        get { return mediaStream.mediaConnection }
    }
        
    init(mediaStream: MediaStream, role: Role) {
        self.mediaStream = mediaStream
        self.role = role
        peerConnectionFactory = RTCPeerConnectionFactory()
    }
    
    // MARK: ピア接続
    
    func connect(handler:
        @escaping ((RTCPeerConnection?, ConnectionError?) -> Void)) {
        if state != .disconnected {
            handler(nil, ConnectionError.connectionBusy)
            return
        }
        
        eventLog.markFormat(type: .WebSocket,
                            format: String(format: "open %@",
                                            connection.URL.description))
        state = .signalingConnecting
        onConnectHandler = handler
        webSocket = SRWebSocket(url: connection.URL)
        webSocket!.delegate = self
        webSocket!.open()
    }
    
    func disconnect(handler: @escaping ((ConnectionError?) -> Void)) {
        switch state {
        case .disconnected:
            callOnDisconnectHandler(error: ConnectionError.connectionDisconnected)
        case .signalingConnected,.connected:
            state = .disconnecting
            onDisconnectHandler = handler
            webSocket!.close()
        default:
            callOnDisconnectHandler(error: ConnectionError.connectionBusy)
        }
    }
    
    func callOnDisconnectHandler(error: ConnectionError?) {
        onDisconnectHandler?(error)
        onDisconnectHandler = nil
        mediaConnection?.callOnDisonnectHandler(error: error)
    }
    
     // 強制的にシグナリングを切断する
    func terminate(error: ConnectionError?) {
        eventLog.markFormat(type: .Signaling,
                            format: "connection terminated")
        state = .terminating
        mediaConnection?.callOnFailureHandler(
            error: error ?? ConnectionError.connectionTerminated)
        // webSocket?.close() だと onDisconnectHandler が二重に呼ばれる可能性がある
        if let webSocket = webSocket {
            webSocket.close()
        }
        callOnDisconnectHandler(error: error)
        onConnectHandler?(nil, error)
    }
    
    func send(_ message: Message) -> ConnectionError? {
        eventLog.markFormat(type: .WebSocket,
                            format: "send message (state %@): %@",
                            arguments: state.rawValue, message.description)
        switch state {
        case .disconnected:
            eventLog.markFormat(type: .WebSocket,
                                format: "failed sending message (connection disconnected)")
            
            return ConnectionError.connectionDisconnected
        case .signalingConnecting, .disconnecting, .terminating:
            eventLog.markFormat(type: .WebSocket,
                                format: "failed sending message (connection busy)")
            return ConnectionError.connectionBusy
            
        default:
            let s = message.JSONString()
            eventLog.markFormat(type: .WebSocket,
                                format: "send message as JSON: %@",
                                arguments: s)
            webSocket!.send(message.JSONString())
            return nil
        }
    }
 
    func send(_ messageable: Messageable) -> ConnectionError? {
        return self.send(messageable.message())
    }
    
    // MARK: SRWebSocketDelegate
    
    var webSocketEventHandlers: WebSocketEventHandlers? {
        get { return mediaConnection?.webSocketEventHandlers }
    }
    
    var signalingEventHandlers: SignalingEventHandlers? {
        get { return mediaConnection?.signalingEventHandlers }
    }
    
    var peerConnectionEventHandlers: PeerConnectionEventHandlers? {
        get { return mediaConnection?.peerConnectionEventHandlers }
    }
    
    func webSocketDidOpen(_ webSocket: SRWebSocket!) {
        eventLog.markFormat(type: .WebSocket, format: "opened")
        webSocketEventHandlers?.onOpenHandler?(webSocket)
        
        if state == .signalingConnecting {
            eventLog.markFormat(type: .Signaling, format: "connected")
            state = .signalingConnected
            signalingEventHandlers?.onConnectHandler?()
            
            // ピア接続オブジェクトを生成する
            eventLog.markFormat(type: .PeerConnection, format: "create peer connection")
            peerConnection = peerConnectionFactory.peerConnection(
                with: mediaStream.mediaOption?.configuration
                    ?? MediaOption.defaultConfiguration,
                constraints: mediaStream.mediaOption?.peerConnectionMediaConstraints
                    ?? MediaOption.defaultMediaConstraints,
                delegate: self)
            if role == Role.upstream {
                if let error = createMediaCapturer() {
                    terminate(error: error)
                    return
                }
            }
            
            // シグナリング connect を送信する
            let connect = SignalingConnect(role: SignalingRole.from(role),
                                           channel_id: connection.mediaChannelId)
            eventLog.markFormat(type: .Signaling,
                                format: "send connect message: %@",
                                arguments: connect.message().JSON().description)
            if let error = send(connect) {
                eventLog.markFormat(type: .Signaling,
                                    format: "send connect message failed: %@",
                                    arguments: error.localizedDescription)
                signalingEventHandlers?.onFailureHandler?(error)
                webSocket.close()
                return
            }
            state = .peerConnectionReady
            
        } else {
            eventLog.markFormat(type: .Signaling,
                                format: "WebSocket opened in invalid state")
            state = .disconnected
            webSocket.close()
        }
    }

    func createMediaCapturer() -> ConnectionError? {
        eventLog.markFormat(type: .PeerConnection, format: "create media capturer")
        mediaCapturer = MediaCapturer(factory: peerConnectionFactory,
                                      mediaOption: mediaStream.mediaOption)
        if mediaCapturer == nil {
            eventLog.markFormat(type: .PeerConnection,
                                format: "create media capturer failed")
            return ConnectionError.mediaCapturerFailed
        }
        
        let upstream = peerConnectionFactory.mediaStream(withStreamId:
            mediaStream.mediaStreamlId ?? MediaStream.defaultStreamId)
        if mediaStream.mediaOption == nil ||
            mediaStream.mediaOption?.videoEnabled == true {
            upstream.addVideoTrack(mediaCapturer!.videoCaptureTrack)
        }
        if mediaStream.mediaOption == nil ||
            mediaStream.mediaOption?.audioEnabled == true {
            upstream.addAudioTrack(mediaCapturer!.audioCaptureTrack)
        }
        peerConnection.add(upstream)
        return nil
    }

    public func webSocket(_ webSocket: SRWebSocket!,
                          didCloseWithCode code: Int,
                          reason: String!,
                          wasClean: Bool) {
        eventLog.markFormat(type: .WebSocket,
                            format: "close: code \(code), reason %@, clean \(wasClean)",
            arguments: reason)
        webSocketEventHandlers?.onCloseHandler?(webSocket, code, reason, wasClean)
        signalingEventHandlers?.onDisconnectHandler?()
        self.webSocket = nil
        
        switch state {
        case .disconnecting, .terminating:
            state = .disconnected
            callOnDisconnectHandler(error: nil)
        default:
            state = .disconnected
            callOnDisconnectHandler(error: ConnectionError.webSocketClose(code, reason))
        }
    }
    
    func webSocket(_ webSocket: SRWebSocket!, didFailWithError error: Error!) {
        state = .disconnected
        eventLog.markFormat(type: .WebSocket,
                            format: "fail: %@",
                            arguments: error.localizedDescription)
        webSocketEventHandlers?.onFailureHandler?(webSocket, error)
        
        let connError = ConnectionError.webSocketError(error)
        self.webSocket = nil
        mediaConnection?.callOnFailureHandler(error: connError)
        callOnDisconnectHandler(error: connError)
    }
    
    func webSocket(_ webSocket: SRWebSocket!, didReceivePong pongPayload: Data!) {
        eventLog.markFormat(type: .WebSocket,
                                 format: "received pong: %@",
                                 arguments: pongPayload.description)
        webSocketEventHandlers?.onPongHandler?(webSocket, pongPayload)
    }
    
    func webSocket(_ webSocket: SRWebSocket!, didReceiveMessage message: Any!) {
        eventLog.markFormat(type: .WebSocket,
                            format: "received message: %@",
                            arguments: (message as AnyObject).description)
        webSocketEventHandlers?.onMessageHandler?(webSocket, message as AnyObject)

        if let message = Message.fromJSONData(message) {
            signalingEventHandlers?.onReceiveHandler?(message)
            eventLog.markFormat(type: .Signaling,
                                format: "signaling message type: %@",
                                arguments: message.type?.rawValue ??  "<unknown>")

            let json = message.JSON()
            switch message.type {
            case .ping?:
                receiveSignalingPing()
                
            case .stats?:
                receiveSignalingStats(json: json)
                
            case .notify?:
                receiveSignalingNotify(json: json)
                
            case .offer?:
                receiveSignalingOffer(json: json)

            default:
                return
            }
        }
    }
    
    func receiveSignalingPing() {
        if state != .connected {
            return
        }
        
        eventLog.markFormat(type: .Signaling, format: "received ping")
        signalingEventHandlers?.onPingHandler?()
        if let error = self.send(SignalingPong()) {
            mediaConnection?.callOnFailureHandler(error: error)
        }
    }
    
    func receiveSignalingStats(json: [String: Any]) {
        if state != .connected {
            return
        }
        
        var stats: SignalingStats!
        do {
            stats = Optional.some(try unbox(dictionary: json))
        } catch {
            eventLog.markFormat(type: .Signaling,
                                format: "failed parsing stats: %@",
                                arguments: json.description)
            return
        }
        
        eventLog.markFormat(type: .Signaling, format: "stats: %@",
                            arguments: stats.description)
        
        let mediaStats = MediaConnection.Statistics(signalingStats: stats)
        signalingEventHandlers?.onUpdateHandler?(stats)
        mediaConnection?.callOnUpdateHandler(stats: mediaStats)
    }
    
    func receiveSignalingNotify(json: [String: Any]) {
        if state != .connected {
            return
        }
        
        var notify: SignalingNotify!
        do {
            notify = Optional.some(try unbox(dictionary: json))
        } catch {
            eventLog.markFormat(type: .Signaling,
                                format: "failed parsing notify: %@",
                                arguments: json.description)
        }
        
        eventLog.markFormat(type: .Signaling, format: "received notify: %@",
                            arguments: notify.notifyMessage)
        signalingEventHandlers?.onNotifyHandler?(notify)
        if let notify = MediaConnection
            .Notification(rawValue: notify.notifyMessage) {
            mediaConnection?.callOnNotifyHandler(notification: notify)
        }
    }
    
    func receiveSignalingOffer(json: [String: Any]) {
        if state != .peerConnectionReady {
            eventLog.markFormat(type: .Signaling,
                                format: "offer: invalid state %@",
                                arguments: state.rawValue)
            terminate(error: ConnectionError.connectionTerminated)
            return
        }
        
        eventLog.markFormat(type: .Signaling, format: "received offer")
        let offer: SignalingOffer!
        do {
            offer = Optional.some(try unbox(dictionary: json))
        } catch {
            eventLog.markFormat(type: .Signaling,
                                format: "parsing offer failed")
            return
        }
        
        if let config = offer.config {
            eventLog.markFormat(type: .Signaling,
                                format: "configure ICE transport policy")
            let peerConfig = RTCConfiguration()
            switch config.iceTransportPolicy {
            case "relay":
                peerConfig.iceTransportPolicy = .relay
            default:
                eventLog.markFormat(type: .Signaling,
                                    format: "unsupported iceTransportPolicy %@",
                                    arguments: config.iceTransportPolicy)
                return
            }
            
            eventLog.markFormat(type: .Signaling, format: "configure ICE servers")
            for serverConfig in config.iceServers {
                let server = RTCIceServer(urlStrings: serverConfig.urls,
                                          username: serverConfig.username,
                                          credential: serverConfig.credential)
                peerConfig.iceServers = [server]
            }
            
            if !peerConnection.setConfiguration(peerConfig) {
                eventLog.markFormat(type: .Signaling,
                                    format: "cannot configure peer connection")
                onConnectHandler?(nil, ConnectionError
                    .failureSetConfiguration(peerConfig))
                return
            }
        }
        
        state = .peerConnectionOffered
        let sdp = offer.sessionDescription()
        eventLog.markFormat(type: .Signaling,
                            format: "set remote description")
        peerConnection.setRemoteDescription(sdp) {
            error in
            if let error = error {
                self.eventLog.markFormat(type: .Signaling,
                                         format: "set remote description failed")
                self.mediaConnection?.callOnFailureHandler(error:
                    ConnectionError.peerConnectionError(error))
                self.webSocket?.close()
                return
            }
            
            self.eventLog.markFormat(type: .Signaling,
                                     format: "create answer")
            self.peerConnection.answer(for: self
                .mediaStream.mediaOption?
                .signalingAnswerMediaConstraints
                ?? MediaOption.defaultMediaConstraints)
            {
                (sdp, error) in
                if let error = error {
                    self.eventLog.markFormat(type: .Signaling,
                                             format: "creating answer failed")
                    self.peerConnectionEventHandlers?.onFailureHandler?(error)
                    self.mediaConnection?.callOnFailureHandler(error:
                        ConnectionError.peerConnectionError(error))
                    self.webSocket?.close()
                    return
                }
                self.eventLog.markFormat(type: .Signaling,
                                         format: "generated answer: %@",
                                         arguments: sdp!)
                self.peerConnection.setLocalDescription(sdp!) {
                    error in
                    if let error = error {
                        self.eventLog.markFormat(type: .Signaling,
                                                 format: "set local description failed")
                        self.peerConnectionEventHandlers?.onFailureHandler?(error)
                        self.mediaConnection?.callOnFailureHandler(error:
                            ConnectionError.peerConnectionError(error))
                        self.webSocket?.close()
                        return
                    }
                    
                    self.eventLog.markFormat(type: .Signaling,
                                             format: "send answer")
                    let answer = SignalingAnswer(sdp: sdp!.sdp)
                    if let error = self.send(answer) {
                        self.mediaConnection?.callOnFailureHandler(error:
                            ConnectionError.peerConnectionError(error))
                        self.webSocket?.close()
                        return
                    }
                    self.state = .peerConnectionAnswered
                }
            }
        }
    }
    
    // MARK: RTCPeerConnectionDelegate
    
    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didChange stateChanged: RTCSignalingState) {
        eventLog.markFormat(type: .PeerConnection,
                            format: "signaling state changed: %@",
                            arguments: stateChanged.description)
        peerConnectionEventHandlers?.onChangeSignalingStateHandler?(
            peerConnection, stateChanged)
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didAdd stream: RTCMediaStream) {
        eventLog.markFormat(type: .PeerConnection, format: "added stream")
        peerConnectionEventHandlers?.onAddStreamHandler?(peerConnection, stream)
        peerConnection.add(stream)
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didRemove stream: RTCMediaStream) {
        eventLog.markFormat(type: .PeerConnection, format: "removed stream")
        peerConnectionEventHandlers?.onRemoveStreamHandler?(peerConnection, stream)
        peerConnection.add(stream)
    }
    
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        eventLog.markFormat(type: .PeerConnection, format: "should negatiate")
        peerConnectionEventHandlers?.onNegotiateHandler?(peerConnection)
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didChange newState: RTCIceConnectionState) {
        eventLog.markFormat(type: .PeerConnection,
                            format: "ICE connection state changed: %@",
                            arguments: newState.description)
        peerConnectionEventHandlers?
            .onChangeIceConnectionState?(peerConnection, newState)
        switch newState {
        case .connected:
            break
            
        case .completed:
            switch state {
            case .peerConnectionAnswered:
                state = .connected
                peerConnectionEventHandlers?.onConnectHandler?()
                onConnectHandler?(nil, nil)
            default:
                eventLog.markFormat(type: .PeerConnection,
                                    format: "ICE connection completed but invalid state %@",
                                    arguments: newState.description)
                terminate(error: ConnectionError.iceConnectionFailed)
            }
            
        case .disconnected:
            switch state {
            case .disconnecting:
                // do nothing
                break
            default:
                terminate(error: ConnectionError.iceConnectionDisconnected)
            }
            
        case .failed:
            mediaConnection?.callOnFailureHandler(error:
                ConnectionError.iceConnectionFailed)
            
        default:
            break
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didChange newState: RTCIceGatheringState) {
        eventLog.markFormat(type: .PeerConnection,
                            format: "ICE gathering state changed: %@",
                            arguments: newState.description)
        peerConnectionEventHandlers?
            .onChangeIceGatheringStateHandler?(peerConnection, newState)
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didGenerate candidate: RTCIceCandidate) {
        eventLog.markFormat(type: .PeerConnection, format: "candidate generated: %@",
                            arguments: candidate.sdp)
        peerConnectionEventHandlers?
            .onGenerateIceCandidateHandler?(peerConnection, candidate)
        if let error = send(SignalingICECandidate(candidate: candidate.sdp)) {
            eventLog.markFormat(type: .PeerConnection,
                                format: "send candidate to server failed")
            terminate(error: error)
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didRemove candidates: [RTCIceCandidate]) {
        eventLog.markFormat(type: .PeerConnection,
                            format: "candidates %d removed",
                            arguments: candidates.count)
        peerConnectionEventHandlers?
            .onRemoveCandidatesHandler?(peerConnection, candidates)
    }
    
    // NOTE: Sora はデータチャネルに非対応
    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didOpen dataChannel: RTCDataChannel) {
        eventLog.markFormat(type: .PeerConnection,
                            format: "data channel opened")
        peerConnectionEventHandlers?
            .onOpenDataChannelHandler?(peerConnection, dataChannel)
    }
    
}
