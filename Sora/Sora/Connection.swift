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
    case connectionWaitTimeout
    case connectionDisconnected
    case connectionBusy
    case multipleDownstreams
    case webSocketClose(Int, String)
    case webSocketError(Error)
    case peerConnectionError(Error)
    case iceConnectionFailed
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
    
    // TODO: deprecated
    
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
    
}
