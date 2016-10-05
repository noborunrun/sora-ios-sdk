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

open class MediaConnection {
    
    open var connection: Connection
    open var mediaStream: MediaStream
    open var mediaOption: MediaOption
    
    open var videoRenderer: VideoRenderer? {
        
        willSet {
            self.mediaStream.setVideoRenderer(newValue)
        }
        
    }
    
    init(connection: Connection, mediaStream: MediaStream, mediaOption: MediaOption) {
        self.connection = connection
        self.mediaStream = mediaStream
        self.mediaOption = mediaOption
    }
    
    open func disconnect() {
        mediaStream.disconnect()
    }
    
}

public enum VideoPreset {
    case vga
    // TODO: etc.
}

public struct MediaCapturer {
    
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

open class MediaPublisher: MediaConnection {
    
    open var videoPreset: VideoPreset =  VideoPreset.vga
    open var mediaCapturer: MediaCapturer

    open var canUseBackCamera: Bool {
        get { return mediaCapturer.videoCaptureSource.canUseBackCamera }
    }
    
    open var captureSession: AVCaptureSession {
        get { return mediaCapturer.videoCaptureSource.captureSession }
    }
    
    init(connection: Connection, mediaStream: MediaStream,
         mediaOption: MediaOption, mediaCapturer: MediaCapturer) {
        self.mediaCapturer = mediaCapturer
        mediaCapturer.videoCaptureSource.useBackCamera = false
        super.init(connection: connection, mediaStream: mediaStream,
                   mediaOption: mediaOption)
    }
    
    open func switchCamera(_ position: CameraPosition? = nil) {
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

open class MediaSubscriber: MediaConnection {
    
}
