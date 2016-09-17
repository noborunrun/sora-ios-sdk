import Foundation
import WebRTC

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

public class MediaConnection {
    
    public var connection: Connection
    public var mediaStream: MediaStream
    public var mediaOption: MediaOption
    
    public var videoRenderers: [VideoRenderer] = []
    var videoRendererSupports: [VideoRendererSupport] = []
    
    init(connection: Connection, mediaStream: MediaStream, mediaOption: MediaOption) {
        self.connection = connection
        self.mediaStream = mediaStream
        self.mediaOption = mediaOption
    }
 
    public func addVideoRenderer(videoRenderer: VideoRenderer,
                                 trackId: String? = nil) -> Int {
        videoRenderers.append(videoRenderer)
        let support = VideoRendererSupport(videoRenderer: videoRenderer, trackId: trackId)
        videoRendererSupports.append(support)
        mediaStream.addVideoRendererSupport(support)
        return videoRenderers.count - 1
    }
    
    public func removeVideoRenderer(index: Int) {
        videoRenderers.removeAtIndex(index)
        let support = videoRendererSupports.removeAtIndex(index)
        mediaStream.removeVideoRendererSupport(support)
    }
    
    public func disconnect() {
        mediaStream.disconnect()
    }
    
}

public class MediaPublisher: MediaConnection {
    
    public func switchCamera() {
        // TODO:
    }
    
}

public class MediaSubscriber: MediaConnection {
    
}