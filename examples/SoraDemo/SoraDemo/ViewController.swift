import UIKit

class ViewController: UIViewController {

    enum State {
        case Connecting
        case Closed
    }
    
    @IBOutlet weak var remoteView: RTCEAGLVideoView!
    @IBOutlet weak var URLField: UITextField!
    @IBOutlet weak var ChannelIdField: UITextField!
    @IBOutlet weak var connectButton: UIButton!

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
        self.connectButton.setTitle("Connect", forState: UIControlState.Normal)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func connectOrDisconnect(sender: AnyObject) {
        switch self.state {
        case .Connecting:
            self.state = .Closed
            self.connectButton.setTitle("Connect", forState: UIControlState.Normal)
        case .Closed:
            self.state = .Connecting
            self.connectButton.setTitle("Disconnect", forState: UIControlState.Normal)
        }
    }
    
    @IBAction func switchVideoView(sender: AnyObject) {
    }
    
}

