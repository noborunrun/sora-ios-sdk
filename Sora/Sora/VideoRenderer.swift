import Foundation
import WebRTC

public protocol VideoRenderer {
    
    func onChangedSize(size: CGSize)
    func renderVideoFrame(videoFrame: VideoFrame?)
    
}

class VideoRendererSupport: NSObject, RTCVideoRenderer {
    
    var videoRenderer: VideoRenderer
    
    init(videoRenderer: VideoRenderer) {
        self.videoRenderer = videoRenderer
    }
    
    func setSize(size: CGSize) {
        videoRenderer.onChangedSize(size)
    }
    
    func renderFrame(frame: RTCVideoFrame?) {
        if let frame = frame {
            let frame = RemoteVideoFrame(nativeVideoFrame: frame)
            videoRenderer.renderVideoFrame(frame)
        } else {
            videoRenderer.renderVideoFrame(nil)
        }
    }
    
}

public class VideoView: UIView, VideoRenderer {

    lazy var remoteVideoView: RTCEAGLVideoView = {
        let view = RTCEAGLVideoView(frame: self.frame)
        self.addSubview(view)
        self.setNeedsDisplay()
        return view
    }()
    
    public func onChangedSize(size: CGSize) {
        remoteVideoView.setSize(size)
    }
    
    public func renderVideoFrame(frame: VideoFrame?) {
        if let frame = frame {
            if let handle = frame.videoFrameHandle {
                switch handle {
                case .WebRTC(let frame):
                    remoteVideoView.renderFrame(frame)
                }
            }
        } else {
            remoteVideoView.renderFrame(nil)
        }
    }

    public override func drawRect(frame: CGRect) {
        super.drawRect(frame)
        remoteVideoView.drawRect(frame)
    }
    
}