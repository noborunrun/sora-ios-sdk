import Foundation
import SwiftyJSON
import Result

/// States of connections.
public enum State {
    /// The connection is trying to connect to a server.
    case Connecting
    
    /// The connection is open.
    case Open
    
    /// The connection is trying to disconnect form the server.
    case Closing
    
    /// The connection is closed.
    case Closed
}

/// Connection error.
public struct Error {
    
    /// Error types.
    public enum Type: ErrorType {
        
        /// Represents that a server respond "UNKNOWN-TYPE" error.
        case UnknownTypeError
        
        /// Represents that a WebSocket stream has any error.
        /// The "error" parameter is a NSError object received from SRWebSocket.
        case WebSocketError(error: NSError)
    }
    
    /// Kind of error types.
    public var type: Type
    
}

/// A request to connect to a sevre.
public struct Request {
    
    public enum Role: String {
        case Upstream = "upstream"
        case Downstream = "downstream"
    }
    
    public enum CodecType: String {
        case VP8 = "VP8"
        case VP9 = "VP9"
        case H264 = "H264"
    }
    
    public var role: Role
    public var channelId: String
    public var accessToken: String?
    public var codecType: CodecType?
    
    public init(role: Role, channelId: String) {
        self.role = role
        self.channelId = channelId
    }
    
    /// Returns a JSON representation.
    func JSONValue() -> JSON {
        var json : [String: AnyObject] = [
            "type": "connect", "channelId": self.channelId]
        switch self.role {
        case .Upstream:
            json["role"] = "upstream"
        case .Downstream:
            json["role"] = "downstream"
        }
        if let tok = self.accessToken {
            json["accessToken"] = tok
        }
        if self.codecType != nil {
            json["video"] = ["codecType": self.codecType!.rawValue]
        }
        return JSON(json)
    }
    
}

/// An offer message from a server.
public struct Offer {
    
    /// Client ID.
    public var clientId: String
    
    //public var metadata: Dictionary
    
    /// SDP message.
    public var SDPMessage: String
    
    public init(clientId: String, SDPMessage: String) {
        self.clientId = clientId
        self.SDPMessage = SDPMessage
    }
    
}

/** Description */
public struct Connection {
    
    /// The Sora server URL. For example, "ws://127.0.0.1:5000/signaling".
    public var URL: NSURL
    
    var webSocket: SRWebSocket?
    var session: Session?
    
    /// The state of the connection.
    public var state: State
    
    /// Called when the connection receives a WebSocket message.
    public var didReceiveMessage: ((connection:Connection, message:String) -> ())!
    
    /// Called when the connection opened.
    public var didOpen: ((connection:Connection) -> ())!
    
    /// Called when the connection closed.
    public var didClose: ((connection:Connection, code:Int, reason:String) -> ())!
    
    /// Called when the connection fails any operations.
    public var didFail: ((connection:Connection, error:Error) -> ())!
    
    /// Initializes the connection.
    ///
    /// - parameter URL: A server's URL to connect.
    public init(URL: NSURL) {
        self.URL = URL
        self.state = State.Closed
    }
    
    /// Connects to the server.
    ///
    /// - parameter request: A request for the server.
    /// - parameter handle: A function handles an offer message sent from the server when the connecting is successed.
    public mutating func connect(request: Request, handle: (Offer) -> ()) {
        print("connecting...")
        self.state = State.Connecting
        self.session = Session(connection: self, request: request, handle: handle)
        self.webSocket = SRWebSocket(URL: self.URL)
        self.webSocket!.delegate = self.session
        self.webSocket!.open()
    }
    
    /*
     /// Sends a request message to the server.
     public mutating func send(request: Request) {
     // create JSON string
     print("JSON = %s", request.JSONString())
     }
     */
    
    /// Disconnects from the server.
    public mutating func close() {
        self.webSocket!.close()
    }
    
    func fail(error: Error) {
        print("Connection.fail ", error)
        if let f = self.didFail {
            f(connection: self, error: error)
        }
    }
}

class Session: NSObject, SRWebSocketDelegate {
    
    var connection: Connection
    var request: Request
    var handle: (Offer) -> ()
    
    init(connection: Connection, request: Request, handle: (Offer) -> ()) {
        self.connection = connection
        self.request = request
        self.handle = handle
    }
    
    func webSocket(webSocket: SRWebSocket!, didReceiveMessage message: AnyObject!) {
        print("MESSAGE: \(message)")
        if let msg = message {
            // TODO: parse offer message
            let jsonData = (msg as! String).dataUsingEncoding(NSUTF8StringEncoding)!
            let json = JSON(data: jsonData)
            let offer = Offer(clientId: json["clientId"].stringValue,
                              SDPMessage: json["sdp"].stringValue)
            self.handle(offer)
        }
    }
    
    func webSocketDidOpen(webSocket: SRWebSocket!) {
        print("opened!")
        self.connection.state = .Open
        if let f = self.connection.didOpen {
            f(connection: self.connection)
        }
        let msg = self.request.JSONValue().description
        print("send ", msg)
        webSocket!.send(msg)
    }
    
    func webSocket(webSocket: SRWebSocket!, didCloseWithCode code: Int, reason: String!, wasClean: Bool) {
        print("close with code ", reason)
        if reason != nil {
            let json = JSON.parse(reason!)
            if json["type"] == "error" && json["reason"] == "UNKNOWN-TYPE" {
                self.connection.fail(Error(type: .UnknownTypeError))
            }
        }
        if let f = self.connection.didClose {
            f(connection: self.connection, code: code, reason: reason)
        }
    }
    
    func webSocket(webSocket: SRWebSocket!, didFailWithError error: NSError!) {
        print("error!")
        self.connection.fail(Error(type: .WebSocketError(error: error)))
    }
    
}
