import UIKit

class ViewController: UIViewController {

    enum State {
        case Connecting
        case Closed
    }
    
    @IBOutlet weak var remoteView: RTCEAGLVideoView!
    @IBOutlet weak var URLField: UITextField!
    @IBOutlet weak var portField: UITextField!
    @IBOutlet weak var ChannelIdField: UITextField!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var connectButton: UIButton!
    var connection: SoraConnection!
    var port: String!
    var state: State
    
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
        
        let numBar = UIToolbar(frame: CGRectMake(0, 0, 320, 50))
        numBar.barStyle = UIBarStyle.Default
        numBar.items = [
            UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(cancelPortField)),
        UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil),
        UIBarButtonItem(title: "Apply", style: UIBarButtonItemStyle.Done, target: self, action: #selector(applyPortField))]
        numBar.sizeToFit()
        self.portField.inputAccessoryView = numBar
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
        case .Closed:
            NSLog("try connect")
            self.state = .Connecting
            self.connectButton.setTitle("Disconnect", forState: UIControlState.Normal)
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
    
}

