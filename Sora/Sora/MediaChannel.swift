import Foundation
import WebRTC

public enum Role {
    
    case upstream
    case downstream
    
}

public enum VideoCodec {
    
    case vp8
    case vp9
    case h264
    
}

public enum AudioCodec {
    
    case opus
    case pcmu
        
}

public class MediaChannel {
    
    public weak var connection: Connection!
    public var mediaChannelId: String
    public var mediaPublisher: MediaPublisher?
    public var mediaSubscriber: MediaSubscriber?
    
    init(connection: Connection, mediaChannelId: String) {
        self.connection = connection
        self.mediaChannelId = mediaChannelId
    }
    
    public func disconnect(handler: @escaping (MediaConnection, ConnectionError?) -> Void) {
        mediaPublisher?.disconnect {
            error in
            handler(self.mediaPublisher!, error)
        }
        mediaSubscriber?.disconnect {
            error in
            handler(self.mediaSubscriber!, error)
        }
    }
    
    public func createMediaPublisher(mediaOption: MediaOption? = nil)
        -> MediaPublisher
    {
        return MediaPublisher(mediaChannel: self,
                              mediaChannelId: mediaChannelId,
                              mediaOption: mediaOption)
    }
    
    public func createMediaSubscriber(mediaOption: MediaOption? = nil)
        -> MediaSubscriber
    {
        return MediaSubscriber(mediaChannel: self,
                               mediaChannelId: mediaChannelId,
                               mediaOption: mediaOption)
    }
    
    // MARK: イベントハンドラ
    
    var onMediaConnectionConnectHandler: ((MediaConnection, ConnectionError?) -> Void)?
    var onMediaConnectionDisconnectHandler: ((MediaConnection, ConnectionError?) -> Void)?
    var onMediaConnectionFailureHandler:
    ((MediaConnection, ConnectionError) -> Void)?
    var onMediaConnectionUpdateHandler:
    ((MediaConnection, MediaConnection.Statistics) -> Void)?
    var onMediaConnectionNotifyHandler:
    ((MediaConnection, MediaConnection.Notification) -> Void)?
    
    public func onMediaConnectionConnect(handler:
        @escaping ((MediaConnection, ConnectionError?) -> Void)) {
        onMediaConnectionConnectHandler = handler
    }
    
    public func onMediaConnectionDisconnect(handler:
        @escaping ((MediaConnection, ConnectionError?) -> Void)) {
        onMediaConnectionDisconnectHandler = handler
    }
    
    public func onMediaConnectionFailure(handler:
        @escaping ((MediaConnection, ConnectionError) -> Void)) {
        onMediaConnectionFailureHandler = handler
    }
    
    public func onMediaConnectionUpdate(handler:
        @escaping ((MediaConnection, MediaConnection.Statistics) -> Void)) {
        onMediaConnectionUpdateHandler = handler
    }
    
    public func onMediaConnectionNotify(handler:
        @escaping ((MediaConnection, MediaConnection.Notification) -> Void)) {
        onMediaConnectionNotifyHandler = handler
    }

}
