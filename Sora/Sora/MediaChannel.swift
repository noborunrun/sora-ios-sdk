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
    
    public var connection: Connection
    public var channelId: String
    public var creationTime: NSDate
    public var mediaPublisher: MediaPublisher?
    public var mediaSubscriber: MediaSubscriber?
    
    init(connection: Connection, channelId: String) {
        self.connection = connection
        self.channelId = channelId
        creationTime = NSDate()
    }
    
    public func disconnect() {
        mediaPublisher?.disconnect()
        mediaSubscriber?.disconnect()
    }
    
    public mutating func createMediaPublisher(mediaOption: MediaOption = MediaOption(),
                                              accessToken: String? = nil,
                                              handler: ((MediaPublisher?, Error?) -> ())) {
        // TODO:
        print("create publisher")
        connection.createMediaStream(Role.Downstream, channelId: channelId,
                                     accessToken: accessToken, mediaOption: mediaOption)
        {
            (mediaStream, error) in
            if let error = error {
                handler(nil, error)
                return
            }
            self.mediaPublisher = MediaPublisher(connection: self.connection,
                                                 mediaStream: mediaStream!,
                                                 mediaOption: mediaOption)
            handler(self.mediaPublisher, nil)
        }
    }
    
    public mutating func createMediaSubscriber(mediaOption: MediaOption = MediaOption(),
                                               accessToken: String? = nil,
                                               handler: ((MediaSubscriber?, Error?) -> ())) {
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
            self.mediaSubscriber = MediaSubscriber(connection: self.connection,
                                                   mediaStream: mediaStream!,
                                                   mediaOption: mediaOption)
            handler(self.mediaSubscriber, nil)
        }
    }
    
}
