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
    
    // TODO: reimpl
    public func createMediaPublisher(
        mediaOption: MediaOption? = nil,
        accessToken: String? = nil,
        mediaStreamId: String? = nil,
        videoCaptureTrackId: String? = nil,
        audioCaptureTrackId: String? = nil,
        videoCaptureSourceMediaConstraints: RTCMediaConstraints? = nil,
        handler: @escaping ((MediaPublisher?, Error?) -> Void))
    {
        // TODO:
        print("create publisher")
        connection.createMediaUpstream(mediaChannelId,
                                       accessToken: accessToken,
                                       mediaOption: mediaOption,
                                       streamId: "main")
        {
            (mediaStream, mediaCapturer, error) in
            if let error = error {
                handler(nil, error)
                return
            }
            
            self.mediaPublisher = MediaPublisher(
                mediaChannel: self,
                mediaChannelId: mediaStream!,
                mediaOption: mediaOption,
                mediaCapturer: mediaCapturer!)
            handler(self.mediaPublisher, nil)
        }
    }
    
    // TODO: reimpl
    public func createMediaSubscriber(_ mediaOption: MediaOption = MediaOption(),
                                      accessToken: String? = nil,
                                      handler: @escaping ((MediaSubscriber?, Error?) -> Void)) {
        // TODO:
        print("create subscriber")
        connection.createMediaDownstream(mediaChannelId, accessToken: accessToken,
                                         mediaOption: mediaOption)
        {
            (mediaStream, error) in
            if let error = error {
                handler(nil, error)
                return
            }
            self.mediaSubscriber = MediaSubscriber(
                connection: self.connection,
                mediaStream: mediaStream!,
                mediaOption: mediaOption)
            handler(self.mediaSubscriber, nil)
        }
    }
    
}
