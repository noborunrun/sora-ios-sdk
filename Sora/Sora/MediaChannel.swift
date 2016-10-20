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

public struct MediaChannel {
    
    public var connection: Connection
    public var channelId: String
    public var creationTime: Date
    public var mediaPublisher: MediaPublisher?
    public var mediaSubscriber: MediaSubscriber?
    
    init(connection: Connection, channelId: String) {
        self.connection = connection
        self.channelId = channelId
        creationTime = Date()
    }
    
    public func disconnect() {
        mediaPublisher?.disconnect()
        mediaSubscriber?.disconnect()
    }
    
    public mutating func createMediaPublisher(
        _ mediaOption: MediaOption = MediaOption(),
        accessToken: String? = nil,
        videoCaptureSourceMediaConstraints: RTCMediaConstraints? = nil,
        handler: @escaping ((MediaPublisher?, Error?) -> Void))
    {
        // TODO:
        print("create publisher")
        var weakSelf = self
        connection.createMediaUpstream(channelId,
                                       accessToken: accessToken,
                                       mediaOption: mediaOption,
                                       streamId: "main")
        {
            (mediaStream, mediaCapturer, error) in
            if let error = error {
                handler(nil, error)
                return
            }
            
            weakSelf.mediaPublisher = MediaPublisher(
                connection: weakSelf.connection,
                mediaStream: mediaStream!,
                mediaOption: mediaOption,
                mediaCapturer: mediaCapturer!)
            handler(weakSelf.mediaPublisher, nil)
        }
    }
    
    public mutating func createMediaSubscriber(_ mediaOption: MediaOption = MediaOption(),
                                               accessToken: String? = nil,
                                               handler: @escaping ((MediaSubscriber?, Error?) -> Void)) {
        // TODO:
        print("create subscriber")
        var weakSelf = self
        connection.createMediaDownstream(channelId, accessToken: accessToken,
                                         mediaOption: mediaOption)
        {
            (mediaStream, error) in
            if let error = error {
                handler(nil, error)
                return
            }
            weakSelf.mediaSubscriber = MediaSubscriber(
                connection: weakSelf.connection,
                mediaStream: mediaStream!,
                mediaOption: mediaOption)
            handler(weakSelf.mediaSubscriber, nil)
        }
    }
    
}
