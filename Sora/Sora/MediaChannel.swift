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
    
    var publisherOption: MediaOption
    var subscriberOption: MediaOption
    
    init(connection: Connection, channelId: String,
         publisherOption: MediaOption, subscriberOption: MediaOption) {
        self.connection = connection
        self.channelId = channelId
        creationTime = NSDate()
        self.publisherOption = publisherOption
        self.subscriberOption = subscriberOption
    }
    
    func connect(handler: ((MediaChannel?, Error?) -> ())) {
        
    }
    
    public func disconnect() {}

}

public struct MediaOption {
    
    public var videoEnabled: Bool
    public var audioEnabled: Bool
    public var configuration: RTCConfiguration
    public var mediaConstraints: RTCMediaConstraints
    public var answerMediaConstraints: RTCMediaConstraints

    public static var defaultConfiguration: RTCConfiguration = {
        () -> RTCConfiguration in
        let config = RTCConfiguration()
        config.iceServers = [
            RTCIceServer(URLStrings: ["stun:stun.l.google.com:19302"],
                username: nil, credential: nil)]
        return config
    }()
    
    public static var defaultMediaConstraints: RTCMediaConstraints =
        RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
    
    public init(videoEnabled: Bool = true, audioEnabled: Bool = true,
                configuration: RTCConfiguration? = nil,
                mediaConstraints: RTCMediaConstraints? = nil,
                answerMediaConstraints: RTCMediaConstraints? = nil) {
        self.videoEnabled = videoEnabled
        self.audioEnabled = audioEnabled
        self.configuration = configuration ?? MediaOption.defaultConfiguration
        self.mediaConstraints = mediaConstraints ?? MediaOption.defaultMediaConstraints
        self.answerMediaConstraints = answerMediaConstraints ?? MediaOption.defaultMediaConstraints
    }
    
}

public struct Publisher {
    
    public var mediaStream: MediaStream
    public var mediaOption: MediaOption
    public var videoRenderer: VideoRenderer?
    
    public func switchCamera() {
        // TODO:
    }
    
}

public struct Subscriber {
    
    public var mediaStream: MediaStream
    public var mediaOption: MediaOption
    public var videoRenderer: VideoRenderer?
    
}
