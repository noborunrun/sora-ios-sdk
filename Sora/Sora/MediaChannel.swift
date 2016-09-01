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
    public var creationTime: NSDate
    public var publisher: Publisher?
    public var subscriber: Subscriber?
    
    public func disconnect() {}

}

public struct MediaOption {
    
    public var videoEnabled: Bool
    public var audioEnabled: Bool
    
    public init(videoEnabled: Bool = true, audioEnabled: Bool = true) {
        self.videoEnabled = videoEnabled
        self.audioEnabled = audioEnabled
    }
    
}

public struct MediaStream {
    
    public var peerConnection: RTCPeerConnection?
    public var nativeMediaStream: RTCMediaStream?
    public var option: MediaOption
    public var creationTime: NSDate
    
    init(option: MediaOption = MediaOption()) {
        self.option = option
        self.creationTime = NSDate()
    }
    
    public func close() {}
}

public struct Publisher {
    
    public var mediaStream: MediaStream
    public var videoRenderer: VideoRenderer?
    
    public func switchCamera() {
        // TODO:
    }
    
}

public struct Subscriber {
    
    public var mediaStream: MediaStream
    public var videoRenderer: VideoRenderer?
    
}
