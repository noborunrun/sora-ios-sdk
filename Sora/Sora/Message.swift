import Foundation
import WebRTC
import Unbox

public class Message {
    
    public enum `Type`: String {
        case connect = "connect"
        case offer = "offer"
        case answer = "answer"
        case candidate = "candidate"
        case ping = "ping"
        case pong = "pong"
        case stats = "stats"
        case notify = "notify"
    }
    
    public var type: Type?
    public var data: [String: Any]
    
    public init(type: Type, data: [String: Any] = [:]) {
        self.type = type
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
            if let type = j["type"] as? String {
                if let type = Type(rawValue: type) {
                    return Message(type: type, data: j)
                } else {
                    print("invalid type:", type)
                    return nil
                }
            } else {
                print("'type' is not found")
                return nil
            }
        } else {
            return nil
        }
    }
    
    public func JSON() -> [String: Any] {
        var json: [String: Any] = self.data
        json["type"] = type?.rawValue
        return json
    }
    
}

extension Message : Messageable {
    
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

enum SignalingRole: String, UnboxableEnum {
    
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

enum SignalingVideoCodec: String, UnboxableEnum {
    
    case vp8 = "VP8"
    case vp9 = "VP9"
    case h264 = "H264"
    
}

enum SignalingAudioCodec: String, UnboxableEnum {
    
    case opus = "OPUS"
    case pcmu = "PCMU"
    
}

struct SignalingVideo {
    
    var bit_rate: Int?
    var codec_type: SignalingVideoCodec
    
}

extension SignalingVideo: JSONEncodable {
    
    func encode() -> Any {
        var data = ["codec_type": codec_type.rawValue]
        if let value = bit_rate {
            data["bit_rate"] = value.description
        }
        return data as Any
    }
    
}

struct SignalingAudio {
    
    var codec_type: SignalingAudioCodec
    
}

extension SignalingAudio: JSONEncodable {
    
    func encode() -> Any {
        return ["codec_type": codec_type.rawValue]
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
        var data = ["role": role.encode(),
                    "channel_id": channel_id] as [String : Any]
        if let value = access_token {
            data["access_token"] = value
        }
        if let value = video {
            data["video"] = value.encode()
        }
        return Message(type: .connect, data: data as [String : Any])
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
    
    var client_id: String
    var sdp: String
    var config: Configuration?

    func sessionDescription() -> RTCSessionDescription {
        return RTCSessionDescription(type: RTCSdpType.offer, sdp: sdp)
    }
    
}

extension SignalingOffer: Unboxable {
    
    init(unboxer: Unboxer) throws {
        client_id = try unboxer.unbox(key: "client_id")
        sdp = try unboxer.unbox(key: "sdp")
        config = unboxer.unbox(key: "config")
    }
    
}

extension SignalingOffer.Configuration: Unboxable {
    
    init(unboxer: Unboxer) throws {
        iceServers = try unboxer.unbox(key: "iceServers")
        iceTransportPolicy = try unboxer.unbox(key: "iceTransportPolicy")
    }
    
}

extension SignalingOffer.Configuration.IceServer: Unboxable {

    init(unboxer: Unboxer) throws {
        urls = try unboxer.unbox(key: "urls")
        credential = try unboxer.unbox(key: "credential")
        username = try unboxer.unbox(key: "username")
    }
    
}

struct SignalingAnswer {
    
    var sdp: String
    
}

extension SignalingAnswer: Messageable {

    func message() -> Message {
        return Message(type: .answer, data: ["sdp": sdp as Any])
    }
    
}

extension SignalingVideo: Unboxable {
    
    init(unboxer: Unboxer) throws {
        bit_rate = unboxer.unbox(key: "bit_rate")
        codec_type = try unboxer.unbox(key: "codec_type")
    }
    
}

extension SignalingAudio: Unboxable {
    
    init(unboxer: Unboxer) throws {
        codec_type = try unboxer.unbox(key: "codec_type")
    }
    
}

struct SignalingICECandidate {
    
    var candidate: String
    
}

extension SignalingICECandidate: Messageable {
    
    func message() -> Message {
        return Message(type: .candidate,
                       data: ["candidate": candidate as Any])
    }
    
}

struct SignalingPong {
}

extension SignalingPong: Messageable {
    
    func message() -> Message {
        return Message(type: .pong)
    }
    
}

public struct SignalingStats {
    
    public var numberOfUpstreamConnections: Int?
    public var numberOfDownstreamConnections: Int?
    
    var description: String {
        get {
            return String(format: "upstreams = %d, downstreams = %d",
                          numberOfUpstreamConnections ?? 0,
                          numberOfDownstreamConnections ?? 0)
        }
    }
}

extension SignalingStats: Unboxable {
    
    public init(unboxer: Unboxer) throws {
        numberOfUpstreamConnections = unboxer.unbox(key: "upstream_connections")
        numberOfDownstreamConnections = unboxer.unbox(key: "downstream_connections")
    }
    
}

public struct SignalingNotify {
    
    var notifyMessage: String
    
}

extension SignalingNotify: Unboxable {
    
    public init(unboxer: Unboxer) throws {
        notifyMessage = try unboxer.unbox(key: "message")
    }
    
}
