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

    public weak var mediaConnection: MediaConnection!
    public var role: Role
    public var mediaChannelId: String
    public var accessToken: String?
    public var mediaStreamlId: String?
    public var mediaOption: MediaOption?
    public var creationTime: Date?
    public var clientId: String?
    public var peerConnection: RTCPeerConnection?
    public var peerConnectionFactory: RTCPeerConnectionFactory?
    public var state: State

    public weak var connection: Connection! {
        get { return mediaConnection.mediaChannel.connection }
    }
    
    public var isAvailable: Bool {
        get { return state == .connected }
    }
    
    public var nativeVideoTrack: RTCVideoTrack? {
        get {
            if nativeMediaStream.videoTracks.isEmpty {
                return nil
            }
            return nativeMediaStream.videoTracks[0]
        }
    }
    
    public var nativeAudioTrack: RTCAudioTrack? {
        get {
            if nativeMediaStream.audioTracks.isEmpty {
                return nil
            }
            return nativeMediaStream.audioTracks[0]
        }
    }

    var context: MediaStreamContext?
    var videoRendererSupport: VideoRendererSupport?
    var nativeMediaStream: RTCMediaStream
    
    init(mediaConnection: MediaConnection,
         role: Role,
         mediaChannelId: String,
         accessToken: String? = nil,
         mediaStreamId: String? = nil,
         mediaOption: MediaOption? = MediaOption()) {
        self.mediaConnection = mediaConnection
        self.role = role
        self.mediaChannelId = mediaChannelId
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
    
    // MARK: シグナリング
    
    func connect(handler: @escaping ((ConnectionError?) -> Void)) {
        switch state {
        case .connected, .connecting, .disconnecting:
            handler(ConnectionError.connectionBusy)
        case .disconnected:
            state = .connecting
            context = MediaStreamContext(mediaStream: self)
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
    
    enum State {
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
    }
    
    weak var mediaStream: MediaStream!
    var webSocket: SRWebSocket?
    var state: State = .disconnected
    var peerConnectionFactory: RTCPeerConnectionFactory
    var peerConnection: RTCPeerConnection!
    var upstream: RTCMediaStream?
    var mediaCapturer: MediaCapturer?
    
    var onConnectHandler: ((ConnectionError?) -> Void)?
    var onDisconnectHandler: ((ConnectionError?) -> Void)?
    var onSentHandler: ((ConnectionError?) -> Void)?
    
    var connection: Connection {
        get { return mediaStream.connection }
    }
    
    var eventLog: EventLog {
        get { return mediaStream.connection.eventLog }
    }
    
    var mediaConnection: MediaConnection {
        get { return mediaStream.mediaConnection }
    }
        
    init(mediaStream: MediaStream) {
        self.mediaStream = mediaStream
        peerConnectionFactory = RTCPeerConnectionFactory()
    }
    
    func connect(handler: @escaping ((ConnectionError?) -> Void)) {
        if state != .disconnected {
            handler(ConnectionError.connectionBusy)
            return
        }
        
        eventLog.mark(event:
            Event(type: .WebSocket,
                  comment: String(format: "open %@", connection.URL.description)))
        state = .signalingConnecting
        onConnectHandler = handler
        webSocket = SRWebSocket(url: connection.URL)
        webSocket!.delegate = self
        webSocket!.open()
    }
    
    func disconnect(handler: @escaping ((ConnectionError?) -> Void)) {
        switch state {
        case .disconnected:
            handler(ConnectionError.connectionDisconnected)
        case .signalingConnected,.connected:
            state = .disconnecting
            onDisconnectHandler = handler
            webSocket!.close()
        default:
            handler(ConnectionError.connectionBusy)
        }
    }
    
    func send(_ message: Message) -> ConnectionError? {
        switch state {
        case .disconnected:
            return ConnectionError.connectionDisconnected
        case .connected:
            let j = message.JSON()
            let data = try! JSONSerialization.data(withJSONObject: j,
                                                   options:
                JSONSerialization.WritingOptions(rawValue: 0))
            let msg = NSString(data: data,
                               encoding: String.Encoding.utf8.rawValue) as String!
            print("WebSocket send ", j)
            eventLog.markFormat(type: .WebSocket,
                                format: "send message: %@",
                                arguments: msg!)
            webSocket!.send(msg)
            return nil
        default:
            return ConnectionError.connectionBusy
        }
    }
    
    func send(_ messageable: Messageable) -> ConnectionError? {
        return self.send(messageable.message())
    }
    
    // MARK: SRWebSocketDelegate
    
    var webSocketEventHandlers: WebSocketEventHandlers? {
        get { return mediaConnection.webSocketEventHandlers }
    }
    
    var signalingEventHandlers: SignalingEventHandlers? {
        get { return mediaConnection.signalingEventHandlers }
    }
    
    var peerConnectionEventHandlers: PeerConnectionEventHandlers? {
        get { return mediaConnection.peerConnectionEventHandlers }
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
                with: mediaConnection.mediaOption?.configuration
                    ?? MediaOption.defaultConfiguration,
                constraints: mediaConnection.mediaOption?.peerConnectionMediaConstraints
                    ?? MediaOption.defaultMediaConstraints,
                delegate: self)
            if mediaConnection.role() == Role.upstream {
                createMediaCapturer()
            }
            
            // シグナリング connect を送信する
            let connect = SignalingConnect(role: SignalingRole.from(mediaConnection.role()),
                                           channel_id: mediaConnection.mediaChannelId)
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

    func createMediaCapturer() {
        print("create media capturer")
        eventLog.markFormat(type: .PeerConnection, format: "create media capturer")
        let constraints = mediaConnection.mediaOption?
            .videoCaptureSourceMediaConstraints
            ?? MediaOption.defaultMediaConstraints
        mediaCapturer = MediaCapturer(factory: peerConnectionFactory, videoCaptureSourceMediaConstraints: constraints)
        if mediaCapturer == nil {
            eventLog.markFormat(type: .PeerConnection,
                                format: "create media capturer failed")
            webSocket?.close()
            return
        }
        
        let upstream = peerConnectionFactory.mediaStream(withStreamId:
            mediaStream.mediaStreamlId ?? MediaStream.defaultStreamId)
        upstream.addVideoTrack(mediaCapturer!.videoCaptureTrack)
        upstream.addAudioTrack(mediaCapturer!.audioCaptureTrack)
        peerConnection.add(upstream)
    }

    public func webSocket(_ webSocket: SRWebSocket!,
                          didCloseWithCode code: Int,
                          reason: String!,
                          wasClean: Bool) {
        print("webSocket:didCloseWithCode:", code)
        eventLog.markFormat(type: .WebSocket,
                            format: "close: code \(code), reason %@, clean \(wasClean)",
            arguments: reason)
        webSocketEventHandlers?.onCloseHandler?(webSocket, code, reason, wasClean)
        signalingEventHandlers?.onDisconnectHandler?()
        
        if state == .disconnecting {
            state = .disconnected
            onDisconnectHandler?(nil)
        } else if state != .disconnecting {
            state = .disconnected
            onDisconnectHandler?(ConnectionError.webSocketClose(code, reason))
        }
    }
    
    func webSocket(_ webSocket: SRWebSocket!, didFailWithError error: Error!) {
        print("webSocket:didFailWithError:")
        state = .disconnected
        mediaConnection.state = .disconnected
        eventLog.markFormat(type: .WebSocket,
                            format: "fail: %@",
                            arguments: error.localizedDescription)
        webSocketEventHandlers?.onFailureHandler?(webSocket, error)
        
        let connError = ConnectionError.webSocketError(error)
        self.webSocket = nil
        mediaConnection.onFailureHandler?(connError)
        onDisconnectHandler?(connError)
    }
    
    func webSocket(_ webSocket: SRWebSocket!, didReceivePong pongPayload: Data!) {
        eventLog.markFormat(type: .WebSocket,
                                 format: "received pong: %@",
                                 arguments: pongPayload.description)
        webSocketEventHandlers?.onPongHandler?(webSocket, pongPayload)
    }
    
    func webSocket(_ webSocket: SRWebSocket!, didReceiveMessage message: Any!) {
        print("webSocket:didReceiveMessage:", message)
        eventLog.markFormat(type: .WebSocket,
                            format: "received message: %@",
                            arguments: (message as AnyObject).description)
        webSocketEventHandlers?.onMessageHandler?(webSocket, message as AnyObject)

        if let message = Message.fromJSONData(message) {
            signalingEventHandlers?.onReceiveHandler?(message)

            let json = message.JSON()
            print("received message type: ", message.type)
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
            mediaConnection.onFailureHandler?(error)
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
        mediaConnection.onUpdateHandler?(mediaStats)
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
            mediaConnection.onNotifyHandler?(notify)
        }
    }
    
    func receiveSignalingOffer(json: [String: Any]) {
        if state != .signalingConnected {
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
        print("peer offered")
        
        if let config = offer.config {
            print("offer config:", config)
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
                print("failed setting configuration sent by offer")
                eventLog.markFormat(type: .Signaling,
                                    format: "cannot configure peer connection")
                onConnectHandler?(ConnectionError
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
                self.mediaConnection.onFailureHandler?(
                    ConnectionError.peerConnectionError(error))
                self.webSocket?.close()
                return
            }
            
            print("create answer")
            self.eventLog.markFormat(type: .Signaling,
                                     format: "create answer")
            self.peerConnection.answer(for: self
                .mediaConnection.mediaOption?
                .signalingAnswerMediaConstraints
                ?? MediaOption.defaultMediaConstraints)
            {
                (sdp, error) in
                if let error = error {
                    self.eventLog.markFormat(type: .Signaling,
                                             format: "creating answer failed")
                    self.peerConnectionEventHandlers?.onFailureHandler?(error)
                    self.mediaConnection.onFailureHandler?(
                        ConnectionError.peerConnectionError(error))
                    self.webSocket?.close()
                    return
                }
                print("generate answer: ", sdp)
                self.eventLog.markFormat(type: .Signaling,
                                         format: "generated answer: %@",
                                         arguments: sdp!)
                
                print("set local description")
                self.eventLog.markFormat(type: .Signaling,
                                         format: "set local description")
                self.peerConnection.setLocalDescription(sdp!) {
                    error in
                    if let error = error {
                        self.eventLog.markFormat(type: .Signaling,
                                                 format: "set local description failed")
                        self.peerConnectionEventHandlers?.onFailureHandler?(error)
                        self.mediaConnection.onFailureHandler?(
                            ConnectionError.peerConnectionError(error))
                        self.webSocket?.close()
                        return
                    }
                    
                    print("send answer")
                    self.eventLog.markFormat(type: .Signaling,
                                             format: "send answer")
                    let answer = SignalingAnswer(sdp: sdp!.sdp)
                    if let error = self.send(answer) {
                        self.mediaConnection.onFailureHandler?(
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
        print("peerConnection:didChangeSignalingState:", stateChanged.rawValue)
        eventLog.markFormat(type: .PeerConnection, format: "signaling state changed: %@",
                            arguments: stateChanged.description)
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didAdd stream: RTCMediaStream) {
        print("peerConnection:didAddStream:")
        eventLog.markFormat(type: .PeerConnection, format: "added stream")
        if downstream != nil {
            peerConnection.close()
            onConnectHandler(nil, nil, ConnectionError.multipleDownstreams)
            return
        }
        downstream = stream
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didRemove stream: RTCMediaStream) {
        print("peerConnection:didRemoveStream:")
        eventLog.markFormat(type: .PeerConnection, format: "removed stream")
        if downstream == stream {
            downstream = nil
        }
    }
    
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        print("peerConnectionShouldNegotiate:")
        eventLog.markFormat(type: .PeerConnection, format: "should negatiate")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didChange newState: RTCIceConnectionState) {
        print("peerConnection:didChangeIceConnectionState:", newState.rawValue)
        eventLog.markFormat(type: .PeerConnection,
                            format: "ICE connection state changed: %@",
                            arguments: newState.description)
        switch newState {
        case .connected:
            print("ice connection connected")
            connContext.state = .ready
            onConnectHandler(peerConnection, downstream, nil)
        case .disconnected:
            print("ice connection disconnected")
            connContext.state = .disconnected
            connContext.connection.onDisconnectHandler?()
        case .failed:
            print("ice connection failed")
            connContext.state = .disconnected
            connContext.connection.onFailedHandler?(.iceConnectionFailed)
        default:
            break
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didChange newState: RTCIceGatheringState) {
        print("peerConnection:didChangeIceGatheringState:")
        eventLog.markFormat(type: .PeerConnection,
                            format: "ICE gathering state changed: %@",
                            arguments: newState.description)
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didGenerate candidate: RTCIceCandidate) {
        print("peerConnection:didGenerateIceCandidate:")
        eventLog.markFormat(type: .PeerConnection, format: "candidate generated: %@",
                            arguments: candidate.sdp)
        connContext.send(SignalingICECandidate(candidate: candidate.sdp))
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didRemove candidates: [RTCIceCandidate]) {
        print("peerConnection:didRemoveIceCandidates:")
        eventLog.markFormat(type: .PeerConnection,
                            format: "candidates %d removed",
                            arguments: candidates.count)
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didOpen dataChannel: RTCDataChannel) {
        print("peerConnection:didOpenDataChannel:")
        eventLog.markFormat(type: .PeerConnection, format: "data channel opened")
    }
    
}
