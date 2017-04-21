import UIKit

class EventLogTextViewController: UIViewController {

    @IBOutlet weak var logTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    func update(settings: EventLogViewController) {
        // TODO
    }
    
    @IBAction func clear(_ sender: AnyObject) {
        logTextView.text = nil
        ConnectionViewController.main?.connection?.eventLog.clear()
    }
    
    @IBAction func copyToClipboard(_ sender: AnyObject) {
        UIPasteboard.general.setValue(logTextView.text,
                                      forPasteboardType: "public.text")
    }
    
}
