import Foundation
import WebRTC

public enum Signaling {
    
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
    
    public struct Connect {
        
        public var role: Role
        public var channelId: String
        public var accessToken: String?
        /*
        public var videoCodecType: VideoCodecType
        public var audioCodecType: AudioCodecType
        public var isVideoEnabled: Bool
        public var isAudioEnabled: Bool
 */
        
    }
    
    public struct Offer {
        
        public var clientId: String
        public var SDP: String
        public var config: [String: String]
        
    }
    
    public struct Answer {
        
    }
    
}

    
}

    
}
