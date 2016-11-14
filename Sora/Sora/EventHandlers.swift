import Foundation
import WebRTC
import SocketRocket

public struct MediaConnectionState {
    
    public var numberOfUpstreamConnections: Int?
    public var numberOfDownstreamConnections: Int?
    
}

public class WebSocketEventHandlers {

    var onOpenHandler: ((SRWebSocket) -> ())?
    var onFailureHandler: ((SRWebSocket, Error) -> ())?
    var onPongHandler: ((SRWebSocket, Data) -> ())?
    var onMessageHandler: ((SRWebSocket, String) -> ())?
    var onCloseHandler: ((SRWebSocket, Int, String, Bool) -> ())?

    func onOpen(handler: @escaping (SRWebSocket) -> ()) {
        onOpenHandler = handler
    }
    
    func onFailure(handler: @escaping (SRWebSocket, Error) -> ()) {
        onFailureHandler = handler
    }
    
    func onPong(handler: @escaping (SRWebSocket, Data) -> ()) {
        onPongHandler = handler
    }
    
    func onMessage(handler: @escaping (SRWebSocket, String) -> ()) {
        onMessageHandler = handler
    }
    
    func onClose(handler: @escaping (SRWebSocket, Int, String, Bool) -> ()) {
        onCloseHandler = handler
    }
    
}

public class SignalingEventHandlers {
    
    var onReceiveHandler: ((Message) -> Void)?
    var onConnectHandler: ((Void) -> Void)?
    var onDisconnectHandler: ((Void) -> Void)?
    var onUpdateHandler: ((MediaConnectionState) -> Void)?
    var onFailureHandler: ((ConnectionError) -> Void)?
    var onPingHandler: ((Void) -> Void)?
    var onNotifyHandler: ((String) -> Void)?
    
    public func onReceive(handler: @escaping ((Message) -> Void)) {
        onReceiveHandler = handler
    }
    
    public func onConnect(handler: @escaping ((Void) -> Void)) {
        onConnectHandler = handler
    }
    
    public func onDisconnect(handler: @escaping ((Void) -> Void)) {
        onDisconnectHandler = handler
    }
    
    public func onUpdate(handler: @escaping ((MediaConnectionState) -> Void)) {
        onUpdateHandler = handler
    }
    
    public func onFailure(handler: @escaping ((ConnectionError) -> Void)) {
        onFailureHandler = handler
    }
    
    public func onPing(handler: @escaping ((Void) -> Void)) {
        onPingHandler = handler
    }
    
    public func onNotify(handler: @escaping ((String) -> Void)) {
        onNotifyHandler = handler
    }
    
}

public class PeerConnectionEventHandlers {
    
    var onChangeSignalingStateHandler:
    ((RTCPeerConnection, RTCSignalingState) -> Void)?
    var onAddStreamHandler: ((RTCPeerConnection, RTCMediaStream) -> Void)?
    var onRemoveStreamHandler: ((RTCPeerConnection, RTCMediaStream) -> Void)?
    var onNegotiateHandler: ((RTCPeerConnection) -> Void)?
    var onChangeIceConnectionState:
    ((RTCPeerConnection,  RTCIceConnectionState) -> Void)?
    var onChangeIceConnectionStateHandler:
    ((RTCPeerConnection,  RTCIceConnectionState) -> Void)?
    var onChangeIceGatheringStateHandler:
    ((RTCPeerConnection, RTCIceGatheringState) -> Void)?
    var onGenerateIceCandidateHandler:
    ((RTCPeerConnection, RTCIceCandidate) -> Void)?
    var onRemoveCandidatesHandler:
    ((RTCPeerConnection, [RTCIceCandidate]) -> Void)?
    var onOpenDataChannelHandler:
    ((RTCPeerConnection, RTCDataChannel) -> Void)?
    
    func onChangeSignalingState(handler:
        @escaping (RTCPeerConnection, RTCSignalingState) -> Void) {
        onChangeSignalingStateHandler = handler
    }
    
    func onAddStream(handler:
        @escaping (RTCPeerConnection, RTCMediaStream) -> Void) {
        onAddStreamHandler = handler
    }
    
    func onRemoveStream(handler:
        @escaping (RTCPeerConnection, RTCMediaStream) -> Void) {
        onRemoveStreamHandler = handler
    }
    
    func onNegotiate(handler: @escaping (RTCPeerConnection) -> Void) {
        onNegotiateHandler = handler
    }
    
    func onChangeIceConnectionState(handler:
        @escaping (RTCPeerConnection,  RTCIceConnectionState) -> Void) {
        onChangeIceConnectionStateHandler = handler
    }
    
    func onChangeIceGatheringState(handler:
        @escaping (RTCPeerConnection, RTCIceGatheringState) -> Void) {
        onChangeIceGatheringStateHandler = handler
    }
    
    func onGenerateIceCandidate(handler:
        @escaping (RTCPeerConnection, RTCIceCandidate) -> Void) {
        onGenerateIceCandidateHandler = handler
    }
    
    func onRemoveCandidates(handler:
        @escaping (RTCPeerConnection, [RTCIceCandidate]) -> Void) {
        onRemoveCandidatesHandler = handler
    }
    
    func onOpenDataChannel(handler:
        @escaping (RTCPeerConnection, RTCDataChannel) -> Void) {
        onOpenDataChannelHandler = handler
    }

}
