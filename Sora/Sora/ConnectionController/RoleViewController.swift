import UIKit

class RoleViewController: UITableViewController {

    @IBOutlet weak var allLabel: UILabel!
    @IBOutlet weak var allCell: UITableViewCell!
    @IBOutlet weak var publisherLabel: UILabel!
    @IBOutlet weak var publisherCell: UITableViewCell!
    @IBOutlet weak var subscriberLabel: UILabel!
    @IBOutlet weak var subscriberCell: UITableViewCell!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        for label: UILabel in [allLabel, publisherLabel, subscriberLabel] {
            label.font = UIFont.preferredFont(forTextStyle: .body)
            label.adjustsFontForContentSizeCategory = true
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        clearCheckmarks()
        switch ConnectionViewController.main?.role {
        case .all?, nil:
            allCell.accessoryType = .checkmark
        case .publisher?:
            publisherCell.accessoryType = .checkmark
        case .subscriber?:
            subscriberCell.accessoryType = .checkmark
        }
    }
    
    override func didReceiveMemoryWarning() {
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

    func clearCheckmarks() {
        allCell?.accessoryType = .none
        publisherCell?.accessoryType = .none
        subscriberCell?.accessoryType = .none
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        clearCheckmarks()
        switch indexPath.row {
        case 0:
            ConnectionViewController.main?.role = .all
            allCell?.accessoryType = .checkmark
        case 1:
            ConnectionViewController.main?.role = .publisher
            publisherCell?.accessoryType = .checkmark
        case 2:
            ConnectionViewController.main?.role = .subscriber
            subscriberCell?.accessoryType = .checkmark
        default:
            break
        }
    }
    
}
