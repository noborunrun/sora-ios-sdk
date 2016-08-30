import Foundation

public struct APIOperator {
    
    public struct Connection {
        public var clientId: String
        public var channelId: String
        public var role: Role
    }
    
    public struct Recording {
        public var channelId: String
        public var elapsedSeconds: Int
        public var videoCodec: VideoCodec
        public var audioCodec: AudioCodec?
    }
    
    public var URL: NSURL
    
    // DisconnectChannel, Disconnect
    public func disconnectChannels(clientId: String?,
                                   channelId: String,
                                   handler: ((Error?) -> ())) {
        // TODO:
    }
    
    // ListAllConnections, ListConnections
    public func getConnections(channelId: String?,
                               handler: (([Connection], Error?) -> ())) {
        // TODO:
    }
    
    // PushChannel, PushClient, PushUpstream/Downstream
    public func sendPush(clientId: String?, channelId: String, role: Role?, data: Data,
                         handler: ((Error?) -> ())) {
        // TODO:
    }
    
    // StartRecording
    public func startRecording(handler: (Error?) -> ()) {
        // TODO:
    }
    
    // StopRecording
    public func stopRecording(handler: (Error?) -> ()) {
        // TODO:
    }
    
    // ListRecording
    public func getRecordings(handler: ([Recording], Error?) -> ()) {
        // TODO:
    }
    
}