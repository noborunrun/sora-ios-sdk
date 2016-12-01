import Foundation
import WebRTC

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
