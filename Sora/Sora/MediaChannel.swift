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
        
}
