import Foundation
import WebRTC

public struct MediaStream {
    
    enum State {
        case connected
        case disconnected
    }
    
    static var defaultStreamId: String = "mainStream"
    static var defaultVideoTrackId: String = "mainVideo"
    static var defaultAudioTrackId: String = "mainAudio"

    public var peerConnection: RTCPeerConnection
    public var mediaOption: MediaOption
    public var creationTime: Date
    public var channelId: String
    public var clientId: String?
    public var role: Role
    
    var context: MediaStreamContext!
    var state: State
    var videoRendererSupport: VideoRendererSupport?
    var nativeMediaStream: RTCMediaStream
    
    static func new(_ peerConnection: RTCPeerConnection, role: Role, channelId: String,
                    mediaOption: MediaOption = MediaOption(),
                    nativeMediaStream: RTCMediaStream) -> MediaStream {
        var mediaStream = MediaStream(peerConnection: peerConnection,
                                      role: role, channelId: channelId,
                                      mediaOption: mediaOption,
                                      nativeMediaStream: nativeMediaStream)
        mediaStream.context = MediaStreamContext(mediaStream: mediaStream)
        peerConnection.delegate = mediaStream.context
        return mediaStream
    }
    
    fileprivate init(peerConnection: RTCPeerConnection, role: Role, channelId: String,
         mediaOption: MediaOption = MediaOption(),
         nativeMediaStream: RTCMediaStream) {
        self.peerConnection = peerConnection
        self.role = role
        self.channelId = channelId
        self.mediaOption = mediaOption
        self.nativeMediaStream = nativeMediaStream
        state = .connected
        creationTime = Date()
    }
    
    mutating func disconnect() {
        peerConnection.close()
        state = .disconnected
    }
    
    public func isDisconnected() -> Bool {
        return state == .disconnected
    }
    
    mutating func setVideoRenderer(_ videoRenderer: VideoRenderer?) {
        if nativeMediaStream.videoTracks.isEmpty {
            return
        }
        
        let videoTrack = nativeMediaStream.videoTracks[0]
        if let renderer = videoRenderer {
            videoRendererSupport = VideoRendererSupport(videoRenderer: renderer)
            videoTrack.add(videoRendererSupport!)
        } else if let support = videoRendererSupport {
            videoTrack.remove(support)
        }
    }
    
    // MARK: イベントハンドラ
    
    var onConnectedHandler: ((MediaStream?, Error?) -> ())?
    var onDisconnectedHandler: ((MediaStream?, Error?) -> ())?
    
    public mutating func onDisconnected(_ handler: @escaping ((MediaStream?, Error?) -> ())) {
        onDisconnectedHandler = handler
    }
    
}

class MediaStreamContext: NSObject, RTCPeerConnectionDelegate {
    
    var mediaStream: MediaStream

    init(mediaStream: MediaStream) {
        self.mediaStream = mediaStream
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didChange stateChanged: RTCSignalingState) {
        print("peerConnection:didChangeSignalingState:", stateChanged.rawValue)
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didAdd stream: RTCMediaStream) {
        print("peerConnection:didAddStream:")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didRemove stream: RTCMediaStream) {
        print("peerConnection:didRemoveStream:")
    }
    
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        print("peerConnectionShouldNegotiate:")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didChange newState: RTCIceConnectionState) {
        print("peerConnection:didChangeIceConnectionState:", newState.rawValue)
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
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didGenerate candidate: RTCIceCandidate) {
        print("peerConnection:didGenerateIceCandidate:")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didRemove candidates: [RTCIceCandidate]) {
        print("peerConnection:didRemoveIceCandidates:")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didOpen dataChannel: RTCDataChannel) {
        print("peerConnection:didOpenDataChannel:")
    }
    
}
