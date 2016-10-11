import Foundation
import WebRTC

public protocol VideoRenderer {
    
    func onChangedSize(_ size: CGSize)
    func renderVideoFrame(_ videoFrame: VideoFrame?)
    
}

class VideoRendererSupport: NSObject, RTCVideoRenderer {
    
    var videoRenderer: VideoRenderer
    
    init(videoRenderer: VideoRenderer) {
        self.videoRenderer = videoRenderer
    }
    
    func setSize(_ size: CGSize) {
        videoRenderer.onChangedSize(size)
    }
    
    func renderFrame(_ frame: RTCVideoFrame?) {
        if let frame = frame {
            let frame = RemoteVideoFrame(nativeVideoFrame: frame)
            videoRenderer.renderVideoFrame(frame)
        } else {
            videoRenderer.renderVideoFrame(nil)
        }
    }
    
}

open class VideoView: UIView, VideoRenderer {

    lazy var remoteVideoView: RTCEAGLVideoView = {
        let view = RTCEAGLVideoView(frame: self.frame)
        self.addSubview(view)
        self.setNeedsDisplay()
        return view
    }()
    
    open func onChangedSize(_ size: CGSize) {
        remoteVideoView.setSize(size)
    }
    
    open func renderVideoFrame(_ frame: VideoFrame?) {
        if let frame = frame {
            if let handle = frame.videoFrameHandle {
                switch handle {
                case .webRTC(let frame):
                    remoteVideoView.renderFrame(frame)
                }
            }
        } else {
            remoteVideoView.renderFrame(nil)
        }
    }

    open override func draw(_ frame: CGRect) {
        super.draw(frame)
        remoteVideoView.draw(frame)
    }
    
}
