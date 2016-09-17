import Foundation
import WebRTC

public struct MediaStream {
    
    enum State {
        case Connected
        case Disconnected
    }
    
    public var peerConnection: RTCPeerConnection
    public var mediaOption: MediaOption
    public var creationTime: NSDate
    public var channelId: String
    public var clientId: String?
    public var role: Role
    
    var context: MediaStreamContext!
    var state: State
    var videoRendererSupports: [VideoRendererSupport] = []
    var nativeMediaStreams: [RTCMediaStream] = []
    
    static func new(peerConnection: RTCPeerConnection, role: Role, channelId: String,
                    mediaOption: MediaOption = MediaOption(),
                    nativeMediaStreams: [RTCMediaStream]) -> MediaStream {
        var mediaStream = MediaStream(peerConnection: peerConnection,
                                      role: role, channelId: channelId,
                                      mediaOption: mediaOption,
                                      nativeMediaStreams: nativeMediaStreams)
        mediaStream.context = MediaStreamContext(mediaStream: mediaStream)
        peerConnection.delegate = mediaStream.context
        return mediaStream
    }
    
    private init(peerConnection: RTCPeerConnection, role: Role, channelId: String,
         mediaOption: MediaOption = MediaOption(),
         nativeMediaStreams: [RTCMediaStream]) {
        self.peerConnection = peerConnection
        self.role = role
        self.channelId = channelId
        self.mediaOption = mediaOption
        self.nativeMediaStreams = nativeMediaStreams
        state = .Connected
        creationTime = NSDate()
    }
    
    mutating func disconnect() {
        peerConnection.close()
        state = .Disconnected
    }
    
    public func isDisconnected() -> Bool {
        return state == .Disconnected
    }
    
    mutating func addVideoRendererSupport(support: VideoRendererSupport) {
        videoRendererSupports.append(support)
        for stream in nativeMediaStreams {
            addVideoRenderer(support, stream: stream)
        }
    }
    
    func addVideoRenderer(support: VideoRendererSupport, stream: RTCMediaStream) {
        if let trackId = support.trackId {
            for track in stream.videoTracks {
                if track.trackId == trackId {
                    track.addRenderer(support)
                }
            }
        } else if stream.videoTracks.count > 0 {
            stream.videoTracks[0].addRenderer(support)
        }
    }
    
    mutating func removeVideoRendererSupport(support: VideoRendererSupport) {
        videoRendererSupports = videoRendererSupports.filter { e in return e == support }
        for stream in nativeMediaStreams {
            removeVideoRenderer(support, stream: stream)
        }
    }
    
    func removeVideoRenderer(support: VideoRendererSupport, stream: RTCMediaStream) {
        if let trackId = support.trackId {
            for track in stream.videoTracks {
                if track.trackId == trackId {
                    track.removeRenderer(support)
                }
            }
        } else if stream.videoTracks.count > 0 {
            stream.videoTracks[0].removeRenderer(support)
        }
    }
    
    // MARK: イベントハンドラ
    
    var onConnectedHandler: ((MediaStream?, Error?) -> ())?
    var onDisconnectedHandler: ((MediaStream?, Error?) -> ())?
    
    public mutating func onDisconnected(handler: ((MediaStream?, Error?) -> ())) {
        onDisconnectedHandler = handler
    }
    
}

class MediaStreamContext: NSObject, RTCPeerConnectionDelegate {
    
    var mediaStream: MediaStream

    init(mediaStream: MediaStream) {
        self.mediaStream = mediaStream
    }
    
    func peerConnection(peerConnection: RTCPeerConnection,
                        didChangeSignalingState stateChanged: RTCSignalingState) {
        print("peerConnection:didChangeSignalingState:", stateChanged.rawValue)
    }
    
    func peerConnection(peerConnection: RTCPeerConnection,
                        didAddStream stream: RTCMediaStream) {
        print("peerConnection:didAddStream:")
    }
    
    func peerConnection(peerConnection: RTCPeerConnection,
                        didRemoveStream stream: RTCMediaStream) {
        print("peerConnection:didRemoveStream:")
    }
    
    func peerConnectionShouldNegotiate(peerConnection: RTCPeerConnection) {
        print("peerConnectionShouldNegotiate:")
    }
    
    func peerConnection(peerConnection: RTCPeerConnection,
                        didChangeIceConnectionState newState: RTCIceConnectionState) {
        print("peerConnection:didChangeIceConnectionState:", newState.rawValue)
        switch newState {
        case .Disconnected:
            print("ice connection disconnected")
            mediaStream.disconnect()
        default:
            break
        }
    }
    
    func peerConnection(peerConnection: RTCPeerConnection,
                        didChangeIceGatheringState newState: RTCIceGatheringState) {
        print("peerConnection:didChangeIceGatheringState:")
    }
    
    func peerConnection(peerConnection: RTCPeerConnection,
                        didGenerateIceCandidate candidate: RTCIceCandidate) {
        print("peerConnection:didGenerateIceCandidate:")
    }
    
    func peerConnection(peerConnection: RTCPeerConnection,
                        didRemoveIceCandidates candidates: [RTCIceCandidate]) {
        print("peerConnection:didRemoveIceCandidates:")
    }
    
    func peerConnection(peerConnection: RTCPeerConnection,
                        didOpenDataChannel dataChannel: RTCDataChannel) {
        print("peerConnection:didOpenDataChannel:")
    }
    
}