import Foundation
import WebRTC
import SocketRocket
import UIKit

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
            onUpdatedHandler?(self, state)
        }
        
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
    
    public func connect(handler: ((Connection, Error?) -> ())) {
        context.connect(handler)
    }
    
    public func disconnect(handler: ((Connection, Error?) -> ())) {
        context.disconnect(handler)
    }
    
    public func send(message: Data, handler: ((Connection, Error?) -> ())?) {
        // TODO:
    }
    
    // メディアチャネル
    public func createMediaChannel(channelId: String,
                                   accessToken: String? = nil,
                                   publisherOption: MediaOption = MediaOption(),
                                   subscriberOption: MediaOption = MediaOption(),
                                   usesDevice: Bool = true,
                                   handler: ((MediaChannel?, Error?) -> ())) {
        // TODO:
    }
    
    func createMediaStream(role: Role, channelId: String,
                           accessToken: String? = nil,
                           handler: ((Connection, MediaStream?, Error?) -> ())) {
        context.createMediaStream(role, channelId: channelId, accessToken: accessToken, handler: handler)
    }
    
    // MARK: イベントハンドラ
    
    var onReceiveHandler: ((Connection, Data) -> ())?
    var onConnectedHandler: ((Connection) -> ())?
    var onDisconnectedHandler: ((Connection) -> ())?
    var onUpdatedHandler: ((Connection, State) -> ())?
    var onFailedHandler: ((Connection, Error) -> ())?
    var onPingHandler: ((Connection) -> ())?
    
    // シグナリングメッセージ
    public mutating func onReceive(handler: ((Connection, Data) -> ())) {
        onReceiveHandler = handler
    }
    
    // 接続
    public mutating func onConnected(handler: ((Connection) -> ())) {
        onConnectedHandler = handler
    }
    
    public mutating func onDisconnected(handler: ((Connection) -> ())) {
        onDisconnectedHandler = handler
    }
    
    public mutating func onUpdated(handler: ((Connection, State) -> ())) {
        onUpdatedHandler = handler
    }
    
    public mutating func onFailed(handler: ((Connection, Error) -> ())) {
        onFailedHandler = handler
    }
    
    public mutating func onPing(handler: ((Connection) -> ())) {
        onPingHandler = handler
    }
    
    // MARK: イベントハンドラ: メディアチャネル
    
    var onDisconnectMediaChannelHandler: ((Connection, MediaChannel) -> ())?
    var onMediaChannelFailedHandler: ((Connection, MediaChannel, Error) -> ())?
    
    public mutating func onDisconnectMediaChannel(handler: ((Connection, MediaChannel) -> ())) {
        onDisconnectMediaChannelHandler = handler
    }
    
    public mutating func onMediaChannelFailed(handler: ((Connection, MediaChannel, Error) -> ())) {
        onMediaChannelFailedHandler = handler
    }
    
    // MARK: イベントハンドラ: Web フック
    
    var onSignalingConnectedHandler: ((Connection, SignalingConnected) -> ())?
    var onSignalingCompletedHandler: ((Connection, SignalingCompleted) -> ())?
    var onSignalingDisconnectedHandler: ((Connection, SignalingDisconnected) -> ())?
    var onSignalingFailedHandler: ((Connection, SignalingFailed) -> ())?
    var onArchiveFinishedHandler: ((Connection, MediaChannel, ArchiveFinished) -> ())?
    var onArchiveFailedHandler: ((Connection, MediaChannel, ArchiveFailed) -> ())?
    
    public mutating func onSignalingConnected(handler: ((Connection, SignalingConnected) -> ())) {
        onSignalingConnectedHandler = handler
    }
    
    public mutating func onSignalingCompleted(handler: ((Connection, SignalingCompleted) -> ())) {
        onSignalingCompletedHandler = handler
    }
    
    public mutating func onSignalingDisconnected(handler: ((Connection, SignalingDisconnected) -> ())) {
        onSignalingDisconnectedHandler = handler
    }
    
    public mutating func onSignalingFailedHandler(handler: ((Connection, SignalingFailed) -> ())) {
        onSignalingFailedHandler = handler
    }
    
    public mutating func onArchiveFinished(handler: ((Connection, MediaChannel, ArchiveFinished) -> ())) {
        onArchiveFinishedHandler = handler
    }
    
    public mutating func onArchiveFailed(handler: ((Connection, MediaChannel, ArchiveFailed) -> ())) {
        onArchiveFailedHandler = handler
    }
    
    // MARK: イベントハンドラ: プッシュ通知
    
    var onReceivePushHandler: ((Connection, MediaChannel?, Data) -> ())?
    
    public mutating func onReceivePush(handler: ((Connection, MediaChannel?, Data) -> ())) {
        onReceivePushHandler = handler
    }
    
}

class ConnectionContext: NSObject, SRWebSocketDelegate {
    
    enum State {
        case Connecting
        case Connected
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
    
    var onConnectedHandler: ((Connection, Error?) -> ())?
    var onDisconnectedHandler: ((Connection, Error?) -> ())?
    var onSentHandler: ((Connection, Error?) -> ())?
    
    init(connection: Connection) {
        self.conn = connection
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
    
    func connect(handler: ((Connection, Error?) -> ())) {
        if state != .Disconnected {
            handler(conn, Error.ConnectionBusy)
            return
        }
        state = .Connecting
        onConnectedHandler = handler
        webSocket = SRWebSocket(URL: conn.URL)
        webSocket.delegate = self
        webSocket.open()
    }
    
    func disconnect(handler: ((Connection, Error?) -> ())) {
        if let error = validateState() {
            handler(conn, error)
            return
        }
        state = .Disconnecting
        onDisconnectedHandler = handler
        webSocket.close()
        webSocket = nil
    }
    
    func createMediaStream(role: Role, channelId: String,
                           accessToken: String? = nil,
                           handler: ((Connection, MediaStream?, Error?) -> ())) {
        if let error = validateState() {
            handler(conn, nil, error)
            return
         }
        
        // TODO:
        /*
         var sigConnect = SignalingConnect(role: SignalingRole.from(stream.role),
         channel_id: stream.channelId)
         */
        
    }
    
    // MARK: SRWebSocketDelegate
    
    func webSocketDidOpen(webSocket: SRWebSocket!) {
        state = .Connected
        onConnectedHandler?(conn, nil)
    }
    
    func webSocket(webSocket: SRWebSocket!, didFailWithError error: NSError!) {
        // TODO:
    }
    
    func webSocket(webSocket: SRWebSocket!, didReceivePong pongPayload: NSData!) {
        // TODO:
    }
    
    func webSocket(webSocket: SRWebSocket!, didReceiveMessage message: AnyObject!) {
        // TODO:
    }
    
    func webSocket(webSocket: SRWebSocket!, didCloseWithCode code: Int, reason: String!, wasClean: Bool) {
        var error: Error? = nil
        if let reason = reason {
            error = Error.WebSocketError(reason)
        }
        onDisconnectedHandler?(conn, error)
    }
    
}