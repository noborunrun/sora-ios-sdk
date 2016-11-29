import Foundation
import WebRTC

public enum MediaStreamRole {
    
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
    
    public var connection: Connection
    public var mediaPublisher: MediaPublisher!
    public var mediaSubscriber: MediaSubscriber!
    
    public init(connection: Connection) {
        self.connection = connection
        mediaPublisher = MediaPublisher(connection: connection, mediaChannel: self)
        mediaSubscriber = MediaSubscriber(connection: connection, mediaChannel: self)
    }

}
