import Foundation
import WebRTC
import SocketRocket
import UIKit
import Unbox

public enum ConnectionError: Error {
    case failureJSONDecode
    case duplicatedChannelId
    case authenticationFailure
    case authenticationInternalError
    case unknownVideoCodecType
    case failureSDPParse
    case failureMissingSDP
    case failureSetConfiguration(RTCConfiguration)
    case unknownType
    case connectWaitTimeout
    case connectionDisconnected
    case connectionBusy
    case multipleDownstreams
    case webSocketClose(Int, String)
    case webSocketError(Error)
    case peerConnectionError(Error)
    case iceConnectionFailed
}

public class Connection {
    
    public enum State {
        case connected
        case connecting
        case disconnected
        case disconnecting
    }
    
    public var URL: Foundation.URL
    public var mediaChannels: [MediaChannel] = []
    public var eventLog: EventLog = EventLog()
    
    public var state: State = .disconnected {
        
        didSet {
            onUpdatedHandler?(state)
        }
        
    }

    public var peerConnectionFactory: RTCPeerConnectionFactory {
        get { return context.peerConnFactory }
    }
    
    var webSocket: SRWebSocket?
    var context: ConnectionContext!
    
    public init(URL: Foundation.URL) {
        self.URL = URL
        state = .disconnected
        context = ConnectionContext(connection: self)
    }
    
    // MARK: シグナリング接続
    
    public func connect(_ handler: @escaping ((ConnectionError?) -> Void)) {
        context.connect(handler)
    }
    
    public func disconnect(_ handler: @escaping ((ConnectionError?) -> Void)) {
        for channel in mediaChannels {
            channel.disconnect()
        }
        context.disconnect(handler)
    }
    
    public func send(_ message: Message) {
        context.send(message)
    }
    
    public func send(_ messageable: Messageable) {
        context.send(messageable.message())
    }
    
    public func isReady() -> Bool {
        return context.state == .ready
    }
    
    // メディアチャネル
    public func createMediaChannel(_ channelId: String) -> MediaChannel {
        let channel = MediaChannel(connection: self, channelId: channelId)
        mediaChannels.append(channel)
        return channel
    }
    
    func createMediaUpstream(_ channelId: String, accessToken: String?,
                             mediaOption: MediaOption,
                             streamId: String,
                             handler: @escaping ((MediaStream?, MediaCapturer?, Error?) -> Void)) {
        context.createPeerConnection(Role.upstream, channelId: channelId,
                                     accessToken: accessToken,
                                     mediaOption: mediaOption)
        {
            (peerConn, upstream, downstream, mediaCapturer, error) in
            print("on peer connection open: ", error)
            if let error = error {
                handler(nil, nil, error)
                return
            }
            assert(upstream != nil, "upstream is nil")
            let mediaStream = MediaStream(connection: self,
                                          peerConnection: peerConn!,
                                          role: Role.upstream,
                                          channelId: channelId,
                                          mediaOption: mediaOption,
                                          nativeMediaStream: upstream!)
            handler(mediaStream, mediaCapturer, nil)
        }
    }
    
    func createMediaDownstream(_ channelId: String, accessToken: String?,
                               mediaOption: MediaOption,
                               handler: @escaping ((MediaStream?, Error?) -> Void)) {
        context.createPeerConnection(Role.downstream, channelId: channelId,
                                     accessToken: accessToken,
                                     mediaOption: mediaOption)
        {
            (peerConn, upstream, downstream, mediaCapturer, error) in
            print("on peer connection open: ", error)
            if let error = error {
                handler(nil, error)
                return
            }
            
            let mediaStream = MediaStream(connection: self,
                                          peerConnection: peerConn!,
                                          role: Role.downstream,
                                          channelId: channelId,
                                          mediaOption: mediaOption,
                                          nativeMediaStream: downstream!)
            handler(mediaStream, nil)
        }
    }
    
    // MARK: イベントハンドラ
    
    var onReceiveHandler: ((Message) -> Void)?
    var onConnectedHandler: ((Void) -> Void)?
    var onDisconnectedHandler: ((Void) -> Void)?
    var onUpdatedHandler: ((State) -> Void)?
    var onFailedHandler: ((ConnectionError) -> Void)?
    var onPingHandler: ((Void) -> Void)?
    var onStatisticsHandler: ((Statistics) -> Void)?
    var onNotifyHandler: ((String) -> Void)?
    
    // シグナリングメッセージ
    public func onReceive(_ handler: @escaping ((Message) -> Void)) {
        onReceiveHandler = handler
    }
    
    // 接続
    public func onConnected(_ handler: @escaping ((Void) -> Void)) {
        onConnectedHandler = handler
    }
    
    public func onDisconnected(_ handler: @escaping ((Void) -> Void)) {
        onDisconnectedHandler = handler
    }
    
    public func onUpdated(_ handler: @escaping ((State) -> Void)) {
        onUpdatedHandler = handler
    }
    
    public func onFailed(_ handler: @escaping ((ConnectionError) -> Void)) {
        onFailedHandler = handler
    }
    
    public func onPing(_ handler: @escaping ((Void) -> Void)) {
        onPingHandler = handler
    }
    
    public func onStatistics(_ handler: @escaping ((Statistics) -> Void)) {
        onStatisticsHandler = handler
    }
    
    public func onNotify(_ handler: @escaping ((String) -> Void)) {
        onNotifyHandler = handler
    }
    
}

class ConnectionContext: NSObject, SRWebSocketDelegate {
    
    enum State {
        case connecting
        case disconnecting
        case disconnected
        case ready
        case peerOffered
        case peerAnswering
        case peerAnswered
        case peerConnecting
    }
    
    weak var conn: Connection!
    var webSocket: SRWebSocket!
    var state: State = .disconnected
    var peerConnFactory: RTCPeerConnectionFactory
    var peerConnContext: PeerConnectionContext!
    var role: Role?
    var upstream: RTCMediaStream?
    var mediaCapturer: MediaCapturer?

    var onConnectedHandler: ((ConnectionError?) -> Void)?
    var onDisconnectedHandler: ((ConnectionError?) -> Void)?
    var onSentHandler: ((ConnectionError?) -> Void)?
    
    init(connection: Connection) {
        self.conn = connection
        peerConnFactory = RTCPeerConnectionFactory()
    }
    
    func validateState() -> ConnectionError? {
        if state == .disconnected || state == .disconnecting {
            return ConnectionError.connectionDisconnected
        } else if state != .ready {
            return ConnectionError.connectionBusy
        } else {
            return nil
        }
    }
    
    func connect(_ handler: @escaping ((ConnectionError?) -> Void)) {
        if state != .disconnected {
            handler(ConnectionError.connectionBusy)
            return
        }
        
        conn.eventLog.mark(event:
            Event(type: .WebSocket,
                  comment: String(format: "open %@", conn.URL.description)))
        state = .connecting
        onConnectedHandler = handler
        webSocket = SRWebSocket(url: conn.URL)
        webSocket.delegate = self
        webSocket.open()
    }
    
    func disconnect(_ handler: @escaping ((ConnectionError?) -> Void)) {
        if let error = validateState() {
            handler(error)
            return
        }
        state = .disconnecting
        onDisconnectedHandler = handler
        webSocket.close()
        webSocket = nil
        conn.eventLog.markFormat(type: .WebSocket, format: "close")
    }
    
    func send(_ message: Message) {
        let j = message.JSON()
        let data = try! JSONSerialization.data(withJSONObject: j,
                                               options: JSONSerialization.WritingOptions(rawValue: 0))
        let msg = NSString(data: data, encoding: String.Encoding.utf8.rawValue) as String!
        print("WebSocket send ", j)
        conn.eventLog.markFormat(type: .WebSocket, format: "send message: %@",
                                 arguments: msg!)
        webSocket.send(msg)
    }

    func send(_ messageable: Messageable) {
        self.send(messageable.message())
    }
    
    func createPeerConnection(_ role: Role, channelId: String,
                              accessToken: String?, mediaOption: MediaOption,
                              handler: @escaping ((RTCPeerConnection?, RTCMediaStream?, RTCMediaStream?, MediaCapturer?, Error?) -> Void)) {
        if let error = validateState() {
            handler(nil, nil, nil, nil, error)
            return
        }
        
        self.role = role
        peerConnContext = PeerConnectionContext(connContext: self, factory: peerConnFactory, mediaOption: mediaOption) {
            (peerConn, downstream, error) in
            handler(peerConn, self.upstream, downstream, self.mediaCapturer, error)
        }
        peerConnContext.createPeerConnection()
        prepareUpstream()
        
        // send "connect"
        print("send connect")
        state = .peerConnecting
        let sigConnect = SignalingConnect(role: SignalingRole.from(role), channel_id: channelId)
        conn.eventLog.markFormat(type: .Signaling,
                                 format: "send connect message: %@",
                                 arguments: sigConnect.message().JSON().description)
        send(sigConnect)
    }
    
    func prepareUpstream() {
        if role == Role.upstream {
            print("create media capturer")
            upstream = peerConnFactory.mediaStream(withStreamId: MediaStream.defaultStreamId)
            let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
            mediaCapturer = MediaCapturer(factory: peerConnFactory, videoCaptureSourceMediaConstraints: constraints)
            upstream!.addVideoTrack(mediaCapturer!.videoCaptureTrack)
            upstream!.addAudioTrack(mediaCapturer!.audioCaptureTrack)
            peerConnContext.peerConn.add(upstream!)
        }
    }
    
    // MARK: SRWebSocketDelegate
    
    func webSocketDidOpen(_ webSocket: SRWebSocket!) {
        conn.eventLog.markFormat(type: .WebSocket, format: "opened")
        state = .ready
        onConnectedHandler?(nil)
    }
    
    func webSocket(_ webSocket: SRWebSocket!, didFailWithError error: Error!) {
        print("webSocket:didFailWithError:")
        conn.eventLog.markFormat(type: .WebSocket, format: "fail: %@",
                                 arguments: error.localizedDescription)
        let connError = ConnectionError.webSocketError(error)
        switch state {
        case .connecting:
            onConnectedHandler?(connError)
        case .disconnecting:
            onDisconnectedHandler?(connError)
        default:
            break
        }
    }
    
    func webSocket(_ webSocket: SRWebSocket!, didReceivePong pongPayload: Data!) {
        conn.eventLog.markFormat(type: .WebSocket,
                                 format: "received pong: %@",
                                 arguments: pongPayload.description)
    }
    
    func webSocket(_ webSocket: SRWebSocket!, didReceiveMessage message: Any!) {
        // TODO:
        print("webSocket:didReceiveMessage:", message)
        conn.eventLog.markFormat(type: .WebSocket,
                                 format: "received message: %@",
                                 arguments: (message as AnyObject).description)
        
        if let message = Message.fromJSONData(message) {
            conn.onReceiveHandler?(message)
            let json = message.JSON()
            print("received message type: ", message.type)
            switch message.type {
            case .ping?:
                conn.eventLog.markFormat(type: .Signaling, format: "received ping")
                let pong = SignalingPong()
                self.send(pong)
                
            case .stats?:
                var stats: Statistics!
                do {
                    stats = Optional.some(try unbox(dictionary: json))
                } catch {
                    conn.eventLog.markFormat(type: .Signaling,
                                             format: "failed parsing stats: %@",
                                             arguments: json.description)
                }
                
                var buf = "received statistics"
                if let n = stats.numberOfDownstreamConnections {
                    buf = buf.appendingFormat(": downstreams=%d", n)
                }
                conn.eventLog.markFormat(type: .Signaling, format: buf)
                
                conn.onStatisticsHandler?(stats)
                
            case .notify?:
                var notify: SignalingNotify!
                do {
                    notify = Optional.some(try unbox(dictionary: json))
                } catch {
                    conn.eventLog.markFormat(type: .Signaling,
                                             format: "failed parsing notify: %@",
                                             arguments: json.description)
                }
                
                conn.eventLog.markFormat(type: .Signaling, format: "received notify: %@",
                                         arguments: notify.notifyMessage)
                
                conn.onNotifyHandler?(notify.notifyMessage)
                
            case .offer?:
                conn.eventLog.markFormat(type: .Signaling, format: "received offer")
                let offer: SignalingOffer!
                do {
                    offer = Optional.some(try unbox(dictionary: json))
                } catch {
                    print("parse fail")
                    state = .ready
                    return
                }
                print("peer offered")
                
                if let config = offer.config {
                    print("offer config:", config)
                    let peerConfig = RTCConfiguration()
                    
                    switch config.iceTransportPolicy {
                    case "relay":
                        peerConfig.iceTransportPolicy = .relay
                    default:
                        print("unsupported iceTransportPolicy:",
                              config.iceTransportPolicy)
                        state = .ready
                        return
                    }
                    
                    for serverConfig in config.iceServers {
                        let server = RTCIceServer(urlStrings: serverConfig.urls,
                                                  username: serverConfig.username,
                                                  credential: serverConfig.credential)
                        peerConfig.iceServers = [server]
                    }
                    
                    conn.eventLog.markFormat(type: .Signaling, format: "set configuration")
                    if !peerConnContext.peerConn.setConfiguration(peerConfig) {
                        print("failed setting configuration sent by offer")
                        conn.eventLog.markFormat(type: .Signaling,
                                                 format: "setting configuration failed")
                        onConnectedHandler?(ConnectionError.failureSetConfiguration(peerConfig))
                        state = .ready
                        return
                    }
                }
                
                state = .peerOffered
                let sdp = offer.sessionDescription()
                conn.eventLog.markFormat(type: .Signaling, format: "set remote description")
                peerConnContext.peerConn.setRemoteDescription(sdp) {
                    (error: Error?) in
                    if let error = error {
                        self.conn.eventLog.markFormat(type: .Signaling,
                                                      format: "setting remote description failed")
                        self.conn.onFailedHandler?(ConnectionError.peerConnectionError(error))
                        return
                    }
                    
                    print("create answer")
                    self.conn.eventLog.markFormat(type: .Signaling,
                                                  format: "create answer")
                    self.state = .peerAnswering
                    self.peerConnContext.peerConn.answer(for: self.peerConnContext.mediaOption.answerMediaConstraints) {
                        (sdp, error) in
                        if let error = error {
                            self.conn.eventLog.markFormat(type: .Signaling,
                                                          format: "creating answer failed")
                            self.conn.onFailedHandler?(ConnectionError.peerConnectionError(error))
                            return
                        }
                        print("generate answer: ", sdp)
                        self.conn.eventLog.markFormat(type: .Signaling,
                                                      format: "generated answer: %@",
                                                      arguments: sdp!)
                        
                        print("set local description")
                        self.conn.eventLog.markFormat(type: .Signaling,
                                                      format: "set local description")
                        self.peerConnContext.peerConn.setLocalDescription(sdp!) {
                            (error) in
                            if let error = error {
                                self.conn.eventLog.markFormat(type: .Signaling,
                                                              format: "failed setting local description")
                                self.conn.onFailedHandler?(ConnectionError.peerConnectionError(error))
                                return
                            }
                            
                            print("send answer")
                            self.conn.eventLog.markFormat(type: .Signaling,
                                                          format: "send answer")
                            let answer = SignalingAnswer(sdp: sdp!.sdp)
                            self.send(answer)
                        }
                    }
                }
            default:
                return
            }
        }
    }
    
    func webSocket(_ webSocket: SRWebSocket!, didCloseWithCode code: Int, reason: String!, wasClean: Bool) {
        print("webSocket:didCloseWithCode:", code)
        conn.eventLog.markFormat(type: .WebSocket,
                                 format: "close: code \(code), reason %@, clean \(wasClean)",
                                 arguments: reason)
        switch state {
        case .connecting:
            onConnectedHandler?(nil)
        case .disconnecting:
            onDisconnectedHandler?(nil)
        default:
            break
        }
    }
    
}

class PeerConnectionContext: NSObject, RTCPeerConnectionDelegate {
    
    var connContext: ConnectionContext
    var factory: RTCPeerConnectionFactory
    var peerConn: RTCPeerConnection!
    var downstream: RTCMediaStream?
    var mediaOption: MediaOption
    var onConnectedHandler: ((RTCPeerConnection?, RTCMediaStream?, Error?) -> Void)
    
    var eventLog: EventLog { get { return connContext.conn.eventLog } }
    
    init(connContext: ConnectionContext,
         factory: RTCPeerConnectionFactory,
         mediaOption: MediaOption,
         handler: @escaping ((RTCPeerConnection?, RTCMediaStream?, Error?) -> Void))
    {
        self.connContext = connContext
        self.factory = factory
        self.mediaOption = mediaOption
        onConnectedHandler = handler
    }
    
    func createPeerConnection() {
        eventLog.markFormat(type: .PeerConnection, format: "create peer connection")
        peerConn = factory.peerConnection(
            with: mediaOption.configuration,
            constraints: mediaOption.mediaConstraints,
            delegate: self)
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
        if downstream != nil {
            peerConnection.close()
            onConnectedHandler(nil, nil, ConnectionError.multipleDownstreams)
            return
        }
        downstream = stream
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didRemove stream: RTCMediaStream) {
        print("peerConnection:didRemoveStream:")
        eventLog.markFormat(type: .PeerConnection, format: "removed stream")
        if downstream == stream {
            downstream = nil
        }
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
        case .connected:
            print("ice connection connected")
            connContext.state = .ready
            onConnectedHandler(peerConnection, downstream, nil)
        case .disconnected:
            print("ice connection disconnected")
            connContext.state = .disconnected
            connContext.conn.onDisconnectedHandler?()
        case .failed:
            print("ice connection failed")
            connContext.state = .disconnected
            connContext.conn.onFailedHandler?(.iceConnectionFailed)
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
        connContext.send(SignalingICECandidate(candidate: candidate.sdp))
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
