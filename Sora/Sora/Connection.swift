import Foundation
import WebRTC

/**
 Sora サーバーとシグナリング接続を行います。
 Sora サーバーでは、シグナリングは WebSocket で JSON フォーマットのメッセージを介して行います。
 */
public struct Connection {
    
    /** Sora サーバーとの接続状態を表します。 */
    public enum State {
        
        /** シグナリング接続中です。 */
        case Connecting
        
        /** シグナリング接続が完了し、シグナリングメッセージの通信が可能です。 */
        case Open
        
        /** ピア接続中です。 */
        case PeerConnecting
        
        /** ピア接続が完了し、データ通信が可能です。 */
        case PeerOpen
        
        /** シグナリング切断中です。 */
        case Closing
        
        /** シグナリング接続していません。 */
        case Closed
        
    }

    /** Sora サーバーの URL */
    public var URL: NSURL
    
    /** Sora サーバーとの接続状態 */
    public var state: State
    
    /** デリゲート */
    public var peerConnectionFactory: RTCPeerConnectionFactory
    
    /**
     ピア接続オブジェクト
     
     @warning このオブジェクトのデリゲートを変更しないでください。
     デリゲートは `SoraConnection` オブジェクトの状態管理に使われます。
     */
    public var peerConnection: RTCPeerConnection
    
    public var fileLogger: RTCFileLogger
    
    /** メディアストリーム (RTCMediaStream オブジェクト) の配列 */
    public var remoteStreams: [RTCMediaStream]
    
    /** 受信した映像を描画するオブジェクト ( プロトコル) の配列 */
    public var remoteVideoRenderers: [RTCVideoRenderer]

    var context: Context
    
    /**
     指定のサーバーに接続し、初期化済みの `SoraConnection` オブジェクトを返します。
     
     @param URL 接続するサーバーの URL
     @param config ピア接続の設定
     @param constraints メディアの制約
     @return 初期化済みの `SoraConnection` オブジェクト
     */
    init(URL: NSURL, config: RTCConfiguration?, constraints: RTCMediaConstraints?) {
        self.URL = URL
        self.state = State.Closed
        self.peerConnectionFactory = RTCPeerConnectionFactory()
        self.context = Context()
        self.fileLogger = RTCFileLogger()
        self.fileLogger.start()
        self.remoteStreams = []
        self.remoteVideoRenderers = []
        
        var config: RTCConfiguration? = config
        var constraints: RTCMediaConstraints? = constraints
        if config == nil {
            config = RTCConfiguration()
        }
        if constraints == nil {
            constraints = RTCMediaConstraints(mandatoryConstraints: [:],
                                              optionalConstraints: [:])
        }
        // default ICE servers
        config?.iceServers = [RTCIceServer(URLStrings: ["stun:stun.l.google.com:19302"])]
        
        self.peerConnection = self.peerConnectionFactory
            .peerConnectionWithConfiguration(config!,
                                             constraints: constraints!,
                                             delegate: self.context)
    }
    
    /**
     サーバーに接続します。
     
     @param connectRequest connect シグナリングメッセージ
     */
    public func open(request: ConnectRequest) {
        // TODO
    }
    
    /** サーバーとの接続を閉じます。 */
    public func close() {
        // TODO
    }
    
    /**
     シグナリングメッセージを送信します。
     
     @param message 送信するシグナリングメッセージ
     */
    public func send(message: Message) {
        // TODO
    }
    
    class Context: NSObject, RTCPeerConnectionDelegate {
    
        let conn: Connection! = nil
        
        func peerConnection(peerConnection: RTCPeerConnection, didChangeSignalingState stateChanged: RTCSignalingState) {
            // TODO
        }
        
        func peerConnection(peerConnection: RTCPeerConnection, didAddStream stream: RTCMediaStream) {
            // TODO
        }
        
        func peerConnection(peerConnection: RTCPeerConnection, didRemoveStream stream: RTCMediaStream) {
            // TODO
        }
        
        func peerConnectionShouldNegotiate(peerConnection: RTCPeerConnection) {
            // TODO
        }
        
        func peerConnection(peerConnection: RTCPeerConnection, didChangeIceConnectionState newState: RTCIceConnectionState) {
            // TODO
        }
        
        func peerConnection(peerConnection: RTCPeerConnection, didChangeIceGatheringState newState: RTCIceGatheringState) {
            // TODO
        }
        
        func peerConnection(peerConnection: RTCPeerConnection, didGenerateIceCandidate candidate: RTCIceCandidate) {
            // TODO
        }
        
        func peerConnection(peerConnection: RTCPeerConnection, didRemoveIceCandidates candidates: [RTCIceCandidate]) {
            // TODO
        }
        
        func peerConnection(peerConnection: RTCPeerConnection, didOpenDataChannel dataChannel: RTCDataChannel) {
            // TODO
        }
        
    }
    
}