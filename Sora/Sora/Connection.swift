import Foundation
import WebRTC
import SocketRocket
import UIKit
import Unbox

public enum ConnectionError: Error {
    case failureJSONDecode
    case duplicatedChannelId
    case authenticationFailure
    case authenticationInternalError
    case unknownVideoCodecType
    case failureSDPParse
    case failureMissingSDP
    case failureSetConfiguration(RTCConfiguration)
    case unknownType
    case connectWaitTimeout
    case connectionDisconnected
    case connectionBusy
    case multipleDownstreams
    case webSocketClose(Int, String)
    case webSocketError(Error)
    case peerConnectionError(NSError)
}

public struct Connection {
    
    public enum State {
        case connected
        case connecting
        case disconnected
        case disconnecting
    }
    
    public var URL: Foundation.URL
    public var clientId: String?
    public var creationTime: Date
    public var mediaChannels: [MediaChannel] = []
    
    public var state: State = .disconnected {
        
        didSet {
            onUpdatedHandler?(state)
        }
        
    }

    public var peerConnectionFactory: RTCPeerConnectionFactory {
        get { return context.peerConnFactory }
    }
    
    var webSocket: SRWebSocket?
    var context: ConnectionContext!
    
    public init(URL: Foundation.URL) {
        self.URL = URL
        state = .disconnected
        creationTime = Date()
        config()
    }
    
    mutating func config() {
        context = ConnectionContext(connection: self)
    }
    
    // MARK: シグナリング接続
    
    public func connect(_ handler: @escaping ((ConnectionError?) -> ())) {
        context.connect(handler)
    }
    
    public func disconnect(_ handler: @escaping ((ConnectionError?) -> ())) {
        context.disconnect(handler)
    }
    
    public func send(_ message: Message) {
        context.send(message)
    }
    
    public func send(_ messageable: Messageable) {
        context.send(messageable.message())
    }
    
    public func isReady() -> Bool {
        return context.state == .ready
    }
    
    // メディアチャネル
    public func createMediaChannel(_ channelId: String) -> MediaChannel {
        return MediaChannel(connection: self, channelId: channelId)
    }
    
    func createMediaUpstream(_ channelId: String, accessToken: String?,
                             mediaOption: MediaOption,
                             streamId: String,
                             handler: @escaping ((MediaStream?, MediaCapturer?, Error?) -> ())) {
        context.createPeerConnection(Role.upstream, channelId: channelId,
                                     accessToken: accessToken,
                                     mediaOption: mediaOption)
        {
            (peerConn, upstream, downstream, mediaCapturer, error) in
            print("on peer connection open: ", error)
            if let error = error {
                handler(nil, nil, error)
                return
            }
            assert(upstream != nil, "upstream is nil")
            let mediaStream = MediaStream.new(peerConn!,
                                              role: Role.upstream,
                                              channelId: channelId,
                                              mediaOption: mediaOption,
                                              nativeMediaStream: upstream!)
            handler(mediaStream, mediaCapturer, nil)
        }
    }
    
    func createMediaDownstream(_ channelId: String, accessToken: String?,
                               mediaOption: MediaOption,
                               handler: @escaping ((MediaStream?, Error?) -> ())) {
        context.createPeerConnection(Role.downstream, channelId: channelId,
                                     accessToken: accessToken,
                                     mediaOption: mediaOption)
        {
            (peerConn, upstream, downstream, mediaCapturer, error) in
            print("on peer connection open: ", error)
            if let error = error {
                handler(nil, error)
                return
            }
            
            let mediaStream = MediaStream.new(peerConn!,
                                              role: Role.downstream,
                                              channelId: channelId,
                                              mediaOption: mediaOption,
                                              nativeMediaStream: downstream!)
            handler(mediaStream, nil)
        }
    }
    
    // MARK: イベントハンドラ
    
    var onReceiveHandler: ((Message) -> ())?
    var onConnectedHandler: (() -> ())?
    var onDisconnectedHandler: (() -> ())?
    var onUpdatedHandler: ((State) -> ())?
    var onFailedHandler: ((ConnectionError) -> ())?
    var onPingHandler: (() -> ())?
    
    // シグナリングメッセージ
    public mutating func onReceive(_ handler: @escaping ((Message) -> ())) {
        onReceiveHandler = handler
    }
    
    // 接続
    public mutating func onConnected(_ handler: @escaping (() -> ())) {
        onConnectedHandler = handler
    }
    
    public mutating func onDisconnected(_ handler: @escaping (() -> ())) {
        onDisconnectedHandler = handler
    }
    
    public mutating func onUpdated(_ handler: @escaping ((State) -> ())) {
        onUpdatedHandler = handler
    }
    
    public mutating func onFailed(_ handler: @escaping ((ConnectionError) -> ())) {
        onFailedHandler = handler
    }
    
    public mutating func onPing(_ handler: @escaping (() -> ())) {
        onPingHandler = handler
    }
    
    // MARK: イベントハンドラ: メディアチャネル
    
    var onDisconnectMediaChannelHandler: ((MediaChannel) -> ())?
    var onMediaChannelFailedHandler: ((MediaChannel, Error) -> ())?
    
    public mutating func onDisconnectMediaChannel(_ handler: @escaping ((MediaChannel) -> ())) {
        onDisconnectMediaChannelHandler = handler
    }
    
    public mutating func onMediaChannelFailed(_ handler: @escaping ((MediaChannel, Error) -> ())) {
        onMediaChannelFailedHandler = handler
    }
    
    // MARK: イベントハンドラ: Web フック
    
    var onSignalingConnectedHandler: ((SignalingConnected) -> ())?
    var onSignalingCompletedHandler: ((SignalingCompleted) -> ())?
    var onSignalingDisconnectedHandler: ((SignalingDisconnected) -> ())?
    var onSignalingFailedHandler: ((SignalingFailed) -> ())?
    var onArchiveFinishedHandler: ((MediaChannel, ArchiveFinished) -> ())?
    var onArchiveFailedHandler: ((MediaChannel, ArchiveFailed) -> ())?
    
    public mutating func onSignalingConnected(_ handler: @escaping ((SignalingConnected) -> ())) {
        onSignalingConnectedHandler = handler
    }
    
    public mutating func onSignalingCompleted(_ handler: @escaping ((SignalingCompleted) -> ())) {
        onSignalingCompletedHandler = handler
    }
    
    public mutating func onSignalingDisconnected(_ handler: @escaping ((SignalingDisconnected) -> ())) {
        onSignalingDisconnectedHandler = handler
    }
    
    public mutating func onSignalingFailedHandler(_ handler: @escaping ((SignalingFailed) -> ())) {
        onSignalingFailedHandler = handler
    }
    
    public mutating func onArchiveFinished(_ handler: @escaping ((MediaChannel, ArchiveFinished) -> ())) {
        onArchiveFinishedHandler = handler
    }
    
    public mutating func onArchiveFailed(_ handler: @escaping ((MediaChannel, ArchiveFailed) -> ())) {
        onArchiveFailedHandler = handler
    }
    
    // MARK: イベントハンドラ: プッシュ通知
    
    var onReceivePushHandler: ((MediaChannel?, Message) -> ())?
    
    public mutating func onReceivePush(_ handler: @escaping ((MediaChannel?, Message) -> ())) {
        onReceivePushHandler = handler
    }
    
}

class ConnectionContext: NSObject, SRWebSocketDelegate {
    
    enum State {
        case connecting
        case disconnecting
        case disconnected
        case ready
        case peerOffered
        case peerAnswering
        case peerAnswered
        case peerConnecting
    }
    
    var conn: Connection!
    var webSocket: SRWebSocket!
    var state: State = .disconnected
    var peerConnFactory: RTCPeerConnectionFactory
    var peerConnContext: PeerConnectionContext!
    var role: Role?
    var upstream: RTCMediaStream?
    var mediaCapturer: MediaCapturer?

    var onConnectedHandler: ((ConnectionError?) -> ())?
    var onDisconnectedHandler: ((ConnectionError?) -> ())?
    var onSentHandler: ((ConnectionError?) -> ())?
    
    init(connection: Connection) {
        self.conn = connection
        peerConnFactory = RTCPeerConnectionFactory()
    }
    
    func validateState() -> ConnectionError? {
        if state == .disconnected || state == .disconnecting {
            return ConnectionError.connectionDisconnected
        } else if state != .ready {
            return ConnectionError.connectionBusy
        } else {
            return nil
        }
    }
    
    func connect(_ handler: @escaping ((ConnectionError?) -> ())) {
        if state != .disconnected {
            handler(ConnectionError.connectionBusy)
            return
        }
        state = .connecting
        onConnectedHandler = handler
        webSocket = SRWebSocket(url: conn.URL)
        webSocket.delegate = self
        webSocket.open()
    }
    
    func disconnect(_ handler: @escaping ((ConnectionError?) -> ())) {
        if let error = validateState() {
            handler(error)
            return
        }
        state = .disconnecting
        onDisconnectedHandler = handler
        webSocket.close()
        webSocket = nil
    }
    
    func send(_ message: Message) {
        let j = message.JSONString()
        print("WebSocket send ", j)
        webSocket.send(j)
    }

    func send(_ messageable: Messageable) {
        self.send(messageable.message())
    }
    
    func createPeerConnection(_ role: Role, channelId: String,
                              accessToken: String?, mediaOption: MediaOption,
                              handler: @escaping ((RTCPeerConnection?, RTCMediaStream?, RTCMediaStream?, MediaCapturer?, Error?) -> ())) {
        if let error = validateState() {
            handler(nil, nil, nil, nil, error)
            return
        }
        
        self.role = role
        peerConnContext = PeerConnectionContext(connContext: self, factory: peerConnFactory, mediaOption: mediaOption) {
            (peerConn, downstream, error) in
            handler(peerConn, self.upstream, downstream, self.mediaCapturer, error)
        }
        peerConnContext.createPeerConnection()
        prepareUpstream()
        
        // send "connect"
        print("send connect")
        state = .peerConnecting
        let sigConnect = SignalingConnect(role: SignalingRole.from(role), channel_id: channelId)
        send(sigConnect)
    }
    
    func prepareUpstream() {
        if role == Role.upstream {
            print("create media capturer")
            upstream = peerConnFactory.mediaStream(withStreamId: MediaStream.defaultStreamId)
            let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
            mediaCapturer = MediaCapturer(factory: peerConnFactory, videoCaptureSourceMediaConstraints: constraints)
            upstream!.addVideoTrack(mediaCapturer!.videoCaptureTrack)
            upstream!.addAudioTrack(mediaCapturer!.audioCaptureTrack)
            peerConnContext.peerConn.add(upstream!)
        }
    }
    
    // MARK: SRWebSocketDelegate
    
    func webSocketDidOpen(_ webSocket: SRWebSocket!) {
        state = .ready
        onConnectedHandler?(nil)
    }
    
    func webSocket(_ webSocket: SRWebSocket!, didFailWithError error: Error!) {
        print("webSocket:didFailWithError:")
        onConnectedHandler?(ConnectionError.webSocketError(error))
    }
    
    func webSocket(_ webSocket: SRWebSocket!, didReceivePong pongPayload: Data!) {
        // TODO:
    }
    
    func webSocket(_ webSocket: SRWebSocket!, didReceiveMessage message: Any!) {
        // TODO:
        print("webSocket:didReceiveMessage:", message)
        
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
                            peerConfig.iceTransportPolicy = .relay
                        default:
                            print("unsupported iceTransportPolicy:",
                                  config.iceTransportPolicy)
                            state = .ready
                            return
                        }
                        
                        for serverConfig in config.iceServers {
                            let server = RTCIceServer(URLStrings: serverConfig.urls,
                                                      username: serverConfig.username,
                                                      credential: serverConfig.credential)
                            peerConfig.iceServers = [server]
                        }
                        
                        if !peerConnContext.peerConn.setConfiguration(peerConfig) {
                            print("failed setting configuration sent by offer")
                            onConnectedHandler?(ConnectionError.failureSetConfiguration(peerConfig))
                            state = .ready
                            return
                        }
                    }
                    
                    state = .peerOffered
                    let sdp = offer.sessionDescription()
                    peerConnContext.peerConn.setRemoteDescription(sdp) {
                        (error: NSError?) in
                        if let error = error {
                            self.conn.onFailedHandler?(ConnectionError.PeerConnectionError(error))
                            return
                        }
                        
                        print("create answer")
                        self.state = .PeerAnswering
                        self.peerConnContext.peerConn.answerForConstraints(self.peerConnContext.mediaOption.answerMediaConstraints) {
                            (sdp, error) in
                            if let error = error {
                                self.conn.onFailedHandler?(ConnectionError.PeerConnectionError(error))
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
    
    func webSocket(_ webSocket: SRWebSocket!, didCloseWithCode code: Int, reason: String!, wasClean: Bool) {
        print("webSocket:didCloseWithCode:", code)
        var error: Error? = nil
        if let reason = reason {
            error = ConnectionError.webSocketClose(code, reason)
        }
        onDisconnectedHandler?(error as! ConnectionError?)
    }
    
}

class PeerConnectionContext: NSObject, RTCPeerConnectionDelegate {
    
    var connContext: ConnectionContext
    var factory: RTCPeerConnectionFactory
    var peerConn: RTCPeerConnection!
    var downstream: RTCMediaStream?
    var mediaOption: MediaOption
    var onConnectedHandler: ((RTCPeerConnection?, RTCMediaStream?, Error?) -> ())
    
    init(connContext: ConnectionContext,
         factory: RTCPeerConnectionFactory,
         mediaOption: MediaOption,
         handler: @escaping ((RTCPeerConnection?, RTCMediaStream?, Error?) -> ()))
    {
        self.connContext = connContext
        self.factory = factory
        self.mediaOption = mediaOption
        onConnectedHandler = handler
    }
    
    func createPeerConnection() {
        peerConn = factory.peerConnection(
            with: mediaOption.configuration,
            constraints: mediaOption.mediaConstraints,
            delegate: self)
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didChange stateChanged: RTCSignalingState) {
        print("peerConnection:didChangeSignalingState:", stateChanged.rawValue)
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didAdd stream: RTCMediaStream) {
        print("peerConnection:didAddStream:")
        if downstream != nil {
            peerConnection.close()
            onConnectedHandler(nil, nil, ConnectionError.multipleDownstreams)
            return
        }
        downstream = stream
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didRemove stream: RTCMediaStream) {
        print("peerConnection:didRemoveStream:")
        if downstream == stream {
            downstream = nil
        }
    }
    
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        print("peerConnectionShouldNegotiate:")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didChange newState: RTCIceConnectionState) {
        print("peerConnection:didChangeIceConnectionState:", newState.rawValue)
        switch newState {
        case .connected:
            print("ice connection connected")
            connContext.state = .ready
            onConnectedHandler(peerConnection, downstream, nil)
        default:
            break
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didChange newState: RTCIceGatheringState) {
        print("peerConnection:didChangeIceGatheringState:")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didGenerate candidate: RTCIceCandidate) {
        print("peerConnection:didGenerateIceCandidate:")
        connContext.send(SignalingICECandidate(candidate: candidate.sdp))
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didRemove candidates: [RTCIceCandidate]) {
        print("peerConnection:didRemoveIceCandidates:")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didOpen dataChannel: RTCDataChannel) {
        print("peerConnection:didOpenDataChannel:")
    }
    
}
