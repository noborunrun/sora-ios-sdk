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
    
    var onReceiveHandler: ((Data) -> ())?
    var onConnectedHandler: (() -> ())?
    var onDisconnectedHandler: (() -> ())?
    var onUpdatedHandler: ((State) -> ())?
    var onFailedHandler: ((Error) -> ())?

    // シグナリングメッセージ
    public mutating func onReceive(handler: ((Data) -> ())) {
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
    
    var onReceivePushHandler: ((MediaChannel?, Data) -> ())?

    public mutating func onReceivePush(handler: ((MediaChannel?, Data) -> ())) {
        onReceivePushHandler = handler
    }

}

class Context {
    
    // MARK: イベントハンドラ
    
    var onConnectedHandler: ((Error?) -> ())?
    var onDisconnectedHandler: ((Error?) -> ())?
    var onSentHandler: ((Error?) -> ())?
    
}