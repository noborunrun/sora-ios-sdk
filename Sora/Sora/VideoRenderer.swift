import Foundation
import WebRTC

public protocol VideoRenderer {
    
    func onChangedSize(_ size: CGSize)
    func render(videoFrame: VideoFrame?)
    func render(snapshot: Snapshot)
    
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
                self.videoRenderer.render(videoFrame: frame)
            } else {
                self.videoRenderer.render(videoFrame: nil)
            }
        }
    }
    
    func render(snapshot: Snapshot) {
        DispatchQueue.main.async {
            self.videoRenderer.render(snapshot: snapshot)
        }
    }
    
}
