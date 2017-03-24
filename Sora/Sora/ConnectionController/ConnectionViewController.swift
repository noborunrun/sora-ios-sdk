import UIKit

class ConnectionViewController: UITableViewController {
    
    enum State {
        case connected
        case connecting
        case disconnected
    }
    
    @IBOutlet weak var cancelButtonItem: UIBarButtonItem!
    
    @IBOutlet weak var connectionStateCell: UITableViewCell!
    @IBOutlet weak var connectionTimeLabel: UILabel!
    @IBOutlet weak var URLLabel: UILabel!
    @IBOutlet weak var channelIdLabel: UILabel!
    @IBOutlet weak var roleLabel: UILabel!
    @IBOutlet weak var roleCell: UITableViewCell!
    @IBOutlet weak var enableMultistreamLabel: UILabel!
    @IBOutlet weak var enableVideoLabel: UILabel!
    @IBOutlet weak var videoCodecLabel: UILabel!
    @IBOutlet weak var videoCodecCell: UITableViewCell!
    @IBOutlet weak var enableAudioLabel: UILabel!
    @IBOutlet weak var audioCodecLabel: UILabel!
    @IBOutlet weak var audioCodecCell: UITableViewCell!
    @IBOutlet weak var autofocusLabel: UILabel!
    @IBOutlet weak var WebRTCVersionLabel: UILabel!
    @IBOutlet weak var WebRTCRevisionLabel: UILabel!
    @IBOutlet weak var VP9EnabledLabel: UILabel!
    
    @IBOutlet weak var connectionTimeValueLabel: UILabel!
    @IBOutlet weak var URLTextField: UITextField!
    @IBOutlet weak var channelIdTextField: UITextField!
    @IBOutlet weak var rollValueLabel: UILabel!
    @IBOutlet weak var enableMultistreamSwitch: UISwitch!
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var enableVideoSwitch: UISwitch!
    @IBOutlet weak var videoCodecValueLabel: UILabel!
    @IBOutlet weak var enableAudioSwitch: UISwitch!
    @IBOutlet weak var audioCodecValueLabel: UILabel!
    @IBOutlet weak var autofocusSwitch: UISwitch!
    @IBOutlet weak var WebRTCVersionValueLabel: UILabel!
    @IBOutlet weak var WebRTCRevisionValueLabel: UILabel!
    @IBOutlet weak var VP9EnabledValueLabel: UILabel!
    
    weak var touchedField: UITextField?
    
    static var main: ConnectionViewController?
    
    var indicator: UIActivityIndicatorView?
    
    var state: State = .disconnected {
        didSet {
            DispatchQueue.main.async {
                switch self.state {
                case .connected:
                    self.cancelButtonItem.title = "Back"
                    self.connectButton.setTitle("Disconnect", for: .normal)
                    self.connectButton.isEnabled = true
                    self.connectionStateCell.accessoryView = nil
                    self.connectionStateCell.accessoryType = .checkmark
                    self.indicator?.stopAnimating()
                    self.enableControls(false)
                    self.connectionTimeLabel.textColor = nil
                    
                case .disconnected:
                    self.cancelButtonItem.title = "Cancel"
                    self.connectButton.setTitle("Connect", for: .normal)
                    self.connectButton.isEnabled = true
                    self.connectionStateCell.accessoryView = nil
                    self.connectionStateCell.accessoryType = .none
                    self.indicator?.stopAnimating()
                    self.connectionTimeValueLabel.text = nil
                    self.enableControls(true)
                    self.connectionTimeLabel.textColor = UIColor.lightGray
                    
                case .connecting:
                    self.connectButton.titleLabel!.text = "Connecting..."
                    self.connectButton.setTitle("Connecting...", for: .normal)
                    self.connectButton.isEnabled = false
                    self.indicator?.startAnimating()
                    self.connectionStateCell.accessoryView = self.indicator
                    self.connectionStateCell.accessoryType = .none
                    self.connectionTimeValueLabel.text = nil
                    self.enableControls(false)
                    self.connectionTimeLabel.textColor = UIColor.lightGray
                }
            }
        }
    }
    
    var URLString: String? {
        get { return URLTextField.text }
        set { URLTextField.text = newValue }
    }
    
    var channelId: String? {
        get { return channelIdTextField.text }
        set { channelIdTextField.text = newValue }
    }
    
    var roles: [ConnectionController.Role] = [] {
        didSet {
            var s: [String] = []
            if roles.contains(.publisher) {
                s.append("Publisher")
            }
            if roles.contains(.subscriber) {
                s.append("Subscriber")
            }
            rollValueLabel.text = s.joined(separator: ",")
        }
    }
    
    var multistreamEnabled: Bool {
        get { return enableMultistreamSwitch.isOn }
    }
    
    var videoEnabled: Bool {
        get { return enableVideoSwitch.isOn }
    }
    
    var videoCodec: VideoCodec? {
        didSet {
            switch videoCodec {
            case .default?, nil:
                videoCodecValueLabel.text = "Default"
            case .VP8?:
                videoCodecValueLabel.text = "VP8"
            case .VP9?:
                videoCodecValueLabel.text = "VP9"
            case .H264?:
                videoCodecValueLabel.text = "H.264"
            }
        }
    }
    
    var audioEnabled: Bool {
        get { return enableAudioSwitch.isOn }
    }
    
    var audioCodec: AudioCodec? {
        didSet {
            switch audioCodec {
            case .default?, nil:
                audioCodecValueLabel.text = "Default"
            case .Opus?:
                audioCodecValueLabel.text = "Opus"
            case .PCMU?:
                audioCodecValueLabel.text = "PCMU"
            }
        }
    }
    
    var connectionController: ConnectionController? {
        get {
            return (navigationController as! ConnectionNavigationController?)?
                .connectionController
        }
    }
    
    var connection: Connection?
    
    // MARK: - View Controller
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        ConnectionViewController.main = self
        indicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        
        for label: UILabel in [connectionTimeLabel,
                               connectionTimeValueLabel,
                               URLLabel, channelIdLabel,
                               roleLabel, rollValueLabel,
                               enableMultistreamLabel,
                               connectButton.titleLabel!,
                               enableVideoLabel, videoCodecLabel,
                               videoCodecValueLabel,
                               enableAudioLabel, audioCodecLabel,
                               audioCodecValueLabel, autofocusLabel,
                               WebRTCVersionLabel, WebRTCVersionValueLabel,
                               WebRTCRevisionLabel, WebRTCRevisionValueLabel,
                               VP9EnabledLabel, VP9EnabledValueLabel]
        {
            label.font = UIFont.preferredFont(forTextStyle: .body)
            label.adjustsFontForContentSizeCategory = true
        }
        for field: UITextField in [URLTextField, channelIdTextField] {
            field.font = UIFont.preferredFont(forTextStyle: .body)
            field.adjustsFontForContentSizeCategory = true
        }
        
        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(applicationDidEnterBackground(_:)),
                         name: NSNotification.Name.UIApplicationDidEnterBackground,
                         object: nil)
        
        state = .disconnected
        roles = [.publisher, .subscriber]
        videoCodec = .default
        audioCodec = .default
        autofocusSwitch.setOn(false, animated: false)
        connectionTimeValueLabel.text = nil
        URLTextField.text = connectionController?.URL
        URLTextField.placeholder = "www.example.com"
        channelIdTextField.text = connectionController?.channelId
        channelIdTextField.placeholder = "your channel ID"
        
        loadSettings()

        switch connectionController!.tupleOfAvailableStreamTypes {
        case (true, true), (false, false):
            break
        case (true, false):
            enableMultistreamLabel.textColor = UIColor.lightGray
            enableMultistreamSwitch.isOn = false
            enableMultistreamSwitch.isEnabled = false
        case (false, true):
            enableMultistreamLabel.textColor = UIColor.lightGray
            enableMultistreamSwitch.isOn = true
            enableMultistreamSwitch.isEnabled = false
        }
        
        // build info
        if let version = BuildInfo.WebRTCVersion {
            WebRTCVersionValueLabel.text = version
        } else {
            WebRTCVersionValueLabel.text = "Unknown"
        }
        if let revision = BuildInfo.WebRTCShortRevision {
            WebRTCRevisionValueLabel.text = revision
        } else {
            WebRTCRevisionValueLabel.text = "Unknown"
        }
        if let VP9 = BuildInfo.VP9Enabled {
            VP9EnabledValueLabel.text = VP9 ? "Enabled" : "Disabled"
        } else {
            VP9EnabledValueLabel.text = "Unknown"
        }
    }
    
    func applicationDidEnterBackground(_ notification: Notification) {
        saveSettings()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        saveSettings()
    }
    
    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func addRole(_ role: ConnectionController.Role) {
        if !roles.contains(role) {
            roles.append(role)
        }
    }
    
    func removeRole(_ role: ConnectionController.Role) {
        roles = roles.filter {
            each in return each != role
        }
    }
    
    // MARK: 設定の保存
    
    func loadSettings() {
        guard let defaults = connectionController!.userDefaults else {
            return
        }
        
        if let url = defaults.string(forKey:
            ConnectionController.UserDefaultsKey.URL.rawValue) {
            if !url.isEmpty {
                URLTextField.text = url
            }
        }
        
        if let channelId = defaults.string(forKey:
            ConnectionController.UserDefaultsKey.channelId.rawValue) {
            if !channelId.isEmpty {
                channelIdTextField.text = channelId
            }
        }
        
        roles = [.publisher]
        if let roleValue = defaults.string(forKey:
            ConnectionController.UserDefaultsKey.roles.rawValue) {
            roles = []
            if roleValue.contains("p") {
                roles.append(.publisher)
            }
            if roleValue.contains("s") {
                roles.append(.subscriber)
            }
        }
        
        initSwitchValue(switch_: enableMultistreamSwitch,
                        key: .multistreamEnabled,
                        value: false)
        initSwitchValue(switch_: enableVideoSwitch,
                        key: .videoEnabled,
                        value: true)
        initSwitchValue(switch_: enableAudioSwitch,
                        key: .audioEnabled,
                        value: true)
        initSwitchValue(switch_: autofocusSwitch,
                        key: .autofocusEnabled,
                        value: false)
        
        switch defaults.string(forKey:
            ConnectionController.UserDefaultsKey.videoCodec.rawValue) {
        case "VP8"?:
            videoCodec = .VP8
        case "VP9"?:
            videoCodec = .VP9
        case "H.264"?:
            videoCodec = .H264
        default:
            videoCodec = nil
        }
        
        switch defaults.string(forKey:
            ConnectionController.UserDefaultsKey.audioCodec.rawValue) {
        case "Opus"?:
            audioCodec = .Opus
        case "VP9"?:
            audioCodec = .PCMU
        default:
            audioCodec = nil
        }
    }
    
    func initSwitchValue(switch_: UISwitch!,
                         key: ConnectionController.UserDefaultsKey,
                         value: Bool) {
        let defaults = UserDefaults.standard
        if let _ = defaults.object(forKey: key.rawValue) {
            switch_.setOn(defaults.bool(forKey: key.rawValue), animated: false)
        } else {
            switch_.setOn(value, animated: false)
        }
    }
    
    func saveSettings() {
        guard let defaults = connectionController!.userDefaults else {
            return
        }
        
        if let text = URLTextField.text {
            defaults.set(text,
                         forKey:
                ConnectionController.UserDefaultsKey.URL.rawValue)
        }
        
        if let text = channelIdTextField.text {
            defaults.set(text,
                         forKey:
                ConnectionController.UserDefaultsKey.channelId.rawValue)
        }
        
        var roleValue = ""
        if roles.contains(.publisher) {
            roleValue.append("p")
        }
        if roles.contains(.subscriber) {
            roleValue.append("s")
        }
        if roleValue.isEmpty {
            roleValue = "ps"
        }
        
        defaults.set(roleValue,
                     forKey:
            ConnectionController.UserDefaultsKey.roles.rawValue)
        defaults.set(multistreamEnabled,
                     forKey:
            ConnectionController.UserDefaultsKey.multistreamEnabled.rawValue)
        defaults.set(videoEnabled,
                     forKey:
            ConnectionController.UserDefaultsKey.videoEnabled.rawValue)
        
        var videoCodecValue: String?
        switch videoCodec {
        case .VP8?:
            videoCodecValue = "VP8"
        case .VP9?:
            videoCodecValue = "VP9"
        case .H264?:
            videoCodecValue = "H.264"
        default:
            videoCodecValue = nil
        }
        defaults.set(videoCodecValue,
                     forKey:
            ConnectionController.UserDefaultsKey.videoCodec.rawValue)
        
        defaults.set(audioEnabled,
                     forKey:
            ConnectionController.UserDefaultsKey.audioEnabled.rawValue)
        
        var audioCodecValue: String?
        switch audioCodec {
        case .Opus?:
            audioCodecValue = "Opus"
        case .PCMU?:
            audioCodecValue = "PCMU"
        default:
            audioCodecValue = nil
        }
        defaults.set(audioCodecValue,
                     forKey:
            ConnectionController.UserDefaultsKey.audioCodec.rawValue)
        
        defaults.set(autofocusSwitch.isOn,
                     forKey:
            ConnectionController.UserDefaultsKey.autofocusEnabled.rawValue)
        
        defaults.synchronize()
    }
    
    // MARK: アクション
    
    func enableControls(_ isEnabled: Bool) {
        let labels: [UILabel] = [
            URLLabel, channelIdLabel, roleLabel,
            enableVideoLabel, videoCodecLabel,
            enableAudioLabel, audioCodecLabel,
            ]
        for label in labels {
            label.textColor = isEnabled ? nil : UIColor.lightGray
        }
        
        switch connectionController!.tupleOfAvailableStreamTypes {
        case (true, false), (false, true):
            enableMultistreamLabel.textColor = UIColor.lightGray
        default:
            enableMultistreamLabel.textColor = nil
        }
        
        let fields: [UITextField] = [URLTextField, channelIdTextField]
        for field in fields {
            if isEnabled {
                field.textColor = nil
            } else {
                field.textColor = UIColor.lightGray
            }
        }
        
        let controls: [UIView] = [
            URLTextField, channelIdTextField, roleCell,
            enableMultistreamSwitch, enableVideoSwitch, enableAudioSwitch,
            videoCodecCell, audioCodecCell]
        for control: UIView in controls {
            control.isUserInteractionEnabled = isEnabled
        }
    }
    
    @IBAction func cancel(_ sender: AnyObject) {
        back(isCancel: true)
    }
    
    func back(isCancel: Bool) {
        saveSettings()
        dismiss(animated: true) {
            if isCancel {
                self.connectionController!.onCancelHandler?()
            }
            self.connectionController!.URL = self.URLLabel.text
            self.connectionController!.channelId = self.channelIdLabel.text
        }
    }
    
    var connectingAlertController: UIAlertController!
    
    @IBAction func connectOrDisconnect(_ sender: AnyObject) {
        saveSettings()
        
        switch state {
        case .connecting:
            assertionFailure("invalid state")
            
        case .connected:
            disconnect()
            
        case .disconnected:
            if URLString == nil || URLString!.isEmpty {
                presentSimpleAlert(title: "Error",
                                   message: "Input server URL")
                return
            }
            
            if channelId == nil || channelId!.isEmpty {
                presentSimpleAlert(title: "Error",
                                   message: "Input channel ID")
                return
            }
            
            guard let URL = URL(string: URLString!) else {
                presentSimpleAlert(title: "Error",
                                   message: "Invalid server URL")
                return
            }
            
            if roles.isEmpty {
                presentSimpleAlert(title: "Error",
                                   message: "Select roles")
                return
            }
            
            connection = Connection(URL: URL, mediaChannelId: channelId!)
            let request = ConnectionController
                .Request(URL: URL,
                         channelId: channelId!,
                         roles: roles,
                         multistreamEnabled: multistreamEnabled,
                         videoEnabled: videoEnabled,
                         videoCodec: videoCodec ?? .default,
                         audioEnabled: audioEnabled,
                         audioCodec: audioCodec ?? .default)
            connectionController?.onRequestHandler?(connection!, request)
            
            connectingAlertController = UIAlertController(
                title: nil,
                message: "Connecting to the server...",
                preferredStyle: .alert)
            let indicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
            indicator.center = CGPoint(x: 25, y: 30)
            connectingAlertController.view.addSubview(indicator)
            connectingAlertController.addAction(
                UIAlertAction(title: "Cancel", style: .cancel)
                {
                    _ in
                    self.disconnect()
                }
            )
            DispatchQueue.main.async {
                indicator.startAnimating()
                self.present(self.connectingAlertController, animated: true) {}
            }
            
            state = .connecting
            if roles.contains(.publisher) {
                self.connectPublisher()
            } else if roles.contains(.subscriber) {
                self.connectSubscriber()
            } else {
                assertionFailure("roles must not be empty")
            }
        }
    }
    
    func connectPublisher() {
        setMediaConnectionSettings(connection!.mediaPublisher)
        connection!.mediaPublisher.connect {
            error in
            DispatchQueue.main.async {
                if let error = error {
                    self.failConnection(error: error)
                    return
                }
                
                if self.roles.contains(.subscriber) {
                    self.connectSubscriber()
                } else {
                    self.finishConnection(self.connection!.mediaPublisher)
                }
            }
        }
    }
    
    func connectSubscriber() {
        setMediaConnectionSettings(connection!.mediaSubscriber)
        connection!.mediaSubscriber.connect {
            error in
            DispatchQueue.main.async {
                if let error = error {
                    self.failConnection(error: error)
                    return
                }
                self.finishConnection(self.connection!.mediaSubscriber)
            }
        }
    }
    
    
    func disconnect() {
        if let conn = connection {
            conn.mediaPublisher.disconnect { _ in () }
            conn.mediaSubscriber.disconnect { _ in () }
        }
        state = .disconnected
        connectingAlertController = nil
    }

    func setMediaConnectionSettings(_ mediaConn: MediaConnection) {
        mediaConn.multistreamEnabled = multistreamEnabled
        mediaConn.mediaOption.videoEnabled = videoEnabled
        if let codec = videoCodec {
            mediaConn.mediaOption.videoCodec = codec
        }
        mediaConn.mediaOption.audioEnabled = audioEnabled
        if let codec = audioCodec {
            mediaConn.mediaOption.audioCodec = codec
        }
        
    }
    
    func failConnection(error: ConnectionError) {
        var title = "Connection Error"
        var message = error.localizedDescription
        switch error {
        case .connectionBusy:
            message = "Connection is busy"
        case .webSocketClose(let code, let reason):
            let reason = reason ?? "?"
            message = String(format: "WebSocket is closed (status code %d, reason %@)",
                             code, reason)
        case .signalingFailure(reason: let reason):
            title = "Signaling Failure"
            message = reason
        default:
            break
        }
        
        connectingAlertController.dismiss(animated: true) {
            self.presentSimpleAlert(title: title, message: message)
            self.state = .disconnected
            self.connectionController?.onConnectHandler?(nil, nil, error)
        }
    }
    
    func finishConnection(_ mediaConnection: MediaConnection) {
        if connectingAlertController != nil {
            connectingAlertController.dismiss(animated: true) {
                self.basicFinishConnection(mediaConnection)
            }
            connectingAlertController = nil
        } else {
            basicFinishConnection(mediaConnection)
        }
    }
    
    func basicFinishConnection(_ mediaConnection: MediaConnection) {
        state = .connected
        mediaConnection.mainMediaStream!.startConnectionTimer(timeInterval: 1) {
            seconds in
            if let seconds = seconds {
                DispatchQueue.main.async {
                    let text = String(format: "%02d:%02d:%02d",
                                      arguments: [seconds/(60*60), seconds/60, seconds%60])
                    self.connectionTimeValueLabel.text = text
                }
            }
        }
        connectionController!.onConnectHandler?(connection, roles, nil)
        back(isCancel: false)
    }
    
    func presentSimpleAlert(title: String? = nil, message: String? = nil) {
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) {
            action in return
        })
        present(alert, animated: true) {}
    }
    
    // MARK: テキストフィールドの編集
    
    @IBAction func URLTextFieldDidTouchDown(_ sender: AnyObject) {
        touchedField = URLTextField
    }
    
    @IBAction func URLTextFieldEditingDidEndOnExit(_ sender: AnyObject) {
        touchedField = nil
    }
    
    @IBAction func channelIdTextFieldDidTouchDown(_ sender: AnyObject) {
        touchedField = channelIdTextField
    }
    
    @IBAction func channelIdTextFieldEditingDidEndOnExit(_ sender: AnyObject) {
        touchedField = nil
    }
    
}
