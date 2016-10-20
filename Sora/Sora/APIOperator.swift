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
    
    public var URL: Foundation.URL
    
    // DisconnectChannel, Disconnect
    public func disconnectChannels(_ clientId: String?,
                                   channelId: String,
                                   handler: ((ConnectionError?) -> Void)) {
        // TODO:
    }
    
    // ListAllConnections, ListConnections
    public func getConnections(_ channelId: String?,
                               handler: (([Connection], Error?) -> Void)) {
        // TODO:
    }
    
    // PushChannel, PushClient, PushUpstream/Downstream
    public func sendPush(_ clientId: String?, channelId: String, role: Role?, message: Message,
                         handler: ((ConnectionError?) -> Void)) {
        // TODO:
    }
    
    // StartRecording
    public func startRecording(_ handler: (ConnectionError?) -> Void) {
        // TODO:
    }
    
    // StopRecording
    public func stopRecording(_ handler: (ConnectionError?) -> Void) {
        // TODO:
    }
    
    // ListRecording
    public func getRecordings(_ handler: ([Recording], Error?) -> Void) {
        // TODO:
    }
    
}
