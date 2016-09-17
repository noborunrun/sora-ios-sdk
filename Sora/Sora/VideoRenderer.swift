import Foundation
import WebRTC

public protocol VideoRenderer {
    
    func onChangedSize(size: CGSize)
    func renderVideoFrame(videoFrame: VideoFrame) -> ()
    
}


class VideoRendererSupport: NSObject, RTCVideoRenderer {
    
    var videoRenderer: VideoRenderer
    var trackId: String?
    
    init(videoRenderer: VideoRenderer, trackId: String?) {
        self.videoRenderer = videoRenderer
        self.trackId = trackId
    }
    
    func setSize(size: CGSize) {
        videoRenderer.onChangedSize(size)
    }
    
    func renderFrame(frame: RTCVideoFrame?) {
        if let frame = frame {
            let frame = VideoFrame(nativeVideoFrame: frame)
            videoRenderer.renderVideoFrame(frame)
        }
    }
    
}

public struct VideoFrame {
    
    public var width: Int {
        get { return nativeVideoFrame.width }
    }
    
    public var height: Int {
        get { return nativeVideoFrame.height }
    }
    
    public var timestamp: CMTime {
        get { return CMTimeMake(nativeVideoFrame.timeStamp, 1000000000) }
    }
    
    public var yPlane: UInt8 {
        get { return nativeVideoFrame.yPlane.memory }
    }
    
    public var uPlane: UInt8 {
        get { return nativeVideoFrame.uPlane.memory }
    }
    
    public var vPlane: UInt8 {
        get { return nativeVideoFrame.vPlane.memory }
    }
    
    public var yPitch: Int32 {
        get { return nativeVideoFrame.yPitch }
    }

    public var uPitch: Int32 {
        get { return nativeVideoFrame.uPitch }
    }

    public var vPitch: Int32 {
        get { return nativeVideoFrame.vPitch }
    }

    public var nativeVideoFrame: RTCVideoFrame
    
    init(nativeVideoFrame: RTCVideoFrame) {
        self.nativeVideoFrame = nativeVideoFrame
    }
    
}

public class VideoView: UIView, VideoRenderer {

    lazy var nativeVideoView: RTCEAGLVideoView = {
        let view = RTCEAGLVideoView(frame: self.frame)
        self.addSubview(view)
        return view
    }()
    
    public func onChangedSize(size: CGSize) {
        nativeVideoView.setSize(size)
    }
    
    public func renderVideoFrame(frame: VideoFrame) {
        nativeVideoView.renderFrame(frame.nativeVideoFrame)
    }

}
