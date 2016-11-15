import Foundation
import WebRTC

public class MediaStream {
    
    public enum State {
        case connecting
        case connected
        case disconnecting
        case disconnected
    }
    
    static var defaultStreamId: String = "mainStream"
    static var defaultVideoTrackId: String = "mainVideo"
    static var defaultAudioTrackId: String = "mainAudio"

    public weak var mediaConnection: MediaConnection!
    public var role: Role
    public var mediaChannelId: String
    public var accessToken: String?
    public var mediaStreamlId: String?
    public var mediaOption: MediaOption?
    public var creationTime: Date?
    public var clientId: String?
    public var peerConnection: RTCPeerConnection?
    public var peerConnectionFactory: RTCPeerConnectionFactory?
    public var state: State

    public weak var connection: Connection! {
        get { return mediaConnection.mediaChannel.connection }
    }
    
    public var isAvailable: Bool {
        get { return state == .connected }
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

    var context: MediaStreamContext?
    var videoRendererSupport: VideoRendererSupport?
    var nativeMediaStream: RTCMediaStream
    
    init(mediaConnection: MediaConnection,
         role: Role,
         mediaChannelId: String,
         accessToken: String? = nil,
         mediaStreamId: String? = nil,
         mediaOption: MediaOption? = MediaOption()) {
        self.mediaConnection = mediaConnection
        self.role = role
        self.mediaChannelId = mediaChannelId
        self.accessToken = accessToken
        self.mediaStreamlId = mediaStreamId
        self.mediaOption = mediaOption
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
    
    // MARK: シグナリング
    
    func connect(handler: @escaping ((ConnectionError?) -> Void)) {
        switch state {
        case .connected, .connecting, .disconnecting:
            handler(ConnectionError.connectionBusy)
        case .disconnected:
            state = .connecting
            // TODO
            creationTime = Date()
        }
    }
    
    func disconnect(handler: @escaping (ConnectionError?) -> Void) {
        switch state {
        case .disconnecting:
            handler(ConnectionError.connectionBusy)
        case .disconnected:
            handler(ConnectionError.connectionDisconnected)
        case .connecting, .connected:
            assert(peerConnection == nil, "peerConnection must not be nil")
            state = .disconnected
            connectionTimer?.invalidate()
            videoRendererSupport = nil

            // TODO: デリゲートを使って close の完了を知るべき
            peerConnection!.close()
            handler(nil)
            creationTime = nil
        }
    }
    
    public func send(_ message: Message) {
        context.send(message)
    }
    
    public func send(_ messageable: Messageable) {
        context.send(messageable.message())
    }
    
    // MARK: 統計情報
    
    public func statisticsReports(level: StatisticsReport.Level)
        -> ([StatisticsReport], [StatisticsReport])
    {
        if peerConnection == nil {
            return ([], [])
        }
        
        func getReports(track: RTCMediaStreamTrack) -> [StatisticsReport] {
            var reports: [StatisticsReport] = []
            peerConnection!.stats(for: track, statsOutputLevel: level.nativeOutputLevel) {
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

    var onUpdateHandler: ((Int) -> Void)?
    var connectionTimer: Timer?
    
    @available(iOS 10.0, *)
    public func onUpdate(timeInterval: TimeInterval, handler: @escaping ((Int) -> Void)) {
        onUpdateHandler = handler
        connectionTimer?.invalidate()
        connectionTimer = Timer(timeInterval: timeInterval, repeats: true) {
            timer in
            if self.state == .connected {
                let diff = Date(timeIntervalSinceNow: 0).timeIntervalSince(self.creationTime!)
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
            print("MediaStream: ice connection disconnected")
            mediaStream.disconnect()
        case .failed:
            print("MediaStream: ice connection failed")
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
