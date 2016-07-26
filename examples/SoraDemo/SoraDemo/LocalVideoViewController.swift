import Foundation

class LocalVideoViewController : UIViewController {
    
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var switchRemoteVideoButton: UIButton!
    
    var connection: SoraConnection!
    weak var remoteVideoViewController: ViewController!

    @IBAction func switchToRemoteVideoView(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: {})
    }
    
}