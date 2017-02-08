import UIKit

public class ConnectionController: UIViewController {

    public enum Role {
        case all
        case publisher
        case subscriber
    }
    
    public struct Request {
        public var URL: URL
        public var channelId: String
        public var role: Role
        public var multistreamEnabled: Bool
        public var videoEnabled: Bool
        public var videoCodec: VideoCodec
        public var audioEnabled: Bool
        public var audioCodec: AudioCodec
    }
    
    enum UserDefaultsKey: String {
        case URL = "SoraConnectionControllerURL"
        case channelId = "SoraConnectionControllerChannelId"
        case role = "SoraConnectionControllerRole"
        case multistreamEnabled = "SoraConnectionControllerMultistreamEnabled"
        case videoEnabled = "SoraConnectionControllerVideoEnabled"
        case videoCodec = "SoraConnectionControllerVideoCodec"
        case audioEnabled = "SoraConnectionControllerAudioEnabled"
        case audioCodec = "SoraConnectionControllerAudioCodec"
        case autofocusEnabled = "SoraConnectionControllerAutofocusEnabled"
    }
    
    public var connection: Connection?
    
    var connectionControllerStoryboard: UIStoryboard?
    var connectionNavigationController: ConnectionNavigationController!
    
    public var URL: String?
    public var channelId: String?
    
    public var userDefaults: UserDefaults? =
        UserDefaults(suiteName: "jp.shiguredo.SoraConnectionController")
    
    public init(URL: String? = nil,
                channelId: String? = nil) {
        super.init(nibName: nil, bundle: nil)
        connectionControllerStoryboard =
            UIStoryboard(name: "ConnectionController",
                         bundle: Bundle(for: ConnectionController.self))
        guard let navi = connectionControllerStoryboard?
            .instantiateViewController(withIdentifier: "Navigation")
            as! ConnectionNavigationController? else {
            fatalError("failed loading ConnectionViewController")
        }
        connectionNavigationController = navi
        connectionNavigationController.connectionController = self
        
        addChildViewController(connectionNavigationController)
        view.addSubview(connectionNavigationController.view)
        connectionNavigationController.didMove(toParentViewController: self)
        
        self.URL = URL
        self.channelId = channelId
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    var onRequestHandler: ((Connection, Request) -> Void)?
    var onConnectHandler: ((Connection?, Role?, ConnectionError?) -> Void)?
    var onCancelHandler: (() -> Void)?

    public func onRequest(handler: @escaping (Connection, Request) -> Void) {
        onRequestHandler = handler
    }
    
    public func onConnect(handler:
        @escaping (Connection?, Role?, ConnectionError?) -> Void) {
        onConnectHandler = handler
    }
    
    public func onCancel(handler: @escaping () -> Void) {
        onCancelHandler = handler
    }
    
}
