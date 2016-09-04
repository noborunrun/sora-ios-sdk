import Foundation
import WebRTC
import Argo
import Curry
import Runes

protocol JSONEncodable {
    
    func encode() -> AnyObject
    
}

enum Enable<T: JSONEncodable>: JSONEncodable {
    
    case Default(T)
    case Enable(T)
    case Disable
    
    func encode() -> AnyObject {
        switch self {
        case .Default(let value):
            return value.encode()
        case .Enable(let value):
            return value.encode()
        case .Disable:
            return "false"
        }
    }
    
}

enum SignalingRole {
    
    case Upstream
    case Downstream
    
    static func from(role: Role) -> SignalingRole {
        switch role {
        case .Upstream:
            return Upstream
        case .Downstream:
            return Downstream
        }
    }
}

extension SignalingRole: JSONEncodable {
    
    func encode() -> AnyObject {
        switch self {
        case .Upstream:
            return "upstream"
        case .Downstream:
            return "downstream"
        }
    }
    
}

enum SignalingVideoCodec {
    
    case VP8
    case VP9
    case H264
    
}

extension SignalingVideoCodec: JSONEncodable {
    
    func encode() -> AnyObject {
        switch self {
        case .VP8:
            return "VP8"
        case .VP9:
            return "VP9"
        case .H264:
            return "h264"
        }
        
    }
    
}

enum SignalingAudioCodec {
    
    case OPUS
    case PCMU
    
}

extension SignalingAudioCodec: JSONEncodable {
    
    func encode() -> AnyObject {
        switch self {
        case .OPUS:
            return "OPUS"
        case .PCMU:
            return "PCMU"
        }
        
    }
    
}

struct SignalingVideo {
    
    var bit_rate: Int?
    var codec_type: SignalingVideoCodec
    
}

extension SignalingVideo: JSONEncodable {
    
    func encode() -> AnyObject {
        var data = ["codec_type": codec_type.encode()]
        if let value = bit_rate {
            data["bit_rate"] = value
        }
        return data
    }
    
}

struct SignalingAudio {
    
    var codec_type: SignalingAudioCodec
    
}

extension SignalingAudio: JSONEncodable {
    
    func encode() -> AnyObject {
        return ["codec_type": codec_type.encode()]
    }
    
}

struct SignalingConnect {
    
    var role: SignalingRole
    var channel_id: String
    var access_token: String?
    var video: SignalingVideo?
    var audio: SignalingAudio?
    var answerConstraints: RTCMediaConstraints =
        RTCMediaConstraints(mandatoryConstraints: [:],
                            optionalConstraints: [:])
    
    init(role: SignalingRole, channel_id: String, access_token: String? = nil) {
        self.role = role
        self.channel_id = channel_id
        self.access_token = access_token
    }
    
    func data() -> Data {
        var data = ["role": role.encode(), "channel_id": channel_id]
        if let tok = access_token {
            data["access_token"] = tok
        }
        if let video = video {
            data["video"] = video.encode()
        }
        if let audio = audio {
            data["audio"] = audio.encode()
        }
        return data
    }
    
}

extension SignalingConnect: JSONEncodable {
    
    func encode() -> AnyObject {
        var data = ["type": "connect", "role": role.encode(), "channel_id": channel_id]
        if let value = access_token {
            data["access_token"] = value
        }
        if let value = video {
            data["video"] = value.encode()
        }
        return data
    }
    
}

struct SignalingOffer {
    
    var type: String
    var client_id: String
    var sdp: String
    //var Enable: [String: String]?
    
    func sessionDescription() -> RTCSessionDescription {
        return RTCSessionDescription(type: RTCSdpType.Offer, sdp: sdp)
    }
    
}

extension SignalingOffer: Decodable {
    
    static func decode(j: JSON) -> Decoded<SignalingOffer> {
        return curry(SignalingOffer.init)
            <^> j <| "type"
            <*> j <| "client_id"
            <*> j <| "sdp"
    }
    
}

struct SignalingAnswer {
    
    var sdp: String
    
}

extension SignalingAnswer: JSONEncodable {
    
    func encode() -> AnyObject {
        return ["type": "answer", "sdp": sdp]
    }
    
}

extension SignalingRole: Decodable {
    
    static func decode(j: JSON) -> Decoded<SignalingRole> {
        switch j {
        case let .String(dest):
            switch dest {
            case "upstream":
                return pure(.Upstream)
            case "downstream":
                return pure(.Downstream)
            default:
                return .typeMismatch("invalid destination", actual: dest)
            }
        default:
            return .typeMismatch("String", actual: j)
        }
    }
    
}

extension SignalingVideoCodec: Decodable {
    
    static func decode(j: JSON) -> Decoded<SignalingVideoCodec> {
        switch j {
        case let .String(name):
            switch name {
            case "VP8":
                return pure(.VP8)
            case "VP9":
                return pure(.VP9)
            case "H264":
                return pure(.H264)
            default:
                return .typeMismatch("invalid video codec type", actual: name)
            }
        default:
            return .typeMismatch("String", actual: j)
        }
    }
    
}

extension SignalingVideo: Decodable {
    
    static func decode(j: JSON) -> Decoded<SignalingVideo> {
        return curry(SignalingVideo.init)
            <^> j <|? "bit_rate"
            <*> j <| "codec_type"
    }
    
}

extension SignalingAudioCodec: Decodable {
    
    static func decode(j: JSON) -> Decoded<SignalingAudioCodec> {
        switch j {
        case let .String(name):
            switch name {
            case "OPUS":
                return pure(.OPUS)
            default:
                return .typeMismatch("invalid audio codec type", actual: name)
            }
        default:
            return .typeMismatch("String", actual: j)
        }
    }
    
}

extension SignalingAudio: Decodable {
    
    static func decode(j: JSON) -> Decoded<SignalingAudio> {
        return curry(SignalingAudio.init)
            <^> j <| "codec_type"
    }
    
}

struct SignalingPong {
    // no properties
}

extension SignalingPong: JSONEncodable {
    
    func encode() -> AnyObject {
        return ["type": "pong"]
    }
    
}