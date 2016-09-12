import Foundation
import WebRTC

public enum Role {
    
    case Upstream
    case Downstream
    
}

public enum VideoCodec {
    
    case VP8
    case VP9
    case H264
    
}

public enum AudioCodec {
    
    case OPUS
    case PCMU
        
}

public struct MediaChannel {
    
    enum State {
        case Connected
        case Disconnected
        case Disconnecting
    }
    
    public var connection: Connection
    public var channelId: String
    public var accessToken: String?
    public var creationTime: NSDate
    public var publisher: Publisher?
    public var subscriber: Subscriber?
    
    init(connection: Connection, channelId: String) {
        self.connection = connection
        self.channelId = channelId
        creationTime = NSDate()
    }
    
    public func disconnect() {
        // TODO:
    }

    public func createPublisher(mediaOption: MediaOption = MediaOption(),
                                handler: ((Publisher?, Error?) -> ())) {
        // TODO:
    }
    
    public mutating func createSubscriber(mediaOption: MediaOption = MediaOption(),
                                          handler: ((Subscriber?, Error?) -> ())) {
        // TODO:
        print("create subscriber")
        connection.createMediaStream(Role.Downstream, channelId: channelId,
                          accessToken: accessToken, mediaOption: mediaOption)
        {
            (mediaStream, error) in
            if let error = error {
                handler(nil, error)
                return
            }
            self.subscriber = Subscriber(connection: self.connection, mediaStream: mediaStream!, mediaOption: mediaOption)
            handler(self.subscriber, nil)
        }
    }
}
