import Foundation

public struct SignalingConnected {
    public var role: Role
    public var clientId: String
    public var channelId: String
    public var channelConnections: Int
    public var upstreamConnections: Int
    public var downstreamConnections: Int
}

public struct SignalingCompleted {
    public var role: Role
    public var clientId: String
    public var channelId: String
}

public struct SignalingDisconnected {
    public var role: Role
    public var clientId: String
    public var channelId: String
    public var channelConnections: Int
    public var upstreamConnections: Int
    public var downstreamConnections: Int
}

public struct SignalingFailed {
    public var clientId: String
    public var channelId: String
    public var error: Error
}

public struct ArchiveFinished {
    public var clientId: String
    public var channelId: String
    public var filePath: String
    public var fileName: String
    public var size: Int
    public var videoCodec: VideoCodec
    public var audioCodec: AudioCodec
}

public struct ArchiveFailed {
    
    public var clientId: String
    public var channelId: String
    public var error: Error
    
}