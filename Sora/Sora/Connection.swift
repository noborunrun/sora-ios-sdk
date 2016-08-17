import Foundation
import WebRTC
import SocketRocket

public protocol ConnectionDelegate {
    
    func didFail(connection: Connection, error: NSError)
    func didChangeState(connection: Connection, state: Connection.State)
    func didSendSignalingConnect(connection: Connection, message: Signaling.Connect)
    func didReceiveSignalingOffer(connection: Connection, message: Signaling.Offer)
    func didSendSignalingAnswer(connection: Connection, message: Signaling.Answer)
    func didSendCandidate(connection: Connection, candidate: RTCIceCandidate)

}

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
    
    public enum ErrorCode: Int {
        /** 内部エラー */
        case InvalidState = 0
    }

    static let errorDomain = "Sora.Connection"

    /** Sora サーバーの URL */
    public var URL: NSURL
    
    /** Sora サーバーとの接続状態 */
    public var state: State = .Closed {
        
        didSet {
            delegate?.didChangeState(self, state: state)
        }
        
    }
    
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

    /** デリゲート */
    public var delegate: ConnectionDelegate?
    
    var context: Context?

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
    
    /**
     サーバーに接続します。
     
     @param connect connect シグナリングメッセージ
     */
    public mutating func open(message: Signaling.Connect) {
        // TODO
        context = Context(connection: self)
        webSocket.delegate = context
        webSocket.open()
    }
    
    /** サーバーとの接続を閉じます。 */
    public mutating func close() {
        context = nil
        webSocket.delegate = nil
        webSocket.close()
    }
    
    /**
     シグナリングメッセージを送信します。
     
     @param message 送信するシグナリングメッセージ
     */
    public func send(message: String) {
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
        
        var conn: Connection
        var state: State = .Closed
        
        init(connection: Connection) {
            conn = connection
        }
        
        func sendSignalingConnect(connect: Signaling.Connect) {
            // TODO:
        }
        
        // MARK: SRWebSocket Delegate
        
        func webSocketDidOpen(webSocket: SRWebSocket!) {
            // TODO
            print("WebSocket open")
            conn.webSocketDelegate?.webSocketDidOpen?(webSocket)
            
            switch state {
            case .Closed:
                // TODO
                state = .Open
                break
            default:
                let error = NSError(domain: errorDomain,
                                    code: ErrorCode.InvalidState.rawValue,
                                    userInfo: nil)
                conn.delegate?.didFail(conn, error: error)
            }
        }
        
        func webSocket(webSocket: SRWebSocket!, didFailWithError error: NSError!) {
            print("WebSocket failed")
            state = .Closed
            conn.state = .Closed
            conn.webSocketDelegate?.webSocket?(webSocket, didFailWithError: error)
        }
        
        func webSocket(webSocket: SRWebSocket!, didReceivePong pongPayload: NSData!) {
            // TODO
            conn.webSocketDelegate?.webSocket?(webSocket, didReceivePong: pongPayload)
        }
        
        func webSocket(webSocket: SRWebSocket!, didReceiveMessage message: AnyObject!) {
            // TODO
            conn.webSocketDelegate?.webSocket(webSocket, didReceiveMessage: message)
        }
        
        func webSocket(webSocket: SRWebSocket!, didCloseWithCode code: Int, reason: String!, wasClean: Bool) {
            // TODO
            conn.webSocketDelegate?.webSocket?(webSocket, didCloseWithCode: code, reason: reason, wasClean: wasClean)
        }
        
        // MARK: RTCPeerConnection Delegate
        
        func peerConnection(peerConnection: RTCPeerConnection, didChangeSignalingState stateChanged: RTCSignalingState) {
            // TODO
            conn.peerConnectionDelegate?
                .peerConnection(peerConnection, didChangeSignalingState: stateChanged)
        }
        
        func peerConnection(peerConnection: RTCPeerConnection, didAddStream stream: RTCMediaStream) {
            // TODO
            conn.peerConnectionDelegate?
                .peerConnection(peerConnection, didAddStream: stream)
        }
        
        func peerConnection(peerConnection: RTCPeerConnection, didRemoveStream stream: RTCMediaStream) {
            // TODO
            conn.peerConnectionDelegate?
                .peerConnection(peerConnection, didRemoveStream: stream)
        }
        
        func peerConnectionShouldNegotiate(peerConnection: RTCPeerConnection) {
            // TODO
            conn.peerConnectionDelegate?.peerConnectionShouldNegotiate(peerConnection)
        }
        
        func peerConnection(peerConnection: RTCPeerConnection, didChangeIceConnectionState newState: RTCIceConnectionState) {
            // TODO
            conn.peerConnectionDelegate?
                .peerConnection(peerConnection, didChangeIceConnectionState: newState)
        }
        
        func peerConnection(peerConnection: RTCPeerConnection, didChangeIceGatheringState newState: RTCIceGatheringState) {
            // TODO
            conn.peerConnectionDelegate?
                .peerConnection(peerConnection, didChangeIceGatheringState: newState)
        }
        
        func peerConnection(peerConnection: RTCPeerConnection, didGenerateIceCandidate candidate: RTCIceCandidate) {
            // TODO
            conn.peerConnectionDelegate?
                .peerConnection(peerConnection, didGenerateIceCandidate: candidate)
        }
        
        func peerConnection(peerConnection: RTCPeerConnection, didRemoveIceCandidates candidates: [RTCIceCandidate]) {
            // TODO
            conn.peerConnectionDelegate?
                .peerConnection(peerConnection, didRemoveIceCandidates: candidates)
        }
        
        func peerConnection(peerConnection: RTCPeerConnection, didOpenDataChannel dataChannel: RTCDataChannel) {
            // TODO
            conn.peerConnectionDelegate?
                .peerConnection(peerConnection, didOpenDataChannel: dataChannel)
        }
        
    }
    
}