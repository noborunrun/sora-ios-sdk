import Foundation
import WebRTC
import SocketRocket
import UIKit

public typealias Data = [String: AnyObject]

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
}

public struct Connection {
    
    public enum State {
        case Connected
        case Connecting
        case Disconnected
        case Disconnecting
    }
    
    public var state: State
    public var clientId: String
    public var creationTime: NSDate
    public var mediaChannels: [MediaChannel]
    
    public init(clientId: String) {
        state = .Disconnected
        self.clientId = clientId
        creationTime = NSDate()
        mediaChannels = []
    }
    
    // MARK: シグナリング接続
    
    public mutating func connect(handler: ((Error?) -> ())) {
        // TODO:
    }
    
    public mutating func disconnect(handler: ((Error?) -> ())) {
        // TODO:
    }
    
    public func send(message: Data, handler: ((Error?) -> ())) {
        // TODO:
    }
    
    // メディアチャネル
    public func connectMediaChannel(channelId: String,
                                    accessToken: String? = nil,
                                    publisherOption: MediaOption = MediaOption(),
                                    subscriberOption: MediaOption = MediaOption(),
                                    usesDevice: Bool = true,
                                    handler: ((MediaChannel?, Error?) -> ()))
    {
        // TODO:
    }
    
    // MARK: イベントハンドラ
    
    var onReceiveHandler: ((Connection, Data) -> ())?
    var onConnectedHandler: ((Connection) -> ())?
    var onDisconnectedHandler: ((Connection) -> ())?
    var onUpdatedHandler: ((Connection, State) -> ())?
    var onFailedHandler: ((Connection, Error) -> ())?

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

class Context {
    
    // MARK: イベントハンドラ
    
    var onConnectedHandler: ((Error?) -> ())?
    var onDisconnectedHandler: ((Error?) -> ())?
    var onSentHandler: ((Error?) -> ())?
    
}