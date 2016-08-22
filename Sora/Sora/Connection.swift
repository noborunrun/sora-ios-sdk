import Foundation
import WebRTC
import SocketRocket
import Argo

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
        
        /** RTCPeerConnection のエラー */
        case PeerConnection
        
        /** SRWebSocket のエラー */
        case WebSocket
        
    }

    public enum ErrorKey: String {
        
        case Wrap = "Wrap"
        
    }
    
    static let errorDomain = "Sora.Connection"

    /** Sora サーバーの URL */
    public var URL: NSURL
    
    /** Sora サーバーとの接続状態 */
    public var state: State = .Closed {
        
        didSet {
            _onChangeState?(state)
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
    
    var context: Context?

    /**
     指定のサーバーに接続し、初期化済みの `Connection` オブジェクトを返します。
     
     @param URL 接続するサーバーの URL
     @param config ピア接続の設定
     @param constraints メディアの制約
     @return 初期化済みの `Connection` オブジェクト
     */
    public init(URL: NSURL, config: RTCConfiguration?, constraints: RTCMediaConstraints?) {
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
     @param completionHandler 接続処理終了時に実行されるクロージャー
     */
    public mutating func open(message: Signaling.Connect,
                              completionHandler: ((NSError?) -> ())?) {
        context = Context(connection: self, message: message,
                          completionHandler: completionHandler)
        webSocket.delegate = context
        webSocket.open()
    }
    
    /** サーバーとの接続を閉じます。 */
    public mutating func close() {
        context = nil
        webSocket.delegate = nil
        webSocket.close()
    }
    
    public mutating func addRemoteVideoRenderer(renderer: RTCVideoRenderer) {
        remoteVideoRenderers.append(renderer)
        for stream in remoteStreams {
            for track in stream.videoTracks {
                track.addRenderer(renderer)
            }
        }
    }
    
    public mutating func removeRemoteVideoRenderer(renderer: RTCVideoRenderer) {
        remoteVideoRenderers = remoteVideoRenderers.filter { !$0.isEqual(renderer) }
    }
    
    // MARK: Callbacks
    
    var _onFail: ((NSError) -> ())?
    var _onChangeState: ((Connection.State) -> ())?
    var _onSendSignalingConnect: ((Signaling.Connect) -> ())?
    var _onReceiveSignalingOffer: ((Signaling.Offer) -> ())?
    var _onSendSignalingAnswer: ((Signaling.Answer) -> ())?
    var _onReceiveCandidate: ((RTCIceCandidate) -> ())?
    
    mutating func onFail(callback: (NSError) -> ()) {
        _onFail = callback
    }
    
    mutating func onChangeState(callback: (Connection.State) -> ()) {
        _onChangeState = callback
    }
    
    mutating func onSendSignalingConnect(callback: (Signaling.Connect) -> ()) {
        _onSendSignalingConnect = callback
    }
    
    mutating func onReceiveSignalingOffer(callback: (Signaling.Offer) -> ()) {
        _onReceiveSignalingOffer = callback
    }
    
    mutating func onSendSignalingAnswer(callback: (Signaling.Answer) -> ()) {
        _onSendSignalingAnswer = callback
    }
    
    mutating func onReceiveCandidate(callback: (RTCIceCandidate) -> ()) {
        _onReceiveCandidate = callback
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
        var sigConnect: Signaling.Connect
        var completionHandler: ((NSError?) -> ())?
        
        init(connection: Connection, message: Signaling.Connect, completionHandler: ((NSError?) -> ())?) {
            conn = connection
            sigConnect = message
            self.completionHandler = completionHandler
        }
        
        func wrapError(code: ErrorCode, error: NSError) -> NSError {
            return NSError(domain: errorDomain,
                           code: code.rawValue,
                           userInfo: [ErrorKey.Wrap.rawValue: error])
        }
        
        func wrapFail(code: ErrorCode, error: NSError) {
            let wrap = wrapError(code, error: error)
            completionHandler?(wrap)
        }
        
        // MARK: SRWebSocket Delegate
        
        func webSocketDidOpen(webSocket: SRWebSocket!) {
            print("WebSocket open")
            conn.webSocketDelegate?.webSocketDidOpen?(webSocket)
            switch state {
            case .Closed:
                state = .Connecting
                let json = sigConnect.JSONString()
                print(json)
                webSocket.send(json)
            default:
                state = .Open
                let error = NSError(domain: errorDomain,
                                    code: ErrorCode.InvalidState.rawValue,
                                    userInfo: nil)
                conn._onFail?(error)
            }
        }
        
        func webSocket(webSocket: SRWebSocket!, didFailWithError error: NSError!) {
            print("WebSocket failed")
            state = .Closed
            conn.state = .Closed
            conn._onFail?(error)
            conn.webSocketDelegate?.webSocket?(webSocket, didFailWithError: error)
        }
        
        func webSocket(webSocket: SRWebSocket!, didReceivePong pongPayload: NSData!) {
            // TODO
            conn.webSocketDelegate?.webSocket?(webSocket, didReceivePong: pongPayload)
        }
        
        func webSocket(webSocket: SRWebSocket!, didReceiveMessage message: AnyObject!) {
            // TODO
            print("WebSocket receive message")
            if let s = message as? String {
                if let json = ParseJSONData(s) {
                    switch json["type"] as? String {
                    case "pong"?:
                        print("ping pong")
                        return
                    default:
                        break
                    }
                    
                    switch state {
                    case .Connecting:
                        // TODO
                        if let offer: Signaling.Offer = decode(json) {
                            receiveSignalingOffer(webSocket, message: offer)
                        }
                        break
                    default:
                        // do nothing
                        break
                    }
                }
                conn.webSocketDelegate?.webSocket(webSocket, didReceiveMessage: message)
            }
        }
        
        func receiveSignalingOffer(webSocket: SRWebSocket, message: Signaling.Offer) {
            // TODO: config
            conn._onReceiveSignalingOffer?(message)
            state = .CreatingAnswer
            
            print("set remote description")
            conn.peerConnection
                .setRemoteDescription(message.sessionDescription()) {
                (error: NSError?) -> () in
                if let error = error {
                    self.wrapFail(ErrorCode.PeerConnection, error: error)
                    return
                }
            }
            
            print("create answer")
            conn.peerConnection.answerForConstraints(sigConnect.answerConstraints) {
                    (sdp: RTCSessionDescription?, error: NSError?) -> () in
                if let error = error {
                    self.wrapFail(ErrorCode.PeerConnection, error: error)
                    return
                } else if let sdp = sdp {
                    self.sendSignalingAnswer(webSocket, SDP: sdp)
                }
            }
        }
        
        func sendSignalingAnswer(webSocket: SRWebSocket, SDP: RTCSessionDescription) {
            print("set local description")
            conn.peerConnection.setLocalDescription(SDP) {
                (error: NSError?) -> () in
                if let error = error {
                    self.wrapFail(ErrorCode.PeerConnection, error: error)
                    return
                }
            }
            print("send answer")
            let answer = Signaling.Answer(SDP: SDP)
            webSocket.send(answer.JSONString())
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