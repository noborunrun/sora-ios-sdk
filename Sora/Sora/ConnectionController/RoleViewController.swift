import UIKit

class RoleViewController: UITableViewController {

    @IBOutlet weak var publisherLabel: UILabel!
    @IBOutlet weak var publisherCell: UITableViewCell!
    @IBOutlet weak var subscriberLabel: UILabel!
    @IBOutlet weak var subscriberCell: UITableViewCell!

    var main: ConnectionViewController {
        get { return ConnectionViewController.main! }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        for label: UILabel in [publisherLabel, subscriberLabel] {
            label.font = UIFont.preferredFont(forTextStyle: .body)
            label.adjustsFontForContentSizeCategory = true
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        clearCheckmarks()
        if main.roles.contains(.publisher) {
            publisherCell.accessoryType = .checkmark
        } else if main.roles.contains(.subscriber) {
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
        publisherCell?.accessoryType = .none
        subscriberCell?.accessoryType = .none
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.row {
        case 0:
            if main.roles.count > 1 && main.roles.contains(.publisher) {
                main.removeRole(.publisher)
                publisherCell.accessoryType = .none
            } else {
                main.addRole(.publisher)
                publisherCell.accessoryType = .checkmark
            }
        case 1:
            if main.roles.count > 1 && main.roles.contains(.subscriber) {
                main.removeRole(.subscriber)
                subscriberCell.accessoryType = .none
            } else {
                main.addRole(.subscriber)
                subscriberCell.accessoryType = .checkmark
            }
        default:
            break
        }
    }
    
}
