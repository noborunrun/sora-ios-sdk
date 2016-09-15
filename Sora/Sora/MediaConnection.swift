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

class VideoRendererSupport: NSObject, RTCVideoRenderer {
    
    var videoRenderer: VideoRenderer
    
    init(videoRenderer: VideoRenderer) {
        self.videoRenderer = videoRenderer
    }
    
    func setSize(size: CGSize) {
        videoRenderer.onChangedSize(size)
    }
    
    func renderFrame(frame: RTCVideoFrame?) {
        if let frame = frame {
            let frame = VideoFrame(nativeVideoFrame: frame)
            videoRenderer.renderVideoFrame(frame)
        }
    }
 
}

public class MediaConnection {
    
    public var connection: Connection
    public var mediaStream: MediaStream
    public var mediaOption: MediaOption
    
    var videoRenderers: [String: (VideoRenderer, VideoRendererSupport)] = [:]
    
    init(connection: Connection, mediaStream: MediaStream, mediaOption: MediaOption) {
        self.connection = connection
        self.mediaStream = mediaStream
        self.mediaOption = mediaOption
    }
 
    public func getVideoRenderer(name: String) -> VideoRenderer? {
        if let (videoRenderer, _) = videoRenderers[name] {
            return videoRenderer
        } else {
            return nil
        }
    }
    
    public func setVideoRenderer(name: String, videoRenderer: VideoRenderer) {
        videoRenderers[name] = (videoRenderer, VideoRendererSupport(videoRenderer: videoRenderer))
    }
    
    public func removeVideoRenderer(name: String) {
        videoRenderers.removeValueForKey(name)
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