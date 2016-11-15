import Foundation
import WebRTC
import SocketRocket

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
            context = MediaStreamContext(mediaStream: self)
            context!.connect(handler: handler)
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
            creationTime = nil
            videoRendererSupport = nil
            context?.disconnect(handler: handler)
        }
    }
    
    func send(message: Message) -> ConnectionError? {
        switch state {
        case .connected:
            return context!.send(message)
        case .disconnected:
            return ConnectionError.connectionDisconnected
        default:
            return ConnectionError.connectionBusy
        }
    }
    
    func send(messageable: Messageable) -> ConnectionError? {
        return send(message: messageable.message())
    }
    
    // MARK: 統計情報
    
    public func statisticsReports(level: StatisticsReport.Level)
        -> ([StatisticsReport], [StatisticsReport])
    {
        if !isAvailable {
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
    
}

class MediaStreamContext: NSObject, SRWebSocketDelegate, RTCPeerConnectionDelegate {
    
    enum State {
        case signalingConnecting
        case signalingConnected
        case peerConnectionOffered
        case peerConnectionAnswering
        case peerConnectionAnswered
        case peerConnectionConnecting
        case connected
        case disconnecting
        case disconnected
    }
    
    weak var mediaStream: MediaStream!
    var webSocket: SRWebSocket?
    var state: State = .disconnected
    var peerConnFactory: RTCPeerConnectionFactory
    var peerConn: RTCPeerConnection!
    var upstream: RTCMediaStream?
    var mediaCapturer: MediaCapturer?
    
    var onConnectHandler: ((ConnectionError?) -> Void)?
    var onDisconnectHandler: ((ConnectionError?) -> Void)?
    var onSentHandler: ((ConnectionError?) -> Void)?
    
    var connection: Connection {
        get { return mediaStream.connection }
    }
    
    var eventLog: EventLog {
        get { return mediaStream.connection.eventLog }
    }
    
    var mediaConnection: MediaConnection {
        get { return mediaStream.mediaConnection }
    }
        
    init(mediaStream: MediaStream) {
        self.mediaStream = mediaStream
        peerConnFactory = RTCPeerConnectionFactory()
    }
    
    func connect(handler: @escaping ((ConnectionError?) -> Void)) {
        if state != .disconnected {
            handler(ConnectionError.connectionBusy)
            return
        }
        
        eventLog.mark(event:
            Event(type: .WebSocket,
                  comment: String(format: "open %@", connection.URL.description)))
        state = .signalingConnecting
        onConnectHandler = handler
        webSocket = SRWebSocket(url: connection.URL)
        webSocket!.delegate = self
        webSocket!.open()
    }
    
    func disconnect(handler: @escaping ((ConnectionError?) -> Void)) {
        switch state {
        case .disconnected:
            handler(ConnectionError.connectionDisconnected)
        case .signalingConnected,.connected:
            state = .disconnecting
            onDisconnectHandler = handler
            webSocket!.close()
        default:
            handler(ConnectionError.connectionBusy)
        }
    }
    
    func send(_ message: Message) -> ConnectionError? {
        switch state {
        case .disconnected:
            return ConnectionError.connectionDisconnected
        case .connected:
            let j = message.JSON()
            let data = try! JSONSerialization.data(withJSONObject: j,
                                                   options:
                JSONSerialization.WritingOptions(rawValue: 0))
            let msg = NSString(data: data,
                               encoding: String.Encoding.utf8.rawValue) as String!
            print("WebSocket send ", j)
            eventLog.markFormat(type: .WebSocket,
                                format: "send message: %@",
                                arguments: msg!)
            webSocket!.send(msg)
            return nil
        default:
            return ConnectionError.connectionBusy
        }
    }
    
    func send(_ messageable: Messageable) -> ConnectionError? {
        return self.send(messageable.message())
    }
    
    // TODO: deprecated
    
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
        eventLog.markFormat(type: .Signaling,
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
            peerConnContext.peerconnection.add(upstream!)
        }
    }
    
    // MARK: SRWebSocketDelegate
    
    var webSocketEventHandlers: WebSocketEventHandlers? {
        get { return mediaConnection.webSocketEventHandlers }
    }
    
    var signalingEventHandlers: SignalingEventHandlers? {
        get { return mediaConnection.signalingEventHandlers }
    }
    
    var peerConnectionEventHandlers: PeerConnectionEventHandlers? {
        get { return mediaConnection.peerConnectionEventHandlers }
    }
    
    func webSocketDidOpen(_ webSocket: SRWebSocket!) {
        eventLog.markFormat(type: .WebSocket, format: "opened")
        state = .signalingConnected
        webSocketEventHandlers?.onOpenHandler?(webSocket)
        signalingEventHandlers?.onConnectHandler?()
    }
    
    public func webSocket(_ webSocket: SRWebSocket!,
                          didCloseWithCode code: Int,
                          reason: String!,
                          wasClean: Bool) {
        print("webSocket:didCloseWithCode:", code)
        eventLog.markFormat(type: .WebSocket,
                            format: "close: code \(code), reason %@, clean \(wasClean)",
            arguments: reason)
        webSocketEventHandlers?.onCloseHandler?(webSocket, code, reason, wasClean)
        signalingEventHandlers?.onDisconnectHandler?()
        
        if state == .disconnecting {
            state = .disconnected
            onDisconnectHandler?(nil)
        } else if state != .disconnecting {
            state = .disconnected
            onDisconnectHandler?(ConnectionError.webSocketClose(code, reason))
        }
    }
    
    func webSocket(_ webSocket: SRWebSocket!, didFailWithError error: Error!) {
        print("webSocket:didFailWithError:")
        state = .disconnected
        mediaConnection.state = .disconnected
        eventLog.markFormat(type: .WebSocket,
                            format: "fail: %@",
                            arguments: error.localizedDescription)
        webSocketEventHandlers?.onFailureHandler?(webSocket, error)
        
        let connError = ConnectionError.webSocketError(error)
        self.webSocket = nil
        mediaConnection.onFailureHandler?(connError)
        onDisconnectHandler?(connError)
    }
    
    func webSocket(_ webSocket: SRWebSocket!, didReceivePong pongPayload: Data!) {
        eventLog.markFormat(type: .WebSocket,
                                 format: "received pong: %@",
                                 arguments: pongPayload.description)
        webSocketEventHandlers?.onPongHandler?(webSocket, pongPayload)
    }
    
    func webSocket(_ webSocket: SRWebSocket!, didReceiveMessage message: Any!) {
        print("webSocket:didReceiveMessage:", message)
        eventLog.markFormat(type: .WebSocket,
                            format: "received message: %@",
                            arguments: (message as AnyObject).description)
        
        if message is Data {
            // discard
            return
        }
        
        webSocketEventHandlers?.onMessageHandler?(webSocket, message as! String)
        
        if let message = Message.fromJSONData(message) {
            signalingEventHandlers?.onReceiveHandler?(message)

            let json = message.JSON()
            print("received message type: ", message.type)
            switch message.type {
            case .ping?:
                eventLog.markFormat(type: .Signaling, format: "received ping")
                signalingEventHandlers?.onPingHandler?()
                let pong = SignalingPong()
                self.send(pong)
                
            case .stats?:
                var stats: Statistics!
                do {
                    stats = Optional.some(try unbox(dictionary: json))
                } catch {
                    eventLog.markFormat(type: .Signaling,
                                             format: "failed parsing stats: %@",
                                             arguments: json.description)
                }
                
                var buf = "received statistics"
                if let n = stats.numberOfDownstreamConnections {
                    buf = buf.appendingFormat(": downstreams=%d", n)
                }
                eventLog.markFormat(type: .Signaling, format: buf)
                
                connection.onStatisticsHandler?(stats)
                
            case .notify?:
                var notify: SignalingNotify!
                do {
                    notify = Optional.some(try unbox(dictionary: json))
                } catch {
                    eventLog.markFormat(type: .Signaling,
                                             format: "failed parsing notify: %@",
                                             arguments: json.description)
                }
                
                eventLog.markFormat(type: .Signaling, format: "received notify: %@",
                                         arguments: notify.notifyMessage)
                
                connection.onNotifyHandler?(notify.notifyMessage)
                
            case .offer?:
                eventLog.markFormat(type: .Signaling, format: "received offer")
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
                    
                    eventLog.markFormat(type: .Signaling, format: "set configuration")
                    if !peerConnContext.peerconnection.setConfiguration(peerConfig) {
                        print("failed setting configuration sent by offer")
                        eventLog.markFormat(type: .Signaling,
                                                 format: "setting configuration failed")
                        onConnectHandler?(ConnectionError.failureSetConfiguration(peerConfig))
                        state = .ready
                        return
                    }
                }
                
                state = .peerOffered
                let sdp = offer.sessionDescription()
                eventLog.markFormat(type: .Signaling, format: "set remote description")
                peerConnContext.peerconnection.setRemoteDescription(sdp) {
                    (error: Error?) in
                    if let error = error {
                        self.eventLog.markFormat(type: .Signaling,
                                                      format: "setting remote description failed")
                        self.connection.onFailedHandler?(ConnectionError.peerConnectionError(error))
                        return
                    }
                    
                    print("create answer")
                    self.eventLog.markFormat(type: .Signaling,
                                                  format: "create answer")
                    self.state = .peerAnswering
                    self.peerConnContext.peerconnection.answer(for: self.peerConnContext.mediaOption.answerMediaConstraints) {
                        (sdp, error) in
                        if let error = error {
                            self.eventLog.markFormat(type: .Signaling,
                                                          format: "creating answer failed")
                            self.connection.onFailedHandler?(ConnectionError.peerConnectionError(error))
                            return
                        }
                        print("generate answer: ", sdp)
                        self.eventLog.markFormat(type: .Signaling,
                                                      format: "generated answer: %@",
                                                      arguments: sdp!)
                        
                        print("set local description")
                        self.eventLog.markFormat(type: .Signaling,
                                                      format: "set local description")
                        self.peerConnContext.peerconnection.setLocalDescription(sdp!) {
                            (error) in
                            if let error = error {
                                self.eventLog.markFormat(type: .Signaling,
                                                              format: "failed setting local description")
                                self.connection.onFailedHandler?(ConnectionError.peerConnectionError(error))
                                return
                            }
                            
                            print("send answer")
                            self.eventLog.markFormat(type: .Signaling,
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
    
    // MARK: RTCPeerConnectionDelegate
    
    var downstream: RTCMediaStream?
    var mediaOption: MediaOption
    var onConnectHandler: ((RTCPeerConnection?, RTCMediaStream?, Error?) -> Void)
    
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
            onConnectHandler(nil, nil, ConnectionError.multipleDownstreams)
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
            onConnectHandler(peerConnection, downstream, nil)
        case .disconnected:
            print("ice connection disconnected")
            connContext.state = .disconnected
            connContext.connection.onDisconnectHandler?()
        case .failed:
            print("ice connection failed")
            connContext.state = .disconnected
            connContext.connection.onFailedHandler?(.iceConnectionFailed)
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
