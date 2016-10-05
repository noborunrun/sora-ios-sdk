import Foundation
import WebRTC
import Unbox

public struct Message {
    
    public var data: [String: Any]
    
    public init(data: [String: Any] = [:]) {
        self.data = data
    }
    
    public static func fromJSONData(_ data: Any) -> Message? {
        let base: Data!
        if data is Data {
            base = data as? Data
        } else if let data = data as? String {
            if let data = data.data(using: String.Encoding.utf8) {
                base = data
            } else {
                return nil
            }
        } else {
            return nil
        }
        
        do {
            let j = try JSONSerialization.jsonObject(with: base, options: JSONSerialization.ReadingOptions(rawValue: 0))
            return fromJSONObject(j as Any)
        } catch _ {
            return nil
        }
    }
    
    public static func fromJSONObject(_ j: Any) -> Message? {
        if let j = j as? [String: Any] {
            return Message(data: j)
        } else {
            return nil
        }
    }
    
    public func JSONString() -> String {
        let JSONData = try! JSONSerialization.data(withJSONObject: data, options: JSONSerialization.WritingOptions(rawValue: 0))
        return NSString(data: JSONData, encoding: String.Encoding.utf8.rawValue) as String!
    }
    
    public func type() -> String? {
        return data["type"] as? String
    }
    
    public func JSON() -> Argo.JSON {
        return Argo.JSON(data)
    }
    
}

extension Message: Messageable {
    
    public func message() -> Message {
        return self
    }
    
}

public protocol Messageable {

    func message() -> Message
    
}

protocol JSONEncodable {
    
    func encode() -> Any
    
}

enum Enable<T: JSONEncodable>: JSONEncodable {
    
    case `default`(T)
    case enable(T)
    case disable
    
    func encode() -> Any {
        switch self {
        case .default(let value):
            return value.encode()
        case .enable(let value):
            return value.encode()
        case .disable:
            return "false" as Any
        }
    }
    
}

enum SignalingRole {
    
    case upstream
    case downstream
    
    static func from(_ role: Role) -> SignalingRole {
        switch role {
        case .upstream:
            return upstream
        case .downstream:
            return downstream
        }
    }
}

extension SignalingRole: JSONEncodable {
    
    func encode() -> Any {
        switch self {
        case .upstream:
            return "upstream" as Any
        case .downstream:
            return "downstream" as Any
        }
    }
    
}

enum SignalingVideoCodec {
    
    case vp8
    case vp9
    case h264
    
}

extension SignalingVideoCodec: JSONEncodable {
    
    func encode() -> Any {
        switch self {
        case .vp8:
            return "VP8" as Any
        case .vp9:
            return "VP9" as Any
        case .h264:
            return "h264" as Any
        }
        
    }
    
}

enum SignalingAudioCodec {
    
    case opus
    case pcmu
    
}

extension SignalingAudioCodec: JSONEncodable {
    
    func encode() -> Any {
        switch self {
        case .opus:
            return "OPUS" as Any
        case .pcmu:
            return "PCMU" as Any
        }
        
    }
    
}

struct SignalingVideo {
    
    var bit_rate: Int?
    var codec_type: SignalingVideoCodec
    
}

extension SignalingVideo: JSONEncodable {
    
    func encode() -> Any {
        var data = ["codec_type": codec_type.encode()]
        if let value = bit_rate {
            data["bit_rate"] = value as Any?
        }
        return data as Any
    }
    
}

struct SignalingAudio {
    
    var codec_type: SignalingAudioCodec
    
}

extension SignalingAudio: JSONEncodable {
    
    func encode() -> Any {
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

}

extension SignalingConnect: Messageable {
    
    func message() -> Message {
        var data = ["type": "connect", "role": role.encode(), "channel_id": channel_id] as [String : Any]
        if let value = access_token {
            data["access_token"] = value
        }
        if let value = video {
            data["video"] = value.encode()
        }
        return Message(data: data as [String : Any])
    }
    
}

struct SignalingOffer {
    
    struct Configuration {
        
        struct IceServer {
            var urls: [String]
            var credential: String
            var username: String
        }
        
        var iceServers: [IceServer]
        var iceTransportPolicy: String
        
    }
    
    var type: String
    var client_id: String
    var sdp: String
    var config: Configuration?

    func sessionDescription() -> RTCSessionDescription {
        return RTCSessionDescription(type: RTCSdpType.offer, sdp: sdp)
    }
    
}

extension SignalingOffer: Decodable {
    
    static func decode(_ j: JSON) -> Decoded<SignalingOffer> {
        return curry(SignalingOffer.init)
            <^> j <| "type"
            <*> j <| "client_id"
            <*> j <| "sdp"
            <*> j <|? "config"
    }
    
}

extension SignalingOffer.Configuration: Decodable {
    
    static func decode(_ j: JSON) -> Decoded<SignalingOffer.Configuration> {
        return curry(SignalingOffer.Configuration.init)
            <^> j <|| "iceServers"
            <*> j <| "iceTransportPolicy"
    }
    
}

extension SignalingOffer.Configuration.IceServer: Decodable {
    
    static func decode(_ j: JSON) -> Decoded<SignalingOffer.Configuration.IceServer> {
        return curry(SignalingOffer.Configuration.IceServer.init)
            <^> j <|| "urls"
            <*> j <| "credential"
            <*> j <| "username"
    }
    
}

struct SignalingAnswer {
    
    var sdp: String
    
}

extension SignalingAnswer: Messageable {

    func message() -> Message {
        return Message(data: ["type": "answer" as Any, "sdp": sdp as Any])
    }
    
}

extension SignalingRole: Decodable {
    
    static func decode(_ j: JSON) -> Decoded<SignalingRole> {
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
    
    static func decode(_ j: JSON) -> Decoded<SignalingVideoCodec> {
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
    
    static func decode(_ j: JSON) -> Decoded<SignalingVideo> {
        return curry(SignalingVideo.init)
            <^> j <|? "bit_rate"
            <*> j <| "codec_type"
    }
    
}

extension SignalingAudioCodec: Decodable {
    
    static func decode(_ j: JSON) -> Decoded<SignalingAudioCodec> {
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
    
    static func decode(_ j: JSON) -> Decoded<SignalingAudio> {
        return curry(SignalingAudio.init)
            <^> j <| "codec_type"
    }
    
}

struct SignalingICECandidate {
    
    var candidate: String
    
}

extension SignalingICECandidate: Messageable {
    
    func message() -> Message {
        return Message(data: ["type": "candidate" as Any, "candidate": candidate as Any])
    }
    
}

struct SignalingPong {
}

extension SignalingPong: Messageable {
    
    func message() -> Message {
        return Message(data: ["type": "pong" as Any])
    }
    
}
