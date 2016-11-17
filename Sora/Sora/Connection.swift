import Foundation
import WebRTC
import SocketRocket
import UIKit

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
    case connectionWaitTimeout
    case connectionDisconnected
    case connectionTerminated
    case connectionBusy
    case multipleDownstreams
    case webSocketClose(Int, String)
    case webSocketError(Error)
    case peerConnectionError(Error)
    case iceConnectionFailed
    case iceConnectionDisconnected
    case mediaCapturerFailed
}

public class Connection {
    
    public var URL: Foundation.URL
    public var mediaChannels: [MediaChannel] = []
    public var eventLog: EventLog = EventLog()
    
    public init(URL: Foundation.URL) {
        self.URL = URL
    }

    public func createMediaChannel(mediaChannelId: String) -> MediaChannel {
        let channel = MediaChannel(connection: self, mediaChannelId: mediaChannelId)
        mediaChannels.append(channel)
        return channel
    }
    
}
