import Foundation
import WebRTC

public protocol VideoRenderer {
    
    func onChangedSize(_ size: CGSize)
    func renderVideoFrame(_ videoFrame: VideoFrame?)
    
}

class VideoRendererAdapter: NSObject, RTCVideoRenderer {
    
    weak var connection: Connection?
    var videoRenderer: VideoRenderer
    
    var eventLog: EventLog? {
        get { return connection?.eventLog }
    }
    
    init(videoRenderer: VideoRenderer) {
        self.videoRenderer = videoRenderer
    }
    
    func setSize(_ size: CGSize) {
        eventLog?.markFormat(type: .VideoRenderer,
                             format: "set size %@ for %@",
                             arguments: size.debugDescription, self)
        DispatchQueue.main.async {
            self.videoRenderer.onChangedSize(size)
        }
    }
    
    func renderFrame(_ frame: RTCVideoFrame?) {
        DispatchQueue.main.async {
            if let frame = frame {
                let frame = RemoteVideoFrame(nativeVideoFrame: frame)
                self.videoRenderer.renderVideoFrame(frame)
            } else {
                self.videoRenderer.renderVideoFrame(nil)
            }
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
