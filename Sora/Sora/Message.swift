import Foundation
import WebRTC
import Argo
import Curry
import Runes

public enum Config<T: JSONEncodable> {
    
    case Default
    case Enable(T)
    case Disable
    
    func JSONString() -> String! {
        switch self {
        case .Default:
            return nil
        case .Enable(let value):
            return value.JSONString()
        case .Disable:
            return "false"
        }
    }
    
}

public enum Signaling {
    
    public enum Role {
        
        case Upstream
        case Downstream
        
        public func JSONString() -> String {
            switch self {
            case .Upstream:
                return "upstream"
            case .Downstream:
                return "downstream"
            }
        }
        
    }
    
    public enum VideoCodecType: JSONEncodable {
        
        case VP8
        case VP9
        case H264
        
        public func JSONString() -> String {
            switch self {
            case .VP8:
                return "VP8"
            case .VP9:
                return "VP9"
            case .H264:
                return "H264"
            }
        }
        
    }
    
    public struct Video: JSONEncodable {
        
        var codec_type: VideoCodecType
        
        public var codecType: VideoCodecType {
            
            get {
                return codec_type
            }
            
            set(newCodecType) {
                codec_type = newCodecType
            }
            
        }
        
        public func JSONString() -> String {
            let dict = NSMutableDictionary()
            dict["codec_type"] = codec_type.JSONString()
            return try! String(data: NSJSONSerialization.dataWithJSONObject(dict, options: NSJSONWritingOptions(rawValue: 0)),
                               encoding: NSUTF8StringEncoding)!
        }
        
    }
    
    public enum AudioCodecType: JSONEncodable {
        
        case Opus
        
        public func JSONString() -> String {
            switch self {
            case .Opus:
                return "OPUS"
            }
        }
        
    }
    
    public struct Audio: JSONEncodable {
        
        public var codec_type: AudioCodecType
        
        public func JSONString() -> String {
            let dict = NSMutableDictionary()
            dict["codec_type"] = codec_type.JSONString()
            return try! String(data: NSJSONSerialization.dataWithJSONObject(dict, options: NSJSONWritingOptions(rawValue: 0)),
                               encoding: NSUTF8StringEncoding)!
        }
        
    }
    
    public struct Connect {
        
        public var role: Role
        public var channelId: String
        public var accessToken: String?
        public var video: Config<Video> = Config.Default
        public var audio: Config<Audio> = Config.Default
        public var answerConstraints: RTCMediaConstraints =
            RTCMediaConstraints(mandatoryConstraints: [:],
                                optionalConstraints: [:])
        
        init(role: Role, channelId: String, accessToken: String?) {
            self.role = role
            self.channelId = channelId
            self.accessToken = accessToken
        }
        
        public func JSONString() -> String {
            let dict = NSMutableDictionary()
            dict["type"] = "connect"
            dict["role"] = role.JSONString()
            dict["channel_id"] = channelId
            if let value = accessToken {
                dict["access_token"] = value
            }
            if let value = video.JSONString() {
                dict["video"] = value
            }
            return CreateJSONString(dict)
        }
        
    }
    
    public struct Offer {
        
        public var type: String
        public var client_id: String
        public var sdp: String
        //public var config: [String: String]?
        
        public func sessionDescription() -> RTCSessionDescription {
            return RTCSessionDescription(type: RTCSdpType.Offer, sdp: sdp)
        }
        
    }
    
    public struct Answer: JSONEncodable {
        
        public var SDP: RTCSessionDescription
        
        public func JSONString() -> String {
            let dict = NSMutableDictionary()
            dict["type"] = "answer"
            dict["sdp"] = SDP.sdp
            return CreateJSONString(dict)
        }
        
    }
    
}

extension Signaling.Role: Decodable {
    
    public static func decode(j: JSON) -> Decoded<Signaling.Role> {
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

extension Signaling.VideoCodecType: Decodable {
    
    public static func decode(j: JSON) -> Decoded<Signaling.VideoCodecType> {
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

extension Signaling.Video: Decodable {
    
    public static func decode(j: JSON) -> Decoded<Signaling.Video> {
        return curry(Signaling.Video.init)
            <^> j <| "codec_type"
    }
    
}

extension Signaling.AudioCodecType: Decodable {
    
    public static func decode(j: JSON) -> Decoded<Signaling.AudioCodecType> {
        switch j {
        case let .String(name):
            switch name {
            case "OPUS":
                return pure(.Opus)
            default:
                return .typeMismatch("invalid audio codec type", actual: name)
            }
        default:
            return .typeMismatch("String", actual: j)
        }
    }
    
}

extension Signaling.Audio: Decodable {
    
    public static func decode(j: JSON) -> Decoded<Signaling.Audio> {
        return curry(Signaling.Audio.init)
            <^> j <| "codec_type"
    }
    
}

extension Signaling.Offer: Decodable {
    
    public static func decode(j: JSON) -> Decoded<Signaling.Offer> {
        return curry(Signaling.Offer.init)
            <^> j <| "type"
            <*> j <| "client_id"
            <*> j <| "sdp"
            //<*> j <|? "config"
    }
    
}