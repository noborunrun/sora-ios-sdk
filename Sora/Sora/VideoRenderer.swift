import Foundation

public protocol VideoRenderer {
    
    func renderVideoFrame(frame: VideoFrame) -> ()
    
}

public struct VideoFrame {
    
    public var videoFormat: VideoFormat
    
}

public struct VideoFormat {
    
    public var name: String
    public var frameWidth: Int
    public var frameHeight: Int
    
}

public struct VideoView: VideoRenderer {

    public func renderVideoFrame(frame: VideoFrame) -> () {
        // TODO:
    }

}