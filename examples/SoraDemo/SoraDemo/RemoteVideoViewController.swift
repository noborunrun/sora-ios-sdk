import UIKit

class RemoteVideoViewController: UIViewController {

    enum State {
        case Connecting
        case Open
        case Closed
    }
    
    @IBOutlet weak var remoteView: RTCEAGLVideoView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var URLField: UITextField!
    @IBOutlet weak var portField: UITextField!
    @IBOutlet weak var ChannelIdField: UITextField!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var connectingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var switchCameraButton: UIButton!
    
    var upstream: SoraConnection!
    var downstream: SoraConnection!
    var port: String!
    var state: State
    var touchedField: UITextField!
    var upstreamDelegate: UpstreamDelegate!
    var downstreamDelegate: DownstreamDelegate!
    var localVideoViewController: LocalVideoViewController!
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        self.state = .Closed
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.state = .Closed
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
        self.messageLabel.text = nil
        self.connectButton.setTitle("Connect", forState: UIControlState.Normal)
        self.connectingIndicator.stopAnimating()
        self.URLField.text = "192.168.0.1"
        self.ChannelIdField.text = "sora"
        self.portField.text = "5000"
        
        let numBar = UIToolbar(frame: CGRectMake(0, 0, 320, 50))
        numBar.barStyle = UIBarStyle.Default
        numBar.items = [
            UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(cancelPortField)),
        UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil),
        UIBarButtonItem(title: "Apply", style: UIBarButtonItemStyle.Done, target: self, action: #selector(applyPortField))]
        numBar.sizeToFit()
        self.portField.inputAccessoryView = numBar
        
        self.localVideoViewController = self.storyboard?.instantiateViewControllerWithIdentifier("LocalViedoViewController") as! LocalVideoViewController
        self.localVideoViewController?.remoteVideoViewController = self
        self.localVideoViewController?.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(keyboardWillBeShown(_:)),
                                                         name: UIKeyboardWillShowNotification,
                                                         object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(keyboardWillBeHidden(_:)),
                                                         name: UIKeyboardWillHideNotification,
                                                         object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self,
                                                            name: UIKeyboardWillShowNotification,
                                                            object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self,
                                                            name: UIKeyboardWillHideNotification,
                                                            object: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func connectOrDisconnect(sender: AnyObject) {
        NSLog("connectOrDisconnect")
        switch self.state {
        case .Connecting:
            // do nothing
            break
        case .Open:
            NSLog("try disconnect")
            self.state = .Closed
            self.connectButton.setTitle("Connect", forState: UIControlState.Normal)
            self.connectingIndicator.stopAnimating()
            self.downstream!.close()
            self.upstream!.close()
        case .Closed:
            NSLog("try connect")
            self.state = .Connecting
            self.connectButton.enabled = false
            self.connectButton.setTitle("Connecting...", forState: UIControlState.Normal)
            self.connectingIndicator.startAnimating()
            self.tryConnect()
        }
    }
    
    func tryConnect() {
        NSLog("try connect")
        print("URL = %@", self.URLField.text)
        print("ChannelId = %@", self.ChannelIdField.text)
        if self.URLField.text == "" {
            self.messageLabel.text = "Error: Input URL"
            return
        }
        
        if self.portField.text == "" {
            self.messageLabel.text = "Error: Input port number"
            return
        }
        
        if self.ChannelIdField.text == "" {
            self.messageLabel.text = "Error: Input channel ID"
            return
        }
        
        NSLog("create SoraConnection")
        let s = NSString.init(format: "ws://%@:%@/signaling",
                              self.URLField.text!, self.portField.text!) as String
        let URL = NSURL(string: s)!
        let channelId = self.ChannelIdField.text!
        
        // upstream
        self.upstream = SoraConnection(URL: URL)
        self.upstreamDelegate = UpstreamDelegate(viewController: self)
        self.upstream.delegate = self.upstreamDelegate
        let upstreamReq = SoraConnectRequest(role: SoraRole.Upstream, channelId: channelId, accessToken: nil)
        self.upstream.open(upstreamReq!)
        
        // downstream
        self.downstream = SoraConnection(URL: URL)
        self.downstreamDelegate = DownstreamDelegate(viewController: self)
        self.downstream.delegate = self.downstreamDelegate
        //self.remoteView!.setSize(CGSizeMake(320, 240))
        self.downstream.addRemoteVideoRenderer(self.remoteView!)
        
        let req = SoraConnectRequest(role: SoraRole.Downstream, channelId: channelId, accessToken: nil)
        self.downstream.open(req!)
    }
    
    func finishConnect() {
        self.state = .Open
        self.connectButton.setTitle("Disconnect", forState: UIControlState.Normal)
        self.connectButton.enabled = true
        self.connectingIndicator.stopAnimating()
    }
    
    @IBAction func switchVideoView(sender: AnyObject) {
        NSLog("switch video view")
        // TODO: upstream connection
        self.presentViewController(self.localVideoViewController, animated: true, completion: {})
    }
    
    @IBAction func URLFieldEditingDidEndOnExit(sender: AnyObject) {
        NSLog("URLFieldEditingDidEndOnExit")
    }
    
    func cancelPortField() {
        self.portField.resignFirstResponder()
        self.portField.text = ""
    }
    
    func applyPortField() {
        self.port = self.portField.text!
        self.portField.resignFirstResponder()
    }
    
    @IBAction func portFieldEditingDidEndOnExit(sender: AnyObject) {
        NSLog("portFieldEditingDidEndOnExit")
    }
    
    @IBAction func channelIdEditingDidEndOnExit(sender: AnyObject) {
        NSLog("channelIdEditingDidEndOnExit")
    }
    
    // MARK: - Keyboard
    
    @IBAction func URLFieldDidTouchDown(sender: AnyObject) {
        print("URLFieldDidTouchDown")
        self.touchedField = self.URLField
    }
    
    @IBAction func portFieldDidTouchDown(sender: AnyObject) {
        print("portFieldDidTouchDown")

        self.touchedField = self.portField
    }
    
    @IBAction func channelIdFieldDidTouchDown(sender: AnyObject) {
        print("channelIdFieldDidTouchDown")

        self.touchedField = self.ChannelIdField
    }
    
    func keyboardWillBeShown(notification: NSNotification) {
        print("keyboardWillBeShown")
        if let userInfo = notification.userInfo {
            if let keyboardFrame = userInfo[UIKeyboardFrameEndUserInfoKey]?.CGRectValue, animationDuration = userInfo[UIKeyboardAnimationDurationUserInfoKey]?.doubleValue {
                restoreScrollViewSize()
                
                let convertedKeyboardFrame = scrollView.convertRect(keyboardFrame, fromView: nil)
                let offsetY: CGFloat = CGRectGetMaxY(self.touchedField.frame) - CGRectGetMinY(convertedKeyboardFrame)
                if offsetY < 0 { return }
                updateScrollViewSize(offsetY, duration: animationDuration)
            }
        }
    }
    
    func keyboardWillBeHidden(notification: NSNotification) {
        restoreScrollViewSize()
    }
    
    func updateScrollViewSize(moveSize: CGFloat, duration: NSTimeInterval) {
        UIView.beginAnimations("ResizeForKeyboard", context: nil)
        UIView.setAnimationDuration(duration)
        
        let contentInsets = UIEdgeInsetsMake(0, 0, moveSize, 0)
        scrollView.contentInset = contentInsets
        scrollView.scrollIndicatorInsets = contentInsets
        scrollView.contentOffset = CGPointMake(0, moveSize)
        
        UIView.commitAnimations()
    }
    
    func restoreScrollViewSize() {
        scrollView.contentInset = UIEdgeInsetsZero
        scrollView.scrollIndicatorInsets = UIEdgeInsetsZero
        scrollView.contentOffset = CGPointMake(0, 0)
    }
    
}

class UpstreamDelegate: NSObject, SoraConnectionDelegate {
    
    var viewController: RemoteVideoViewController
    
    init(viewController: RemoteVideoViewController) {
        self.viewController = viewController
    }
    
    @objc func connection(connection: SoraConnection, didFailWithError error: NSError) {
        print("UpstreamDelegate connection:didFailWithError:")
    }
    
    @objc func connection(connection: SoraConnection, didReceiveErrorResponse response: SoreErrorResponse) {
        print("UpstreamDelegate connection:didReceiveErrorResponse:")
    }

}


class DownstreamDelegate: NSObject, SoraConnectionDelegate {
    
    var viewController: RemoteVideoViewController
    
    init(viewController: RemoteVideoViewController) {
        self.viewController = viewController
    }
    
    @objc func connection(connection: SoraConnection, didFailWithError error: NSError) {
        print("connection:didFailWithError:")
    }
    
    @objc func connection(connection: SoraConnection, didReceiveErrorResponse response: SoreErrorResponse) {
        print("connection:didReceiveErrorResponse:")
    }
    
    @objc func connectionDidOpen(connection: SoraConnection) {
        print("connectionDidOpen")
    }
    
    @objc func connection(connection: SoraConnection, didReceivePing message: AnyObject) {
        print("connection:didReceivePing:")
    }
    
    @objc func connection(connection: SoraConnection, stateChanged state: SoraConnectionState) {
        print("connection:stateChanged:")
        if state == SoraConnectionState.PeerOpen {
            print("peer open")
            self.viewController.finishConnect()
        }
    }
    
    @objc func connection(connection: SoraConnection, numberOfDownstreamConnections numStreams: UInt) {
        print("connection:numberOfDownstreamConnections: ", numStreams)
    }
}