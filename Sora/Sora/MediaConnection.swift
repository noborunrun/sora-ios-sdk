import Foundation
import WebRTC

public class MediaOption {
    
    public var videoEnabled: Bool
    public var audioEnabled: Bool
    public var configuration: RTCConfiguration
    public var mediaConstraints: RTCMediaConstraints
    public var answerMediaConstraints: RTCMediaConstraints
    
    public static var defaultConfiguration: RTCConfiguration = {
        () -> RTCConfiguration in
        let config = RTCConfiguration()
        config.iceServers = [
            RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"],
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
    
    public var videoRenderer: VideoRenderer? {
        
        willSet {
            self.mediaStream.setVideoRenderer(newValue)
        }
        
    }
    
    init(connection: Connection, mediaStream: MediaStream, mediaOption: MediaOption) {
        self.connection = connection
        self.mediaStream = mediaStream
        self.mediaOption = mediaOption
    }
    
    public func disconnect() {
        mediaStream.disconnect()
    }
    
}

public enum VideoPreset {
    case vga
    // TODO: etc.
}

public class MediaCapturer {
    
    public var videoCaptureTrack: RTCVideoTrack
    public var videoCaptureSource: RTCAVFoundationVideoSource
    public var audioCaptureTrack: RTCAudioTrack
    
    static var defaultVideoCaptureTrackId: String = "mainVideoCaptureTrack"
    static var defaultAudioCaptureTrackId: String = "mainAudioCaptureTrack"

    init(factory: RTCPeerConnectionFactory,
         videoCaptureSourceMediaConstraints: RTCMediaConstraints) {
        videoCaptureSource = factory
            .avFoundationVideoSource(with: videoCaptureSourceMediaConstraints)
        videoCaptureTrack = factory
            .videoTrack(with: videoCaptureSource,
                                  trackId: MediaCapturer.defaultVideoCaptureTrackId)
        audioCaptureTrack = factory
            .audioTrack(withTrackId: MediaCapturer.defaultAudioCaptureTrackId)
    }
    
}

public enum CameraPosition {
    case front
    case back
}

public class MediaPublisher: MediaConnection {
    
    public var videoPreset: VideoPreset =  VideoPreset.vga
    public var mediaCapturer: MediaCapturer

    public var canUseBackCamera: Bool {
        get { return mediaCapturer.videoCaptureSource.canUseBackCamera }
    }
    
    public var captureSession: AVCaptureSession {
        get { return mediaCapturer.videoCaptureSource.captureSession }
    }
    
    init(connection: Connection, mediaStream: MediaStream,
         mediaOption: MediaOption, mediaCapturer: MediaCapturer) {
        self.mediaCapturer = mediaCapturer
        mediaCapturer.videoCaptureSource.useBackCamera = false
        super.init(connection: connection, mediaStream: mediaStream,
                   mediaOption: mediaOption)
    }
    
    public func switchCamera(_ position: CameraPosition? = nil) {
        switch position {
        case nil:
            mediaCapturer.videoCaptureSource.useBackCamera =
                !mediaCapturer.videoCaptureSource.useBackCamera
        case CameraPosition.front?:
            mediaCapturer.videoCaptureSource.useBackCamera = false
        case CameraPosition.back?:
            mediaCapturer.videoCaptureSource.useBackCamera = true
        }
    }
    
}

public class MediaSubscriber: MediaConnection {
    
}
