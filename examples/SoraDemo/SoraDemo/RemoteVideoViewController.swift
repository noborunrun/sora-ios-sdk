import UIKit
import WebRTC
import Sora

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
    
    var upstream: Sora.Connection!
    var downstream: Sora.Connection!
    var port: String!
    var state: State
    var touchedField: UITextField!
    var upstreamDelegate: UpstreamDelegate!
    var downstreamDelegate: DownstreamDelegate!
    var localVideoViewController: LocalVideoViewController!
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        state = .Closed
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        state = .Closed
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
        messageLabel.text = nil
        connectButton.setTitle("Connect", forState: UIControlState.Normal)
        connectingIndicator.stopAnimating()
        URLField.text = "192.168.0.1"
        ChannelIdField.text = "sora"
        portField.text = "5000"
        
        let numBar = UIToolbar(frame: CGRectMake(0, 0, 320, 50))
        numBar.barStyle = UIBarStyle.Default
        numBar.items = [
            UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(cancelPortField)),
        UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil),
        UIBarButtonItem(title: "Apply", style: UIBarButtonItemStyle.Done, target: self, action: #selector(applyPortField))]
        numBar.sizeToFit()
        portField.inputAccessoryView = numBar
        
        localVideoViewController = storyboard?.instantiateViewControllerWithIdentifier("LocalViedoViewController") as! LocalVideoViewController
        localVideoViewController?.remoteVideoViewController = self
        localVideoViewController?.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
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
        switch state {
        case .Connecting:
            // do nothing
            break
        case .Open:
            NSLog("try disconnect")
            state = .Closed
            connectButton.setTitle("Connect", forState: UIControlState.Normal)
            connectingIndicator.stopAnimating()
            downstream!.close()
            upstream!.close()
        case .Closed:
            NSLog("try connect")
            state = .Connecting
            connectButton.enabled = false
            connectButton.setTitle("Connecting...", forState: UIControlState.Normal)
            connectingIndicator.startAnimating()
            tryConnect()
        }
    }
    
    func tryConnect() {
        NSLog("try connect")
        print("URL = %@", URLField.text)
        print("ChannelId = %@", ChannelIdField.text)
        if URLField.text == "" {
            messageLabel.text = "Error: Input URL"
            return
        }
        
        if portField.text == "" {
            messageLabel.text = "Error: Input port number"
            return
        }
        
        if ChannelIdField.text == "" {
            messageLabel.text = "Error: Input channel ID"
            return
        }
        
        NSLog("create Sora.Connection")
        let s = NSString.init(format: "ws://%@:%@/signaling",
                              URLField.text!, portField.text!) as String
        let URL = NSURL(string: s)!
        let channelId = ChannelIdField.text!
        
        // upstream
        upstream = Sora.Connection(URL: URL, config: nil, constraints: nil)
        upstreamDelegate = UpstreamDelegate(viewController: self)
        upstream.delegate = upstreamDelegate
        let upSigConnect = Sora.Signaling.Connect(role: Sora.Signaling.Role.Upstream,
                                                 channelId: channelId,
                                                 accessToken: nil)
        upstream.open(upSigConnect) { (error: NSError?) -> () in return }
        
        // downstream
        downstream = Sora.Connection(URL: URL, config: nil, constraints: nil)
        downstreamDelegate = DownstreamDelegate(viewController: self)
        downstream.delegate = downstreamDelegate
        //remoteView!.setSize(CGSizeMake(320, 240))
        downstream.addRemoteVideoRenderer(remoteView!)
        
        let downSigConnect = Sora.Signaling.Connect(role: Sora.Signaling.Role.Downstream,
                                         channelId: channelId,
                                         accessToken: nil)
        downstream.open(downSigConnect) { (error: NSError?) -> () in return }
    }
    
    func finishConnect() {
        state = .Open
        connectButton.setTitle("Disconnect", forState: UIControlState.Normal)
        connectButton.enabled = true
        connectingIndicator.stopAnimating()
    }
    
    @IBAction func switchVideoView(sender: AnyObject) {
        NSLog("switch video view")
        // TODO: upstream connection
        presentViewController(localVideoViewController, animated: true, completion: {})
    }
    
    @IBAction func URLFieldEditingDidEndOnExit(sender: AnyObject) {
        NSLog("URLFieldEditingDidEndOnExit")
    }
    
    func cancelPortField() {
        portField.resignFirstResponder()
        portField.text = ""
    }
    
    func applyPortField() {
        port = portField.text!
        portField.resignFirstResponder()
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
        touchedField = URLField
    }
    
    @IBAction func portFieldDidTouchDown(sender: AnyObject) {
        print("portFieldDidTouchDown")

        touchedField = portField
    }
    
    @IBAction func channelIdFieldDidTouchDown(sender: AnyObject) {
        print("channelIdFieldDidTouchDown")

        touchedField = ChannelIdField
    }
    
    func keyboardWillBeShown(notification: NSNotification) {
        print("keyboardWillBeShown")
        if let userInfo = notification.userInfo {
            if let keyboardFrame = userInfo[UIKeyboardFrameEndUserInfoKey]?.CGRectValue, animationDuration = userInfo[UIKeyboardAnimationDurationUserInfoKey]?.doubleValue {
                restoreScrollViewSize()
                
                let convertedKeyboardFrame = scrollView.convertRect(keyboardFrame, fromView: nil)
                let offsetY: CGFloat = CGRectGetMaxY(touchedField.frame) - CGRectGetMinY(convertedKeyboardFrame)
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

class UpstreamDelegate: NSObject, Sora.ConnectionDelegate {
    
    var viewController: RemoteVideoViewController
    
    init(viewController: RemoteVideoViewController) {
        self.viewController = viewController
    }
    
    func didFail(connection: Sora.Connection, error: NSError) {
        print("UpstreamDelegate didFail")
    }

    func didChangeState(connection: Sora.Connection, state: Sora.Connection.State) {}
    func didSendSignalingConnect(connection: Sora.Connection, message: Sora.Signaling.Connect) {}
    func didReceiveSignalingOffer(connection: Sora.Connection, message: Sora.Signaling.Offer) {}
    func didSendSignalingAnswer(connection: Sora.Connection, message: Sora.Signaling.Answer) {}
    func didSendCandidate(connection: Sora.Connection, candidate: RTCIceCandidate) {}

}


class DownstreamDelegate: NSObject, Sora.ConnectionDelegate {
    
    var viewController: RemoteVideoViewController
    
    init(viewController: RemoteVideoViewController) {
        self.viewController = viewController
    }
    
    func didFail(connection: Sora.Connection, error: NSError) {
        print("didFail")
    }
    
    func didChangeState(connection: Sora.Connection, state: Sora.Connection.State) {
        print("didChangeState")
        if state == Sora.Connection.State.PeerOpen {
            print("peer open")
            viewController.finishConnect()
        }
    }
    
    func didSendSignalingConnect(connection: Sora.Connection, message: Sora.Signaling.Connect) {}
    func didReceiveSignalingOffer(connection: Sora.Connection, message: Sora.Signaling.Offer) {}
    func didSendSignalingAnswer(connection: Sora.Connection, message: Sora.Signaling.Answer) {}
    func didSendCandidate(connection: Sora.Connection, candidate: RTCIceCandidate) {}

}