import Foundation
import WebRTC

public enum Role {
    case Upstream
    case Downstream
}

public enum VideoCodecType {
    case VP8
    case VP9
    case H264
}

public enum AudioCodecType {
    case Opus
}

public enum Message {

    case Connect(reuqest: ConnectRequest)
    case Offer(clientId: String, SDP: String, config: [String: String])
    
}

public struct ConnectRequest {

    public var role: Role
    public var channelId: String
    public var accessToken: String
    public var videoCodecType: VideoCodecType
    public var audioCodecType: AudioCodecType
    public var isVideoEnabled: Bool
    public var isAudioEnabled: Bool
    
}