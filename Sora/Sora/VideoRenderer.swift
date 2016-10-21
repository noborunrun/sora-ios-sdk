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

public class VideoView: UIView, VideoRenderer {

    lazy var remoteVideoView: RTCEAGLVideoView = {
        let view = RTCEAGLVideoView(frame: CGRect(x: 0, y: 0,
                                                  width: self.frame.width,
                                                  height: self.frame.height))
        self.addSubview(view)
        self.setNeedsDisplay()
        return view
    }()
    
    public func onChangedSize(_ size: CGSize) {
        remoteVideoView.setSize(size)
        self.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
    }
    
    public func renderVideoFrame(_ frame: VideoFrame?) {
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

    public override func draw(_ frame: CGRect) {
        super.draw(frame)
        remoteVideoView.draw(frame)
    }
    
}
