import Foundation
import WebRTC

public struct MediaStream {
    
    public var peerConnection: RTCPeerConnection!
    public var mediaOption: MediaOption
    public var creationTime: NSDate
    public var channelId: String
    public var clientId: String?
    public var role: Role
    
    var context: MediaStreamContext!
    
    init(peerConnection: RTCPeerConnection, role: Role, channelId: String,
         mediaOption: MediaOption = MediaOption()) {
        self.peerConnection = peerConnection
        self.role = role
        self.channelId = channelId
        self.mediaOption = mediaOption
        creationTime = NSDate()
    }
    
    mutating func config() {
        context = MediaStreamContext(stream: self)
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

// deprecated?
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
    
    var onConnectedHandler: ((Error?) -> ())?
    var onDisconnectedHandler: ((Error?) -> ())?
    
    init(stream: MediaStream) {
        self.stream = stream
    }
    
    func connect(handler: ((Error?) -> ())) {
        // TODO:
        onConnectedHandler = handler
        
        // "connect"
        /*
        stream.connection.createMediaStream(stream.role, channelId: stream.channelId) { (stream, error) in
            // TODO:
        }
 */
        
    }
    
}