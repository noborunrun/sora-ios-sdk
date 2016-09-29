import Foundation
import WebRTC
import SocketRocket
import UIKit
import Argo

public enum Error: ErrorType {
    case FailureJSONDecode
    case DuplicatedChannelId
    case AuthenticationFailure
    case AuthenticationInternalError
    case UnknownVideoCodecType
    case FailureSDPParse
    case FailureMissingSDP
    case FailureSetConfiguration(RTCConfiguration)
    case UnknownType
    case ConnectWaitTimeout
    case ConnectionDisconnected
    case ConnectionBusy
    case WebSocketClose(Int, String)
    case WebSocketError(NSError)
    case PeerConnectionError(NSError)
}

public struct Connection {
    
    public enum State {
        case Connected
        case Connecting
        case Disconnected
        case Disconnecting
    }
    
    public var URL: NSURL
    public var clientId: String?
    public var creationTime: NSDate
    public var mediaChannels: [MediaChannel] = []
    
    public var state: State = .Disconnected {
        
        didSet {
            onUpdatedHandler?(state)
        }
        
    }

    public var peerConnectionFactory: RTCPeerConnectionFactory {
        get { return context.peerConnFactory }
    }
    
    var webSocket: SRWebSocket?
    var context: ConnectionContext!
    
    public init(URL: NSURL) {
        self.URL = URL
        state = .Disconnected
        creationTime = NSDate()
        config()
    }
    
    mutating func config() {
        context = ConnectionContext(connection: self)
    }
    
    // MARK: シグナリング接続
    
    public func connect(handler: ((Error?) -> ())) {
        context.connect(handler)
    }
    
    public func disconnect(handler: ((Error?) -> ())) {
        context.disconnect(handler)
    }
    
    public func send(message: Message) {
        context.send(message)
    }
    
    public func send(messageable: Messageable) {
        context.send(messageable.message())
    }
    
    public func isReady() -> Bool {
        return context.state == .Ready
    }
    
    // メディアチャネル
    public func createMediaChannel(channelId: String) -> MediaChannel {
        return MediaChannel(connection: self, channelId: channelId)
    }
    
    func createMediaUpstream(channelId: String, accessToken: String?,
                             mediaOption: MediaOption,
                             streamId: String,
                             handler: ((MediaStream?, MediaCapturer?, Error?) -> ())) {
        context.createPeerConnection(Role.Upstream, channelId: channelId,
                                     accessToken: accessToken,
                                     mediaOption: mediaOption)
        {
            (peerConn, upstream, downstreams, mediaCapturer, error) in
            print("on peer connection open: ", error)
            if let error = error {
                handler(nil, nil, error)
                return
            }
            let mediaStream = MediaStream.new(peerConn!, role: Role.Upstream,
                                              channelId: channelId,
                                              mediaOption: mediaOption,
                                              nativeMediaStreams: [upstream!])
            handler(mediaStream, mediaCapturer, nil)
        }
    }
    
    func createMediaDownstream(channelId: String, accessToken: String?,
                               mediaOption: MediaOption,
                               handler: ((MediaStream?, Error?) -> ())) {
        context.createPeerConnection(Role.Downstream, channelId: channelId,
                                     accessToken: accessToken,
                                     mediaOption: mediaOption)
        {
            (peerConn, upstream, downstreams, mediaCapturer, error) in
            print("on peer connection open: ", error)
            if let error = error {
                handler(nil, error)
                return
            }
            
            let mediaStream = MediaStream.new(peerConn!, role: Role.Downstream,
                                              channelId: channelId,
                                              mediaOption: mediaOption,
                                              nativeMediaStreams: downstreams)
            handler(mediaStream, nil)
        }
    }
    
    // MARK: イベントハンドラ
    
    var onReceiveHandler: ((Message) -> ())?
    var onConnectedHandler: (() -> ())?
    var onDisconnectedHandler: (() -> ())?
    var onUpdatedHandler: ((State) -> ())?
    var onFailedHandler: ((Error) -> ())?
    var onPingHandler: (() -> ())?
    
    // シグナリングメッセージ
    public mutating func onReceive(handler: ((Message) -> ())) {
        onReceiveHandler = handler
    }
    
    // 接続
    public mutating func onConnected(handler: (() -> ())) {
        onConnectedHandler = handler
    }
    
    public mutating func onDisconnected(handler: (() -> ())) {
        onDisconnectedHandler = handler
    }
    
    public mutating func onUpdated(handler: ((State) -> ())) {
        onUpdatedHandler = handler
    }
    
    public mutating func onFailed(handler: ((Error) -> ())) {
        onFailedHandler = handler
    }
    
    public mutating func onPing(handler: (() -> ())) {
        onPingHandler = handler
    }
    
    // MARK: イベントハンドラ: メディアチャネル
    
    var onDisconnectMediaChannelHandler: ((MediaChannel) -> ())?
    var onMediaChannelFailedHandler: ((MediaChannel, Error) -> ())?
    
    public mutating func onDisconnectMediaChannel(handler: ((MediaChannel) -> ())) {
        onDisconnectMediaChannelHandler = handler
    }
    
    public mutating func onMediaChannelFailed(handler: ((MediaChannel, Error) -> ())) {
        onMediaChannelFailedHandler = handler
    }
    
    // MARK: イベントハンドラ: Web フック
    
    var onSignalingConnectedHandler: ((SignalingConnected) -> ())?
    var onSignalingCompletedHandler: ((SignalingCompleted) -> ())?
    var onSignalingDisconnectedHandler: ((SignalingDisconnected) -> ())?
    var onSignalingFailedHandler: ((SignalingFailed) -> ())?
    var onArchiveFinishedHandler: ((MediaChannel, ArchiveFinished) -> ())?
    var onArchiveFailedHandler: ((MediaChannel, ArchiveFailed) -> ())?
    
    public mutating func onSignalingConnected(handler: ((SignalingConnected) -> ())) {
        onSignalingConnectedHandler = handler
    }
    
    public mutating func onSignalingCompleted(handler: ((SignalingCompleted) -> ())) {
        onSignalingCompletedHandler = handler
    }
    
    public mutating func onSignalingDisconnected(handler: ((SignalingDisconnected) -> ())) {
        onSignalingDisconnectedHandler = handler
    }
    
    public mutating func onSignalingFailedHandler(handler: ((SignalingFailed) -> ())) {
        onSignalingFailedHandler = handler
    }
    
    public mutating func onArchiveFinished(handler: ((MediaChannel, ArchiveFinished) -> ())) {
        onArchiveFinishedHandler = handler
    }
    
    public mutating func onArchiveFailed(handler: ((MediaChannel, ArchiveFailed) -> ())) {
        onArchiveFailedHandler = handler
    }
    
    // MARK: イベントハンドラ: プッシュ通知
    
    var onReceivePushHandler: ((MediaChannel?, Message) -> ())?
    
    public mutating func onReceivePush(handler: ((MediaChannel?, Message) -> ())) {
        onReceivePushHandler = handler
    }
    
}

class ConnectionContext: NSObject, SRWebSocketDelegate {
    
    enum State {
        case Connecting
        case Disconnecting
        case Disconnected
        case Ready
        case PeerOffered
        case PeerAnswering
        case PeerAnswered
        case PeerConnecting
    }
    
    var conn: Connection!
    var webSocket: SRWebSocket!
    var state: State = .Disconnected
    var peerConnFactory: RTCPeerConnectionFactory
    var peerConnContext: PeerConnectionContext!
    var role: Role?
    var upstream: RTCMediaStream?
    var mediaCapturer: MediaCapturer?

    var onConnectedHandler: ((Error?) -> ())?
    var onDisconnectedHandler: ((Error?) -> ())?
    var onSentHandler: ((Error?) -> ())?
    
    init(connection: Connection) {
        self.conn = connection
        peerConnFactory = RTCPeerConnectionFactory()
    }
    
    func validateState() -> Error? {
        if state == .Disconnected || state == .Disconnecting {
            return Error.ConnectionDisconnected
        } else if state != .Ready {
            return Error.ConnectionBusy
        } else {
            return nil
        }
    }
    
    func connect(handler: ((Error?) -> ())) {
        if state != .Disconnected {
            handler(Error.ConnectionBusy)
            return
        }
        state = .Connecting
        onConnectedHandler = handler
        webSocket = SRWebSocket(URL: conn.URL)
        webSocket.delegate = self
        webSocket.open()
    }
    
    func disconnect(handler: ((Error?) -> ())) {
        if let error = validateState() {
            handler(error)
            return
        }
        state = .Disconnecting
        onDisconnectedHandler = handler
        webSocket.close()
        webSocket = nil
    }
    
    func send(message: Message) {
        let j = message.JSONString()
        print("WebSocket send ", j)
        webSocket.send(j)
    }

    func send(messageable: Messageable) {
        self.send(messageable.message())
    }
    
    func createPeerConnection(role: Role, channelId: String,
                              accessToken: String?, mediaOption: MediaOption,
                              handler: ((RTCPeerConnection!, RTCMediaStream?, [RTCMediaStream], MediaCapturer?, Error?) -> ())) {
        if let error = validateState() {
            handler(nil, nil, [], nil, error)
            return
        }
        
        self.role = role
        peerConnContext = PeerConnectionContext(connContext: self, factory: peerConnFactory, mediaOption: mediaOption) {
            (peerConn, downstreams, error) in
            handler(peerConn, self.upstream, downstreams, self.mediaCapturer, error)
        }
        peerConnContext.createPeerConnection()
        prepareUpstream()
        
        // send "connect"
        print("send connect")
        state = .PeerConnecting
        let sigConnect = SignalingConnect(role: SignalingRole.from(role), channel_id: channelId)
        send(sigConnect)
    }
    
    func prepareUpstream() {
        if role == Role.Upstream {
            print("create media capturer")
            upstream = peerConnFactory.mediaStreamWithStreamId("main")
            let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
            mediaCapturer = MediaCapturer(factory: peerConnFactory, videoCaptureSourceMediaConstraints: constraints)
            upstream!.addVideoTrack(mediaCapturer!.videoCaptureTrack)
            upstream!.addAudioTrack(mediaCapturer!.audioCaptureTrack)
            peerConnContext.peerConn.addStream(upstream!)
        }
    }
    
    // MARK: SRWebSocketDelegate
    
    func webSocketDidOpen(webSocket: SRWebSocket!) {
        state = .Ready
        onConnectedHandler?(nil)
    }
    
    func webSocket(webSocket: SRWebSocket!, didFailWithError error: NSError!) {
        print("webSocket:didFailWithError:")
        onConnectedHandler?(Error.WebSocketError(error))
    }
    
    func webSocket(webSocket: SRWebSocket!, didReceivePong pongPayload: NSData!) {
        // TODO:
    }
    
    func webSocket(webSocket: SRWebSocket!, didReceiveMessage message: AnyObject!) {
        // TODO:
        print("webSocket:didReceiveMessage:")
        
        if let message = Message.fromJSONData(message) {
            conn.onReceiveHandler?(message)
            let json = message.JSON()
            print("received message type: ", message.type())
            switch message.type() {
            case "ping"?:
                self.send(SignalingPong())
                
            case "offer"?:
                if let offer = SignalingOffer.decode(json).value {
                    print("peer offered")
                    
                    if let config = offer.config {
                        print("offer config:", config)
                        let peerConfig = RTCConfiguration()
                        
                        switch config.iceTransportPolicy {
                        case "relay":
                            peerConfig.iceTransportPolicy = .Relay
                        default:
                            print("unsupported iceTransportPolicy:",
                                  config.iceTransportPolicy)
                            break
                        }
                        
                        for serverConfig in config.iceServers {
                            let server = RTCIceServer(URLStrings: serverConfig.urls,
                                                      username: serverConfig.username,
                                                      credential: serverConfig.credential)
                            peerConfig.iceServers = [server]
                        }
                        if !peerConnContext.peerConn.setConfiguration(peerConfig) {
                            onConnectedHandler?(Error.FailureSetConfiguration(peerConfig))
                            state = .Ready
                            return
                        }
                    }
                    
                    state = .PeerOffered
                    let sdp = offer.sessionDescription()
                    peerConnContext.peerConn.setRemoteDescription(sdp) {
                        (error: NSError?) in
                        if let error = error {
                            self.conn.onFailedHandler?(Error.PeerConnectionError(error))
                            return
                        }
                        
                        print("create answer")
                        self.state = .PeerAnswering
                        self.peerConnContext.peerConn.answerForConstraints(self.peerConnContext.mediaOption.answerMediaConstraints) {
                            (sdp, error) in
                            if let error = error {
                                self.conn.onFailedHandler?(Error.PeerConnectionError(error))
                                return
                            }
                            print("generate answer: ", sdp)

                            print("set local description")
                            self.peerConnContext.peerConn.setLocalDescription(sdp!) {
                                (error) in
                                print("send answer")
                                let answer = SignalingAnswer(sdp: sdp!.sdp)
                                self.send(answer)
                            }
                        }
                    }
                }
            default:
                return
            }
        }
    }
    
    func webSocket(webSocket: SRWebSocket!, didCloseWithCode code: Int, reason: String!, wasClean: Bool) {
        print("webSocket:didCloseWithCode:", code)
        var error: Error? = nil
        if let reason = reason {
            error = Error.WebSocketClose(code, reason)
        }
        onDisconnectedHandler?(error)
    }
    
}

class PeerConnectionContext: NSObject, RTCPeerConnectionDelegate {
    
    var connContext: ConnectionContext
    var factory: RTCPeerConnectionFactory
    var peerConn: RTCPeerConnection!
    var mediaStreams: [RTCMediaStream] = []
    var mediaOption: MediaOption
    var onConnectedHandler: ((RTCPeerConnection!, [RTCMediaStream], Error?) -> ())
    
    init(connContext: ConnectionContext,
         factory: RTCPeerConnectionFactory,
         mediaOption: MediaOption,
         handler: ((RTCPeerConnection!, [RTCMediaStream], Error?) -> ()))
    {
        self.connContext = connContext
        self.factory = factory
        self.mediaOption = mediaOption
        onConnectedHandler = handler
    }
    
    func createPeerConnection() {
        peerConn = factory.peerConnectionWithConfiguration(
            mediaOption.configuration,
            constraints: mediaOption.mediaConstraints,
            delegate: self)
    }
    
    func peerConnection(peerConnection: RTCPeerConnection,
                        didChangeSignalingState stateChanged: RTCSignalingState) {
        print("peerConnection:didChangeSignalingState:", stateChanged.rawValue)
    }
    
    func peerConnection(peerConnection: RTCPeerConnection,
                        didAddStream stream: RTCMediaStream) {
        print("peerConnection:didAddStream:")
        mediaStreams.append(stream)
    }
    
    func peerConnection(peerConnection: RTCPeerConnection,
                        didRemoveStream stream: RTCMediaStream) {
        print("peerConnection:didRemoveStream:")
        mediaStreams = mediaStreams.filter { e in return e == stream }
    }
    
    func peerConnectionShouldNegotiate(peerConnection: RTCPeerConnection) {
        print("peerConnectionShouldNegotiate:")
    }
    
    func peerConnection(peerConnection: RTCPeerConnection,
                        didChangeIceConnectionState newState: RTCIceConnectionState) {
        print("peerConnection:didChangeIceConnectionState:", newState.rawValue)
        switch newState {
        case .Connected:
            print("ice connection connected")
            connContext.state = .Ready
            onConnectedHandler(peerConnection, mediaStreams, nil)
        default:
            break
        }
    }
    
    func peerConnection(peerConnection: RTCPeerConnection,
                        didChangeIceGatheringState newState: RTCIceGatheringState) {
        print("peerConnection:didChangeIceGatheringState:")
    }
    
    func peerConnection(peerConnection: RTCPeerConnection,
                        didGenerateIceCandidate candidate: RTCIceCandidate) {
        print("peerConnection:didGenerateIceCandidate:")
        connContext.send(SignalingICECandidate(candidate: candidate.sdp))
    }
    
    func peerConnection(peerConnection: RTCPeerConnection,
                        didRemoveIceCandidates candidates: [RTCIceCandidate]) {
        print("peerConnection:didRemoveIceCandidates:")
    }
    
    func peerConnection(peerConnection: RTCPeerConnection,
                        didOpenDataChannel dataChannel: RTCDataChannel) {
        print("peerConnection:didOpenDataChannel:")
    }
    
}