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
    case peerConnectionError(Error)
}

public class Connection {
    
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
    public var eventLog: EventLog = EventLog()
    
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
    
    func config() {
        context = ConnectionContext(connection: self)
    }
    
    // MARK: シグナリング接続
    
    public func connect(_ handler: @escaping ((ConnectionError?) -> Void)) {
        context.connect(handler)
    }
    
    public func disconnect(_ handler: @escaping ((ConnectionError?) -> Void)) {
        for channel in mediaChannels {
            channel.disconnect()
        }
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
        let channel = MediaChannel(connection: self, channelId: channelId)
        mediaChannels.append(channel)
        return channel
    }
    
    func createMediaUpstream(_ channelId: String, accessToken: String?,
                             mediaOption: MediaOption,
                             streamId: String,
                             handler: @escaping ((MediaStream?, MediaCapturer?, Error?) -> Void)) {
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
                               handler: @escaping ((MediaStream?, Error?) -> Void)) {
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
    
    var onReceiveHandler: ((Message) -> Void)?
    var onConnectedHandler: ((Void) -> Void)?
    var onDisconnectedHandler: ((Void) -> Void)?
    var onUpdatedHandler: ((State) -> Void)?
    var onFailedHandler: ((ConnectionError) -> Void)?
    var onPingHandler: ((Void) -> Void)?
    
    // シグナリングメッセージ
    public func onReceive(_ handler: @escaping ((Message) -> Void)) {
        onReceiveHandler = handler
    }
    
    // 接続
    public func onConnected(_ handler: @escaping ((Void) -> Void)) {
        onConnectedHandler = handler
    }
    
    public func onDisconnected(_ handler: @escaping ((Void) -> Void)) {
        onDisconnectedHandler = handler
    }
    
    public func onUpdated(_ handler: @escaping ((State) -> Void)) {
        onUpdatedHandler = handler
    }
    
    public func onFailed(_ handler: @escaping ((ConnectionError) -> Void)) {
        onFailedHandler = handler
    }
    
    public func onPing(_ handler: @escaping ((Void) -> Void)) {
        onPingHandler = handler
    }
    
    // MARK: イベントハンドラ: メディアチャネル
    
    var onDisconnectMediaChannelHandler: ((MediaChannel) -> Void)?
    var onMediaChannelFailedHandler: ((MediaChannel, Error) -> Void)?
    
    public func onDisconnectMediaChannel(_ handler: @escaping ((MediaChannel) -> Void)) {
        onDisconnectMediaChannelHandler = handler
    }
    
    public func onMediaChannelFailed(_ handler: @escaping ((MediaChannel, Error) -> Void)) {
        onMediaChannelFailedHandler = handler
    }
    
    // MARK: イベントハンドラ: Web フック
    
    var onSignalingConnectedHandler: ((SignalingConnected) -> Void)?
    var onSignalingCompletedHandler: ((SignalingCompleted) -> Void)?
    var onSignalingDisconnectedHandler: ((SignalingDisconnected) -> Void)?
    var onSignalingFailedHandler: ((SignalingFailed) -> Void)?
    var onArchiveFinishedHandler: ((MediaChannel, ArchiveFinished) -> Void)?
    var onArchiveFailedHandler: ((MediaChannel, ArchiveFailed) -> Void)?
    
    public func onSignalingConnected(_ handler: @escaping ((SignalingConnected) -> Void)) {
        onSignalingConnectedHandler = handler
    }
    
    public func onSignalingCompleted(_ handler: @escaping ((SignalingCompleted) -> Void)) {
        onSignalingCompletedHandler = handler
    }
    
    public func onSignalingDisconnected(_ handler: @escaping ((SignalingDisconnected) -> Void)) {
        onSignalingDisconnectedHandler = handler
    }
    
    public func onSignalingFailedHandler(_ handler: @escaping ((SignalingFailed) -> Void)) {
        onSignalingFailedHandler = handler
    }
    
    public func onArchiveFinished(_ handler: @escaping ((MediaChannel, ArchiveFinished) -> Void)) {
        onArchiveFinishedHandler = handler
    }
    
    public func onArchiveFailed(_ handler: @escaping ((MediaChannel, ArchiveFailed) -> Void)) {
        onArchiveFailedHandler = handler
    }
    
    // MARK: イベントハンドラ: プッシュ通知
    
    var onReceivePushHandler: ((MediaChannel?, Message) -> Void)?
    
    public func onReceivePush(_ handler: @escaping ((MediaChannel?, Message) -> Void)) {
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

    var onConnectedHandler: ((ConnectionError?) -> Void)?
    var onDisconnectedHandler: ((ConnectionError?) -> Void)?
    var onSentHandler: ((ConnectionError?) -> Void)?
    
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
    
    func connect(_ handler: @escaping ((ConnectionError?) -> Void)) {
        if state != .disconnected {
            handler(ConnectionError.connectionBusy)
            return
        }
        
        conn.eventLog.mark(event:
            Event(type: .WebSocket,
                  comment: String(format: "open %@", conn.URL.description)))
        state = .connecting
        onConnectedHandler = handler
        webSocket = SRWebSocket(url: conn.URL)
        webSocket.delegate = self
        webSocket.open()
    }
    
    func disconnect(_ handler: @escaping ((ConnectionError?) -> Void)) {
        if let error = validateState() {
            handler(error)
            return
        }
        state = .disconnecting
        onDisconnectedHandler = handler
        webSocket.close()
        webSocket = nil
        conn.eventLog.mark(event:
            Event(type: .WebSocket, comment: "close"))
    }
    
    func send(_ message: Message) {
        let j = message.JSON()
        let data = try! JSONSerialization.data(withJSONObject: j,
                                               options: JSONSerialization.WritingOptions(rawValue: 0))
        let msg = NSString(data: data, encoding: String.Encoding.utf8.rawValue) as String!
        print("WebSocket send ", j)
        webSocket.send(msg)
    }

    func send(_ messageable: Messageable) {
        self.send(messageable.message())
    }
    
    func createPeerConnection(_ role: Role, channelId: String,
                              accessToken: String?, mediaOption: MediaOption,
                              handler: @escaping ((RTCPeerConnection?, RTCMediaStream?, RTCMediaStream?, MediaCapturer?, Error?) -> Void)) {
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
        conn.eventLog.mark(event: Event(type: .WebSocket, comment: "opened"))
        state = .ready
        onConnectedHandler?(nil)
    }
    
    func webSocket(_ webSocket: SRWebSocket!, didFailWithError error: Error!) {
        print("webSocket:didFailWithError:")
        let connError = ConnectionError.webSocketError(error)
        switch state {
        case .connecting:
            onConnectedHandler?(connError)
        case .disconnecting:
            onDisconnectedHandler?(connError)
        default:
            break
        }
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
            print("received message type: ", message.type)
            switch message.type {
            case .ping?:
                conn.eventLog.mark(event: Event(type: .Signaling,
                                                comment: "receive ping"))
                self.send(SignalingPong())
                
            case .offer?:
                conn.eventLog.mark(event: Event(type: .Signaling,
                                                comment: "receive offer"))
                let offer: SignalingOffer!
                do {
                    offer = Optional.some(try unbox(dictionary: json))
                } catch {
                    print("parse fail")
                    state = .ready
                    return
                }
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
                        let server = RTCIceServer(urlStrings: serverConfig.urls,
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
                    (error: Error?) in
                    if let error = error {
                        self.conn.onFailedHandler?(ConnectionError.peerConnectionError(error))
                        return
                    }
                    
                    print("create answer")
                    self.state = .peerAnswering
                    self.peerConnContext.peerConn.answer(for: self.peerConnContext.mediaOption.answerMediaConstraints) {
                        (sdp, error) in
                        if let error = error {
                            self.conn.onFailedHandler?(ConnectionError.peerConnectionError(error))
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
            default:
                return
            }
        }
    }
    
    func webSocket(_ webSocket: SRWebSocket!, didCloseWithCode code: Int, reason: String!, wasClean: Bool) {
        print("webSocket:didCloseWithCode:", code)
        switch state {
        case .connecting:
            onConnectedHandler?(nil)
        case .disconnecting:
            onDisconnectedHandler?(nil)
        default:
            break
        }
    }
    
}

class PeerConnectionContext: NSObject, RTCPeerConnectionDelegate {
    
    var connContext: ConnectionContext
    var factory: RTCPeerConnectionFactory
    var peerConn: RTCPeerConnection!
    var downstream: RTCMediaStream?
    var mediaOption: MediaOption
    var onConnectedHandler: ((RTCPeerConnection?, RTCMediaStream?, Error?) -> Void)
    
    init(connContext: ConnectionContext,
         factory: RTCPeerConnectionFactory,
         mediaOption: MediaOption,
         handler: @escaping ((RTCPeerConnection?, RTCMediaStream?, Error?) -> Void))
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
