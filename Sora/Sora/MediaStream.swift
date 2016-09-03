import Foundation
import WebRTC

public struct MediaStream {
    
    public var peerConnection: RTCPeerConnection?
    public var nativeMediaStream: RTCMediaStream?
    public var connection: Connection
    public var option: MediaOption
    public var creationTime: NSDate
    public var channelId: String
    public var clientId: String?
    public var role: Role
    
    var context: MediaStreamContext!
    
    init(connection: Connection, role: Role, channelId: String,
         option: MediaOption = MediaOption()) {
        self.connection = connection
        self.role = role
        self.channelId = channelId
        self.option = option
        creationTime = NSDate()
    }
    
    mutating func config() {
        context = MediaStreamContext(stream: self)
    }
    
    func connect(handler: (MediaStream?, Error?) -> ()) {
        context.connect(self, handler: handler)
    }
    
    public func disconnect() {
        // TODO:
    }
    
    // MARK: イベントハンドラ
    
    var onConnectedHandler: ((MediaStream?, Error?) -> ())?
    var onDisconnectedHandler: ((MediaStream?, Error?) -> ())?
    
    public mutating func onDisconnected(handler: ((MediaStream?, Error?) -> ())) {
        onDisconnectedHandler = handler
    }
    
}

class MediaStreamContext {
    
    enum State {
        case Connecting
        case Connected
        case Disconnecting
        case Disconnected
    }
    
    var stream: MediaStream
    var state: State = .Disconnected
    var conn: Connection!
    
    var onConnectedHandler: ((MediaStream?, Error?) -> ())?
    var onDisconnectedHandler: ((MediaStream?, Error?) -> ())?
    
    init(stream: MediaStream) {
        self.stream = stream
    }
    
    func connect(stream: MediaStream, handler: ((MediaStream?, Error?) -> ())) {
        // TODO:
        self.stream = stream
        onConnectedHandler = handler
        
        // "connect"
        stream.connection.connectMediaStream(stream.role, channelId: stream.channelId) { (conn, stream, error) in
            // TODO:
        }
        
    }
    
}