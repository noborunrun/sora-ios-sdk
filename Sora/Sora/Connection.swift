import Foundation
import WebRTC
import SocketRocket

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
     デリゲートは `Connection` オブジェクトの状態管理に使われます。
     デリゲートをセットしたい場合は `peerConnectionDelegate` を利用してください。
     */
    public var peerConnection: RTCPeerConnection

    /**
     `peerConnection` のデリゲート。
     `Connection` オブジェクトは接続状態の管理のためのデリゲートを `peerConnection` にセットしているので、
     このプロパティに `peerConnection` のデリゲートをセットしてください。
     */
    public var peerConnectionDelegate: RTCPeerConnectionDelegate?
    
    public var fileLogger: RTCFileLogger
    
    /** メディアストリーム (RTCMediaStream オブジェクト) の配列 */
    public var remoteStreams: [RTCMediaStream]
    
    /** 受信した映像を描画するオブジェクト ( プロトコル) の配列 */
    public var remoteVideoRenderers: [RTCVideoRenderer]

    public var didStateChanged: ((Connection, State) -> ())?

    /**
     WebSocket 接続オブジェクト
     
     @warning このオブジェクトのデリゲートを変更しないでください。
     デリゲートは `Connection` オブジェクトの状態管理に使われます。
     デリゲートを設定したい場合は `webSocketDelegate` を利用してください。
     */
    public var webSocket: SRWebSocket
    
    /**
     `webSocket` のデリゲート。
     `Connection` オブジェクトは接続状態の管理のためのデリゲートを `webSocket` にセットしているので、
     このプロパティに `webSocket` のデリゲートをセットしてください。
     */
    public var webSocketDelegate: SRWebSocketDelegate?
    
    var context: Context
    
    /**
     指定のサーバーに接続し、初期化済みの `Connection` オブジェクトを返します。
     
     @param URL 接続するサーバーの URL
     @param config ピア接続の設定
     @param constraints メディアの制約
     @return 初期化済みの `Connection` オブジェクト
     */
    init(URL: NSURL, config: RTCConfiguration?, constraints: RTCMediaConstraints?) {
        self.URL = URL
        state = State.Closed
        peerConnectionFactory = RTCPeerConnectionFactory()
        context = Context()
        fileLogger = RTCFileLogger()
        fileLogger.start()
        remoteStreams = []
        remoteVideoRenderers = []
        webSocket = SRWebSocket(URL: URL)
        
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
        
        peerConnection = peerConnectionFactory
            .peerConnectionWithConfiguration(config!,
                                             constraints: constraints!,
                                             delegate: context)
    }
    
    public mutating func setState(state: State) {
        self.state = state
        didStateChanged?(self, state)
    }
    
    /**
     サーバーに接続します。
     
     @param connectRequest connect シグナリングメッセージ
     */
    public mutating func open(request: ConnectRequest) {
        // TODO
        webSocket.delegate = context
        webSocket.open()
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
    
    class Context: NSObject, RTCPeerConnectionDelegate, SRWebSocketDelegate {
        
        enum State {
            case Closed
            case Open
            case Connecting
            case CreatingAnswer
            case SendingAnswer
            case PeerOpen
        }
        
        var conn: Connection! = nil
        var state: State = .Closed
        
        func webSocketDidOpen(webSocket: SRWebSocket!) {
            // TODO
            print("WebSocket open")
            conn!.webSocketDelegate?.webSocketDidOpen?(webSocket)
        }
        
        func webSocket(webSocket: SRWebSocket!, didFailWithError error: NSError!) {
            print("WebSocket failed")
            state = .Closed
            conn!.state = .Closed
            conn!.webSocketDelegate?.webSocket?(webSocket, didFailWithError: error)
        }
        
        func webSocket(webSocket: SRWebSocket!, didReceivePong pongPayload: NSData!) {
            // TODO
            conn!.webSocketDelegate?.webSocket?(webSocket, didReceivePong: pongPayload)
        }
        
        func webSocket(webSocket: SRWebSocket!, didReceiveMessage message: AnyObject!) {
            // TODO
            conn!.webSocketDelegate?.webSocket(webSocket, didReceiveMessage: message)
        }
        
        func webSocket(webSocket: SRWebSocket!, didCloseWithCode code: Int, reason: String!, wasClean: Bool) {
            // TODO
            conn!.webSocketDelegate?.webSocket?(webSocket, didCloseWithCode: code, reason: reason, wasClean: wasClean)
        }
        
        func peerConnection(peerConnection: RTCPeerConnection, didChangeSignalingState stateChanged: RTCSignalingState) {
            // TODO
            conn!.peerConnectionDelegate?
                .peerConnection(peerConnection, didChangeSignalingState: stateChanged)
        }
        
        func peerConnection(peerConnection: RTCPeerConnection, didAddStream stream: RTCMediaStream) {
            // TODO
            conn!.peerConnectionDelegate?
                .peerConnection(peerConnection, didAddStream: stream)
        }
        
        func peerConnection(peerConnection: RTCPeerConnection, didRemoveStream stream: RTCMediaStream) {
            // TODO
            conn!.peerConnectionDelegate?
                .peerConnection(peerConnection, didRemoveStream: stream)
        }
        
        func peerConnectionShouldNegotiate(peerConnection: RTCPeerConnection) {
            // TODO
            conn!.peerConnectionDelegate?.peerConnectionShouldNegotiate(peerConnection)
        }
        
        func peerConnection(peerConnection: RTCPeerConnection, didChangeIceConnectionState newState: RTCIceConnectionState) {
            // TODO
            conn!.peerConnectionDelegate?
                .peerConnection(peerConnection, didChangeIceConnectionState: newState)
        }
        
        func peerConnection(peerConnection: RTCPeerConnection, didChangeIceGatheringState newState: RTCIceGatheringState) {
            // TODO
            conn!.peerConnectionDelegate?
                .peerConnection(peerConnection, didChangeIceGatheringState: newState)
        }
        
        func peerConnection(peerConnection: RTCPeerConnection, didGenerateIceCandidate candidate: RTCIceCandidate) {
            // TODO
            conn!.peerConnectionDelegate?
                .peerConnection(peerConnection, didGenerateIceCandidate: candidate)
        }
        
        func peerConnection(peerConnection: RTCPeerConnection, didRemoveIceCandidates candidates: [RTCIceCandidate]) {
            // TODO
            conn!.peerConnectionDelegate?
                .peerConnection(peerConnection, didRemoveIceCandidates: candidates)
        }
        
        func peerConnection(peerConnection: RTCPeerConnection, didOpenDataChannel dataChannel: RTCDataChannel) {
            // TODO
            conn!.peerConnectionDelegate?
                .peerConnection(peerConnection, didOpenDataChannel: dataChannel)
        }
        
    }
    
}