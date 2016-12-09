import Foundation
import WebRTC

public enum MediaStreamRole {
    
    case upstream
    case downstream
    
}

public enum VideoCodec {
    
    case unspecified
    case VP8
    case VP9
    case H264
    
}

public enum AudioCodec {
    
    case unspecified
    case Opus
    case PCMU
    
}

public enum Resolution {
    case FHD
    case HD
    case VGA
    case QVGA
    case HQVGA
    case QCIF
    case QQVGA
}

public class MediaOption {
    
    public var videoCodec: VideoCodec = .unspecified
    public var audioCodec: AudioCodec = .unspecified
    public var videoEnabled: Bool = true
    public var audioEnabled: Bool = true
    
    public static var maxBitRate = 5000
    
    public var bitRate: Int? {
        didSet {
            if let bitRate = bitRate {
                self.bitRate = max(0, min(bitRate, MediaOption.maxBitRate))
            }
        }
    }
    
    public var configuration: RTCConfiguration = defaultConfiguration
    public var signalingAnswerMediaConstraints: RTCMediaConstraints = defaultMediaConstraints
    public var videoCaptureSourceMediaConstraints: RTCMediaConstraints = defaultMediaConstraints
    public var peerConnectionMediaConstraints: RTCMediaConstraints = defaultMediaConstraints
    public var videoCaptureTrackId: String = defaultVideoCaptureTrackId
    public var audioCaptureTrackId: String = defaultAudioCaptureTrackId
    
    static var defaultConfiguration: RTCConfiguration = {
        () -> RTCConfiguration in
        let config = RTCConfiguration()
        config.iceServers = [
            RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"],
                         username: nil, credential: nil)]
        return config
    }()
    
    static var defaultMediaConstraints: RTCMediaConstraints =
        RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
    
    static var defaultVideoCaptureTrackId: String = "mainVideoCaptureTrack"
    static var defaultAudioCaptureTrackId: String = "mainAudioCaptureTrack"
    
}
