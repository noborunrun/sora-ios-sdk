import UIKit
import WebRTC

public class VideoView: UIView, VideoRenderer {
    
    // キーウィンドウ外で RTCEAGLVideoView を生成すると次のエラーが発生するため、
    // contentView を Nib ファイルでセットせずに遅延プロパティで初期化する
    // "Failed to bind EAGLDrawable: <CAEAGLLayer: ***> to GL_RENDERBUFFER 1"
    // ただし、このエラーは無視しても以降の描画に問題はなく、クラッシュもしない
    lazy var contentView: VideoViewContentView! = {
        guard let topLevel = Bundle(for: VideoView.self)
            .loadNibNamed("VideoView", owner: self, options: nil) else
        {
            assertionFailure("cannot load VideoView's nib file")
            return nil
        }
        
        let view: VideoViewContentView = topLevel[0] as! VideoViewContentView
        view.frame = self.bounds
        self.addSubview(view)
        if view.allowsRender {
            view.setNeedsDisplay()
        }
        return view
    }()

    override public init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    public func onChangedSize(_ size: CGSize) {
        contentView.onChangedSize(size)
    }
    
    public func renderVideoFrame(_ frame: VideoFrame?) {
        contentView.renderVideoFrame(frame)
    }
    
}

class VideoViewContentView: UIView, VideoRenderer {
    
    @IBOutlet weak var nativeVideoView: RTCEAGLVideoView!
    
    var allowsRender: Bool {
        get {
            // 前述のエラーはキーウィンドウ外での描画でも発生するので、
            // ビューがキーウィンドウに表示されている場合のみ描画を許可する
            return !(isHidden || window == nil || !window!.isKeyWindow)
        }
    }
    
    var sizeToChange: CGSize?
    
    public func onChangedSize(_ size: CGSize) {
        // ここも前述のエラーと同様の理由で処理を後回しにする
        if allowsRender {
            setRemoteVideoViewSize(size)
        } else {
            sizeToChange = size
        }
    }
    
    func setRemoteVideoViewSize(_ size: CGSize) {
        nativeVideoView.setSize(size)
        sizeToChange = nil
    }
    
    public func renderVideoFrame(_ frame: VideoFrame?) {
        guard allowsRender else { return }
        updateSize()
        
        if let frame = frame {
            if let handle = frame.videoFrameHandle {
                switch handle {
                case .webRTC(let frame):
                    nativeVideoView.renderFrame(frame)
                }
            }
        } else {
            nativeVideoView.renderFrame(nil)
        }
    }
    
    public override func draw(_ frame: CGRect) {
        super.draw(frame)
        nativeVideoView.draw(frame)
    }
    
    public override func didMoveToWindow() {
        // onChangedSize が呼ばれて RTCEAGLVideoView にサイズの変更がある場合、
        // このビューがウィンドウに表示されたタイミングでサイズの変更を行う
        // これも前述のエラーを回避するため
        updateSize()
    }
    
    func updateSize() {
        if let size = sizeToChange {
            if allowsRender {
                setRemoteVideoViewSize(size)
            }
        }
    }
    
}
