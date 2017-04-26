import UIKit

public class ConnectionController: UIViewController {

    public enum Role {
        case publisher
        case subscriber
        
        static var allRoles: [Role] = [.publisher, .subscriber]
        
        static func containsAll(_ roles: [Role]) -> Bool {
            let allRoles: [Role] = [.publisher, .subscriber]
            for role in roles {
                if !allRoles.contains(role) {
                    return false
                }
            }
            return true
        }
    }
    
    public enum StreamType {
        case single
        case multiple
    }
    
    public class Request {
        
        public var URL: URL
        public var channelId: String
        public var roles: [Role]
        public var multistreamEnabled: Bool
        public var videoEnabled: Bool
        public var videoCodec: VideoCodec
        public var bitRate: Int
        public var audioEnabled: Bool
        public var audioCodec: AudioCodec
        
        public init(URL: URL,
                    channelId: String,
                    roles: [Role],
                    multistreamEnabled: Bool,
                    videoEnabled: Bool,
                    videoCodec: VideoCodec,
                    bitRate: Int,
                    audioEnabled: Bool,
                    audioCodec: AudioCodec) {
            self.URL = URL
            self.channelId = channelId
            self.roles = roles
            self.multistreamEnabled = multistreamEnabled
            self.videoEnabled = videoEnabled
            self.videoCodec = videoCodec
            self.bitRate = bitRate
            self.audioEnabled = audioEnabled
            self.audioCodec = audioCodec
        }
        
    }
    
    enum UserDefaultsKey: String {
        case WebSocketSSLEnabled = "SoraConnectionControllerWebSocketSSLEnabled"
        case host = "SoraConnectionControllerHost"
        case port = "SoraConnectionControllerPort"
        case signalingPath = "SoraConnectionControllerSignalingPath"
        case channelId = "SoraConnectionControllerChannelId"
        case roles = "SoraConnectionControllerRoles"
        case multistreamEnabled = "SoraConnectionControllerMultistreamEnabled"
        case videoEnabled = "SoraConnectionControllerVideoEnabled"
        case videoCodec = "SoraConnectionControllerVideoCodec"
        case bitRate = "SoraConnectionControllerBitRate"
        case audioEnabled = "SoraConnectionControllerAudioEnabled"
        case audioCodec = "SoraConnectionControllerAudioCodec"
        case autofocusEnabled = "SoraConnectionControllerAutofocusEnabled"
    }
    
    static var userDefaultsDidLoadNotificationName: Notification.Name
        = Notification.Name("SoraConnectionControllerUserDefaultsDidLoad")
    
    public var connection: Connection?
    
    var connectionControllerStoryboard: UIStoryboard?
    var connectionNavigationController: ConnectionNavigationController!
    
    public var WebSocketSSLEnabled: Bool = true
    public var host: String?
    public var port: UInt?
    public var signalingPath: String?
    public var channelId: String?
    public var availableRoles: [Role] = [.publisher, .subscriber]
    public var availableStreamTypes: [StreamType] = [.single, .multiple]
    public var autofocusEnabled: Bool = false
    public var multistreamEnabled: Bool = false
    public var videoEnabled: Bool = true
    public var videoCodec: VideoCodec = .default
    public var bitRate: Int? = 800
    public var audioEnabled: Bool = true
    public var audioCodec: AudioCodec = .default
    public var userDefaultsSuiteName: String? = "jp.shiguredo.SoraConnectionController"
    
    public var userDefaults: UserDefaults? {
        get { return UserDefaults(suiteName: userDefaultsSuiteName) }
    }
    
    var tupleOfAvailableStreamTypes: (Bool, Bool) {
        get {
            return (availableStreamTypes.contains(.single),
                    availableStreamTypes.contains(.multiple))
        }
    }
    
    public init(WebSocketSSLEnabled: Bool = true,
                host: String? = nil,
                port: UInt? = nil,
                signalingPath: String? = "signaling",
                channelId: String? = nil,
                availableRoles: [Role]? = nil,
                availableStreamTypes: [StreamType]? = nil,
                userDefaultsSuiteName: String? = nil) {
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
        
        self.WebSocketSSLEnabled = WebSocketSSLEnabled
        self.host = host
        self.port = port
        self.signalingPath = signalingPath
        self.channelId = channelId
        if let roles = availableRoles {
            self.availableRoles = roles
        }
        if let streamTypes = availableStreamTypes {
            self.availableStreamTypes = streamTypes
        }
        self.userDefaultsSuiteName = userDefaultsSuiteName
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
    var onConnectHandler: ((Connection?, [Role]?, ConnectionError?) -> Void)?
    var onCancelHandler: (() -> Void)?

    public func onRequest(handler: @escaping (Connection, Request) -> Void) {
        onRequestHandler = handler
    }
    
    public func onConnect(handler:
        @escaping (Connection?, [Role]?, ConnectionError?) -> Void) {
        onConnectHandler = handler
    }
    
    public func onCancel(handler: @escaping () -> Void) {
        onCancelHandler = handler
    }
    
    // MARK: - User Defaults
    
    func loadFromUserDefaults() {
        // TODO
        NotificationCenter.default.post(name: ConnectionController
            .userDefaultsDidLoadNotificationName, object: self)
    }
    
    func saveToUserDefaults() {
        // TODO
    }
    
}

extension ConnectionController {
    
    struct Action {
        
        static let updateWebSocketSSLEnabled =
            #selector(ConnectionController.updateWebSocketSSLEnabled(_:))
        static let updateHost =
            #selector(ConnectionController.updateHost(_:))
        static let updatePort =
            #selector(ConnectionController.updatePort(_:))
        static let updateSignalingPath =
            #selector(ConnectionController.updateSignalingPath(_:))
        static let updateChannelId =
            #selector(ConnectionController.updateChannelId(_:))
        static let updateMultistreamEnabled =
            #selector(ConnectionController.updateMultistreamEnabled(_:))
        static let updateVideoEnabled =
            #selector(ConnectionController.updateVideoEnabled(_:))
        static let updateBitRate =
            #selector(ConnectionController.updateBitRate(_:))
        static let updateAudioEnabled =
            #selector(ConnectionController.updateAudioEnabled(_:))
        static let updateAutofocus =
            #selector(ConnectionController.updateAutofocus(_:))
        
    }
    
    func updateWebSocketSSLEnabled(_ sender: AnyObject) {
        if let control = sender as? UISwitch {
            WebSocketSSLEnabled = control.isOn
        }
    }
    
    func updateHost(_ sender: AnyObject) {
        if let control = sender as? UITextField {
            host = control.text
        }
    }
    
    func updatePort(_ sender: AnyObject) {
        if let control = sender as? UITextField {
            if let text = control.text {
                port = UInt(text)
            }
        }
    }
    
    func updateSignalingPath(_ sender: AnyObject) {
        if let control = sender as? UITextField {
            signalingPath = control.text
        }
    }
    
    func updateChannelId(_ sender: AnyObject) {
        if let control = sender as? UITextField {
            channelId = control.text
        }
    }
    
    func updateMultistreamEnabled(_ sender: AnyObject) {
        if let control = sender as? UISwitch {
            multistreamEnabled = control.isOn
        }
    }
    
    func updateVideoEnabled(_ sender: AnyObject) {
        if let control = sender as? UISwitch {
            videoEnabled = control.isOn
        }
    }
    
    func updateBitRate(_ sender: AnyObject) {
        if let control = sender as? UITextField {
            if let text = control.text {
                bitRate = Int(text)
            }
        }
    }
    
    func updateAudioEnabled(_ sender: AnyObject) {
        if let control = sender as? UISwitch {
            audioEnabled = control.isOn
        }
    }
    
    func updateAutofocus(_ sender: AnyObject) {
        if let control = sender as? UISwitch {
            autofocusEnabled = control.isOn
        }
    }
    
}
