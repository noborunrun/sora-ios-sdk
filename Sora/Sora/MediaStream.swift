import Foundation
import WebRTC

public class MediaStream {
    
    enum State {
        case connected
        case disconnected
    }
    
    static var defaultStreamId: String = "mainStream"
    static var defaultVideoTrackId: String = "mainVideo"
    static var defaultAudioTrackId: String = "mainAudio"

    public weak var connection: Connection!
    public var peerConnection: RTCPeerConnection
    public var mediaOption: MediaOption
    public var creationTime: Date
    public var channelId: String
    public var clientId: String?
    public var role: Role
    
    public var isDisconnected: Bool {
        get { return state == .disconnected }
    }
    
    public var nativeVideoTrack: RTCVideoTrack? {
        get {
            if nativeMediaStream.videoTracks.isEmpty {
                return nil
            }
            return nativeMediaStream.videoTracks[0]
        }
    }
    
    public var nativeAudioTrack: RTCAudioTrack? {
        get {
            if nativeMediaStream.audioTracks.isEmpty {
                return nil
            }
            return nativeMediaStream.audioTracks[0]
        }
    }

    var context: MediaStreamContext!
    var state: State
    var videoRendererSupport: VideoRendererSupport?
    var nativeMediaStream: RTCMediaStream
    
    init(connection: Connection,
                     peerConnection: RTCPeerConnection,
                     role: Role,
                     channelId: String,
                     mediaOption: MediaOption = MediaOption(),
                     nativeMediaStream: RTCMediaStream) {
        self.connection = connection
        self.peerConnection = peerConnection
        self.role = role
        self.channelId = channelId
        self.mediaOption = mediaOption
        self.nativeMediaStream = nativeMediaStream
        state = .connected
        creationTime = Date()
        context = MediaStreamContext(mediaStream: self)
        peerConnection.delegate = context
    }
    
    func disconnect() {
        connectionTimer?.invalidate()
        peerConnection.close()
        videoRendererSupport = nil
        state = .disconnected
    }
    
    func setVideoRenderer(_ videoRenderer: VideoRenderer?) {
        if let videoTrack = nativeVideoTrack {
            if let renderer = videoRenderer {
                videoRendererSupport = VideoRendererSupport(videoRenderer: renderer)
                videoTrack.add(videoRendererSupport!)
            } else if let support = videoRendererSupport {
                videoTrack.remove(support)
            }
        }
    }
    
    public func statisticsReports(level: StatisticsReport.Level)
        -> ([StatisticsReport], [StatisticsReport])
    {
        func getReports(track: RTCMediaStreamTrack) -> [StatisticsReport] {
            var reports: [StatisticsReport] = []
            peerConnection.stats(for: track, statsOutputLevel: level.nativeOutputLevel) {
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
    
    // MARK: イベントハンドラ
    
    var onConnectedHandler: ((MediaStream?, Error?) -> Void)?
    var onDisconnectedHandler: ((MediaStream?, Error?) -> Void)?
    
    public func onDisconnected(_ handler: @escaping ((MediaStream?, Error?) -> Void)) {
        onDisconnectedHandler = handler
    }
    
    var onAvailableHandler: ((Int) -> Void)?
    var connectionTimer: Timer?
    
    @available(iOS 10.0, *)
    public func onAvailable(handler: @escaping ((Int) -> Void)) {
        onAvailableHandler = handler
        connectionTimer?.invalidate()
        connectionTimer = Timer(timeInterval: 1, repeats: true) {
            timer in
            if self.state == .connected {
                let diff = Date(timeIntervalSinceNow: 0).timeIntervalSince(self.creationTime)
                handler(Int(diff))
            }
        }
        RunLoop.main.add(connectionTimer!, forMode: .commonModes)
        RunLoop.main.run()
    }
    
}

class MediaStreamContext: NSObject, RTCPeerConnectionDelegate {
    
    weak var mediaStream: MediaStream!

    var eventLog: EventLog { get { return mediaStream.connection.eventLog } }
    
    init(mediaStream: MediaStream) {
        self.mediaStream = mediaStream
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didChange stateChanged: RTCSignalingState) {
        print("peerConnection:didChangeSignalingState:", stateChanged.rawValue)
        eventLog.markFormat(type: .PeerConnection, format: "signaling state changed: %@",
                            arguments: stateChanged.description)
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didAdd stream: RTCMediaStream) {
        print("peerConnection:didAddStream:")
        eventLog.markFormat(type: .PeerConnection, format: "added stream")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didRemove stream: RTCMediaStream) {
        print("peerConnection:didRemoveStream:")
        eventLog.markFormat(type: .PeerConnection, format: "removed stream")
    }
    
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        print("peerConnectionShouldNegotiate:")
        eventLog.markFormat(type: .PeerConnection, format: "should negatiate")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didChange newState: RTCIceConnectionState) {
        print("peerConnection:didChangeIceConnectionState:", newState.rawValue)
        eventLog.markFormat(type: .PeerConnection,
                            format: "ICE connection state changed: %@",
                            arguments: newState.description)
        
        switch newState {
        case .disconnected:
            print("ice connection disconnected")
            mediaStream.disconnect()
        default:
            break
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didChange newState: RTCIceGatheringState) {
        print("peerConnection:didChangeIceGatheringState:")
        eventLog.markFormat(type: .PeerConnection,
                            format: "ICE gathering state changed: %@",
                            arguments: newState.description)
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didGenerate candidate: RTCIceCandidate) {
        print("peerConnection:didGenerateIceCandidate:")
        eventLog.markFormat(type: .PeerConnection, format: "candidate generated: %@",
                            arguments: candidate.sdp)
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didRemove candidates: [RTCIceCandidate]) {
        print("peerConnection:didRemoveIceCandidates:")
        eventLog.markFormat(type: .PeerConnection,
                            format: "candidates %d removed",
                            arguments: candidates.count)
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didOpen dataChannel: RTCDataChannel) {
        print("peerConnection:didOpenDataChannel:")
        eventLog.markFormat(type: .PeerConnection, format: "data channel opened")
    }
    
}
