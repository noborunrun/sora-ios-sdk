import Foundation
import WebRTC

public enum StatisticsReport {
    
    case session(SessionReport)
    case track(TrackReport)
    case ssrcVideo(SSRCVideoReport)
    case ssrcAudio(SSRCAudioReport)
    
    public enum Level: Int {
        
        case debug
        case standard
        
        var nativeOutputLevel: RTCStatsOutputLevel {
            get {
                switch self {
                case .debug:
                    return RTCStatsOutputLevel.debug
                case .standard:
                    return RTCStatsOutputLevel.standard
                }
            }
        }
    }
    
    public class Report {
        
        public var nativeReport: RTCStatsReport
        public var reportId: String
        public var timestamp: Date
        
        init(report: RTCStatsReport) {
            nativeReport = report
            reportId = report.reportId
            timestamp = Date(timeIntervalSince1970: report.timestamp)
        }
        
    }
    
    public class SessionReport : Report {
        
        public var initiator: Bool?
        
        override init(report: RTCStatsReport) {
            super.init(report: report)
            initiator = report.boolValue(key: "googInitiator")
        }
        
    }
    
    public class TrackReport : Report {
        
        public var trackId: String?
        
        override init(report: RTCStatsReport) {
            super.init(report: report)
            trackId = report.stringValue(key: "googTrackId")
        }
        
    }
    
    public class SSRCVideoReport : Report {
        
        public var bytesSent: Int?
        public var codecImplementationName: String?
        public var adaptationChanges: Int?
        public var avgEncodeMs: Int?
        public var bandwidthLimitedResolution: Bool?
        public var codecName: String?
        public var cpuLimitedResolution: Bool?
        public var encodeUsagePercent: Int?
        public var firsReceived: Int?
        public var frameHeightInput: Int?
        public var frameHeightSent: Int?
        public var frameRateInput: Int?
        public var frameRateSent: Int?
        public var frameWidthInput: Int?
        public var frameWidthSent: Int?
        public var nacksReceived: Int?
        public var plisReceived: Int?
        public var rtt: Int?
        public var viewLimitedResolution: Bool?
        public var packetsLost: Int?
        public var packetsSent: Int?
        public var ssrc: Int?
        public var transportId: String?
        public var trackId: String?
        
        override init(report: RTCStatsReport) {
            super.init(report: report)
            bytesSent = report.intValue(key: "bytesSent")
            codecImplementationName = report.stringValue(key:
                "codecImplementationName")
            adaptationChanges = report.intValue(key: "googAdaptationChanges")
            avgEncodeMs = report.intValue(key: "googAvgEncodeMs")
            bandwidthLimitedResolution = report.boolValue(key:
                "googBandwidthLimitedResolution")
            codecName = report.stringValue(key: "googCodecName")
            cpuLimitedResolution = report.boolValue(key:
                "googCpuLimitedResolution")
            encodeUsagePercent = report.intValue(key: "googEncodeUsagePercent")
            firsReceived = report.intValue(key: "googFirsReceived")
            frameHeightInput = report.intValue(key: "googFrameHeightInput")
            frameHeightSent = report.intValue(key: "googFrameHeightSent")
            frameRateInput = report.intValue(key: "googFrameRateInput")
            frameRateSent = report.intValue(key: "googFrameRateSent")
            frameWidthInput = report.intValue(key: "googFrameWidthInput")
            frameWidthSent = report.intValue(key: "googFrameWidthSent")
            nacksReceived = report.intValue(key: "googNacksReceived")
            plisReceived = report.intValue(key: "googPlisReceived")
            rtt = report.intValue(key: "googRtt")
            trackId = report.stringValue(key: "googTrackId")
            transportId = report.stringValue(key: "transportId")
            viewLimitedResolution = report.boolValue(key: "googViewLimitedResolution")
            packetsLost = report.intValue(key: "packetsLost")
            packetsSent = report.intValue(key: "packetsSent")
            ssrc = report.intValue(key: "ssrc")
        }
        
    }
    
    public class SSRCAudioReport : Report {
        
        public var trackId: String?
        public var transportId: String?
        public var typingNoiseState: Bool?
        public var codecName: String?
        public var packetsSent: Int?
        public var bytesSent: Int?
        public var echoCancellationReturnLoss: Int?
        public var echoCancellationReturnLossEnhancement: Int?
        public var audioInputLevel: Int?
        public var ssrc: String?
        
        override init(report: RTCStatsReport) {
            super.init(report: report)
            trackId = report.stringValue(key: "googTrackId")
            typingNoiseState = report.boolValue(key: "googTypingNoiseState")
            codecName = report.stringValue(key: "googCodecName")
            packetsSent = report.intValue(key: "packetsSent")
            bytesSent = report.intValue(key: "bytesSent")
            echoCancellationReturnLoss =
                report.intValue(key: "googEchoCancellationReturnLoss")
            echoCancellationReturnLossEnhancement =
                report.intValue(key: "googEchoCancellationReturnLossEnhancement")
            audioInputLevel = report.intValue(key: "audioInputLevel")
            ssrc = report.stringValue(key: "ssrc")
        }
        
    }
    
    static func parse(report: RTCStatsReport) -> StatisticsReport? {
        switch report.type {
        case "googLibjingleSession":
            return .session(SessionReport(report: report))
            
        case "googTrack":
            return .track(TrackReport(report: report))
            
        case "ssrc":
            switch report.values["mediaType"] {
            case "video"?:
                return .ssrcVideo(SSRCVideoReport(report: report))
            case "audio"?:
                return .ssrcAudio(SSRCAudioReport(report: report))
            default:
                return nil
            }
            
        default:
            return nil
        }
    }
    
}

extension RTCStatsReport {
    
    public func stringValue(key: String) -> String? {
        return values[key]
    }
    
    public func boolValue(key: String) -> Bool? {
        if let value = values[key] {
            switch value {
            case "true":
                return true
            case "false":
                return false
            default:
                return nil
            }
        } else {
            return nil
        }
    }
    
    public func intValue(key: String) -> Int? {
        if let value = values[key] {
            return Int(value)
        } else {
            return nil
        }
    }
    
    public func floatValue(key: String) -> Float? {
        if let value = values[key] {
            return Float(value)
        } else {
            return nil
        }
    }
    
}
