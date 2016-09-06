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
    case UnknownType
    case ConnectWaitTimeout
    case ConnectionDisconnected
    case ConnectionBusy
    case WebSocketError(String)
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
    
    public var defaultConfiguration: RTCConfiguration
    public var defaultMediaConstraints: RTCMediaConstraints
    
    var webSocket: SRWebSocket?
    var context: ConnectionContext!
    
    public init(URL: NSURL) {
        self.URL = URL
        state = .Disconnected
        creationTime = NSDate()
        defaultConfiguration = RTCConfiguration()
        defaultConfiguration.iceServers = [
            RTCIceServer(URLStrings: ["stun:stun.l.google.com:19302"],
                username: nil, credential: nil)]
        defaultMediaConstraints = RTCMediaConstraints(
            mandatoryConstraints: nil, optionalConstraints: nil)
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
    
    // メディアチャネル
    public func createMediaChannel(channelId: String,
                                   accessToken: String? = nil,
                                   publisherOption: MediaOption = MediaOption(),
                                   publisherConfiguration: RTCConfiguration? = nil,
                                   publisherConstraints: RTCMediaConstraints? = nil,
                                   subscriberOption: MediaOption = MediaOption(),
                                   subscriberConfiguration: RTCConfiguration? = nil,
                                   subscriberConstraints: RTCMediaConstraints? = nil,
                                   usesDevice: Bool = true,
                                   handler: ((MediaChannel?, Error?) -> ())) {
        print("create media streams")
        context.createPeerConnection(
            Role.Downstream, channelId: channelId,
            accessToken: accessToken,
            config: publisherConfiguration ?? defaultConfiguration,
            constraints: publisherConstraints ?? defaultMediaConstraints) {
                (peerConn, error) in
                print("on peer connection open: ", error)
        }
        
        /*
        print("create media channel")
        let channel = MediaChannel(connection: self, channelId: channelId,
            publisherOption: publisherOption, subscriberOption: subscriberOption)
        var weakSelf = self
        channel.connect { (error) in
            print("create media channel handler")
            if error == nil {
                weakSelf.mediaChannels.append(channel)
            }
            handler(channel, error)
        }
         */
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
        case PeerConnected
    }
    
    var conn: Connection!
    var webSocket: SRWebSocket!
    var state: State = .Disconnected
    var peerConn: RTCPeerConnection?
    var peerConnFactory: RTCPeerConnectionFactory
    
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
        webSocket.send(message.JSONString())
    }
    
    func createPeerConnection(role: Role, channelId: String,
                              accessToken: String? = nil,
                              config: RTCConfiguration,
                              constraints: RTCMediaConstraints,
                              handler: ((RTCPeerConnection?, Error?) -> ())) {
        if let error = validateState() {
            handler(nil, error)
            return
        }
        
        peerConn = peerConnFactory.peerConnectionWithConfiguration(config, constraints: constraints, delegate: PeerConnectionContext(connContext: self))
        
        // send "connect"
        print("send connect")
        state = .PeerConnecting
        let sigConnect = SignalingConnect(role: SignalingRole.from(role), channel_id: channelId)
        send(sigConnect.message())
    }
    
    // MARK: SRWebSocketDelegate
    
    func webSocketDidOpen(webSocket: SRWebSocket!) {
        state = .Ready
        onConnectedHandler?(nil)
    }
    
    func webSocket(webSocket: SRWebSocket!, didFailWithError error: NSError!) {
        // TODO:
        print("webSocket:didFailWithError:")
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
            switch message.type() {
            case "offer"?:
                if let offer = SignalingOffer.decode(json).value {
                    print("peer offered")
                    state = .PeerOffered
                    let sdp = offer.sessionDescription()
                    peerConn!.setRemoteDescription(sdp) {
                        (error: NSError?) in
                        if let error = error {
                            self.conn.onFailedHandler?(Error.PeerConnectionError(error))
                            return
                        }

                        // TODO:
                        print("create answer")
                        self.state = .PeerAnswering
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
            error = Error.WebSocketError(reason)
        }
        onDisconnectedHandler?(error)
    }
    
}

class PeerConnectionContext: NSObject, RTCPeerConnectionDelegate {
    
    var connContext: ConnectionContext
    
    init(connContext: ConnectionContext) {
        self.connContext = connContext
    }
    
    func peerConnection(peerConnection: RTCPeerConnection,
                               didChangeSignalingState stateChanged: RTCSignalingState) {
        print("peerConnection:didChangeSignalingState:")
    }
    
    func peerConnection(peerConnection: RTCPeerConnection, didAddStream stream: RTCMediaStream) {
        print("peerConnection:didAddStream:")
    }
    
    func peerConnection(peerConnection: RTCPeerConnection,
                        didRemoveStream stream: RTCMediaStream) {
        print("peerConnection:didRemoveStream:")
    }
    
    func peerConnectionShouldNegotiate(peerConnection: RTCPeerConnection) {
        print("peerConnectionShouldNegotiate:")
    }
    
    func peerConnection(peerConnection: RTCPeerConnection,
                        didChangeIceConnectionState newState: RTCIceConnectionState) {
        print("peerConnection:didChangeIceConnectionState:")
    }
    
    func peerConnection(peerConnection: RTCPeerConnection,
                        didChangeIceGatheringState newState: RTCIceGatheringState) {
        print("peerConnection:didChangeIceGatheringState:")
    }
    
    func peerConnection(peerConnection: RTCPeerConnection,
                        didGenerateIceCandidate candidate: RTCIceCandidate) {
        print("peerConnection:didGenerateIceCandidate:")
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