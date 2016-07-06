import UIKit

class ViewController: UIViewController {

    enum State {
        case Connecting
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
    var connection: SoraConnection!
    var port: String!
    var state: State
    var touchedField: UITextField!
    
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
        self.messageLabel.text = nil
        self.connectButton.setTitle("Connect", forState: UIControlState.Normal)
        self.connectingIndicator.stopAnimating()
        
        let numBar = UIToolbar(frame: CGRectMake(0, 0, 320, 50))
        numBar.barStyle = UIBarStyle.Default
        numBar.items = [
            UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(cancelPortField)),
        UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil),
        UIBarButtonItem(title: "Apply", style: UIBarButtonItemStyle.Done, target: self, action: #selector(applyPortField))]
        numBar.sizeToFit()
        self.portField.inputAccessoryView = numBar
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
            NSLog("disconnect")
            self.state = .Closed
            self.connectButton.setTitle("Connect", forState: UIControlState.Normal)
            self.connectingIndicator.stopAnimating()
        case .Closed:
            NSLog("try connect")
            self.state = .Connecting
            self.connectButton.enabled = false
            self.connectButton.setTitle("Connecting...", forState: UIControlState.Normal)
            self.connectingIndicator.startAnimating()
            //self.tryConnect()
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
        let URL = NSURL(string: self.URLField.text!)!
        let channelId = self.ChannelIdField.text!
        self.connection = SoraConnection(URL: URL)
        let req = SoraConnectRequest(role: SoraRole.Downstream, channelId: channelId, accessToken: nil)
        self.connection.open(req!)
    }
    
    @IBAction func switchVideoView(sender: AnyObject) {
        NSLog("switch video view")
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

