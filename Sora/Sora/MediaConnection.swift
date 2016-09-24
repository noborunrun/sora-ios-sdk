import Foundation
import WebRTC

public struct MediaOption {
    
    public var videoEnabled: Bool
    public var audioEnabled: Bool
    public var configuration: RTCConfiguration
    public var mediaConstraints: RTCMediaConstraints
    public var answerMediaConstraints: RTCMediaConstraints
    public var videoCaptureSourceConstraints: RTCMediaConstraints
    
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
                answerMediaConstraints: RTCMediaConstraints? = nil,
                videoCaptureSourceConstraints: RTCMediaConstraints? = nil) {
        self.videoEnabled = videoEnabled
        self.audioEnabled = audioEnabled
        self.configuration = configuration ?? MediaOption.defaultConfiguration
        self.mediaConstraints = mediaConstraints ?? MediaOption.defaultMediaConstraints
        self.answerMediaConstraints = answerMediaConstraints ?? MediaOption.defaultMediaConstraints
        self.videoCaptureSourceConstraints = videoCaptureSourceConstraints ?? MediaOption.defaultMediaConstraints
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
        print("add video renderer", videoRenderer)
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

public enum VideoPreset {
    case VGA
    // TODO: etc.
}

public class MediaPublisher: MediaConnection {
    
    public var videoPreset: VideoPreset =  VideoPreset.VGA

    public var videoCaptureTrack: RTCVideoTrack
    public var videoCaptureSource: RTCAVFoundationVideoSource

    public var canUseBackCamera: Bool {
        get { return videoCaptureSource.canUseBackCamera }
    }
    
    public var captureSession: AVCaptureSession {
        get { return videoCaptureSource.captureSession }
    }
    
    override init(connection: Connection, mediaStream: MediaStream,
                  mediaOption: MediaOption) {
        self.videoCaptureSource = connection.createVideoCaptureSource(mediaOption.videoCaptureSourceConstraints)
        self.videoCaptureTrack = connection.createVideoCaptureTrack(
            self.videoCaptureSource, trackId: "main")
        videoCaptureSource.useBackCamera = false
        for stream in mediaStream.nativeMediaStreams {
            stream.addVideoTrack(videoCaptureTrack)
        }
        super.init(connection: connection, mediaStream: mediaStream,
                   mediaOption: mediaOption)
    }
    
    public func switchCamera() {
        videoCaptureSource.useBackCamera = true
    }
    
}

public class MediaSubscriber: MediaConnection {
    
}
