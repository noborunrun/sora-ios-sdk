import Foundation
import WebRTC

public class MediaStream {
    
    public enum State: String {
        case connecting
        case connected
        case disconnecting
        case disconnected
    }
    
    static var defaultStreamId: String = "mainStream"
    static var defaultVideoTrackId: String = "mainVideo"
    static var defaultAudioTrackId: String = "mainAudio"
    
    public weak var peerConnection: PeerConnection?
    public var nativeMediaStream: RTCMediaStream
    public var creationTime: Date?

    var eventLog: EventLog? {
        get { return peerConnection?.eventLog }
    }
    
    public var state: State = .disconnected {
        willSet {
            switch newValue {
            case .connected:
                creationTime = Date()
            default:
                creationTime = nil
            }
        }
    }
    
    public var isAvailable: Bool {
        get { return state == .connected }
    }
    
    public var mediaStreamId: String {
        get {
            return nativeMediaStream.streamId
        }
    }
    
    public var nativeVideoTrack: RTCVideoTrack? {
        get {
            if nativeMediaStream.videoTracks.isEmpty {
                return nil
            } else {
                return nativeMediaStream.videoTracks[0]
            }
        }
    }
    
    public var nativeAudioTrack: RTCAudioTrack? {
        get {
            if nativeMediaStream.audioTracks.isEmpty {
                return nil
            } else {
                return nativeMediaStream.audioTracks[0]
            }
        }
    }
    
    public var videoRenderer: VideoRenderer? {
        didSet {
            if let videoTrack = nativeVideoTrack {
                if let renderer = videoRenderer {
                    eventLog?.markFormat(type: .VideoRenderer,
                                         format: "set video renderer")
                    videoRendererAdapter =
                        VideoRendererAdapter(videoRenderer: renderer)
                    videoTrack.add(videoRendererAdapter!)
                } else if let adapter = videoRendererAdapter {
                    eventLog?.markFormat(type: .VideoRenderer,
                                         format: "clear video renderer")
                    videoTrack.remove(adapter)
                }
            }
        }
    }
    
    var videoRendererAdapter: VideoRendererAdapter?
    
    init(peerConnection: PeerConnection, nativeMediaStream: RTCMediaStream) {
        self.peerConnection = peerConnection
        self.nativeMediaStream = nativeMediaStream
    }
    
    // MARK: 統計情報
    
    public func statisticsReports(level: StatisticsReport.Level)
        -> ([StatisticsReport], [StatisticsReport])
    {
        if !isAvailable {
            return ([], [])
        }
        
        func getReports(track: RTCMediaStreamTrack) -> [StatisticsReport] {
            var reports: [StatisticsReport] = []
            peerConnection!.nativePeerConnection!
                .stats(for: track, statsOutputLevel: level.nativeOutputLevel) {
                    nativeReports in
                    for nativeReport in nativeReports {
                        if let report = StatisticsReport.parse(report: nativeReport) {
                            reports.append(report)
                        }
                    }
            }
            return reports
        }
        
        var videoReports: [StatisticsReport] = []
        if let track = nativeVideoTrack {
            videoReports = getReports(track: track)
        }
        
        var audioReports: [StatisticsReport] = []
        if let track = nativeAudioTrack {
            audioReports = getReports(track: track)
        }
        
        return (videoReports, audioReports)
    }
    
}
