import Foundation
import WebRTC
import SocketRocket
import UIKit

public indirect enum ConnectionError: Error {
    case failureSetConfiguration(RTCConfiguration)
    case connectionWaitTimeout
    case connectionDisconnected
    case connectionTerminated
    case connectionBusy
    case webSocketClose(Int, String?)
    case webSocketError(Error)
    case peerConnectionError(Error)
    case iceConnectionFailed
    case iceConnectionDisconnected
    case mediaCapturerFailed
    case aggregateError([ConnectionError])
    case updateError(ConnectionError)
}

public class Connection {
    
    public var URL: Foundation.URL
    public var mediaChannelId: String
    public var eventLog: EventLog
    public var mediaPublisher: MediaPublisher!
    public var mediaSubscriber: MediaSubscriber!
    
    public init(URL: Foundation.URL, mediaChannelId: String) {
        self.URL = URL
        self.mediaChannelId = mediaChannelId
        eventLog = EventLog(URL: URL, mediaChannelId: mediaChannelId)
        mediaPublisher = MediaPublisher(connection: self)
        mediaSubscriber = MediaSubscriber(connection: self)
    }

}
