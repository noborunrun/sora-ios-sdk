import UIKit

class BitRateViewController: UITableViewController {

    @IBOutlet weak var value100Label: UILabel!
    @IBOutlet weak var value300Label: UILabel!
    @IBOutlet weak var value500Label: UILabel!
    @IBOutlet weak var value800Label: UILabel!
    @IBOutlet weak var value1000Label: UILabel!
    @IBOutlet weak var value1500Label: UILabel!
    @IBOutlet weak var value2000Label: UILabel!
    @IBOutlet weak var value2500Label: UILabel!
    @IBOutlet weak var value3000Label: UILabel!
    @IBOutlet weak var value5000Label: UILabel!

    @IBOutlet weak var value100Cell: UITableViewCell!
    @IBOutlet weak var value300Cell: UITableViewCell!
    @IBOutlet weak var value500Cell: UITableViewCell!
    @IBOutlet weak var value800Cell: UITableViewCell!
    @IBOutlet weak var value1000Cell: UITableViewCell!
    @IBOutlet weak var value1500Cell: UITableViewCell!
    @IBOutlet weak var value2000Cell: UITableViewCell!
    @IBOutlet weak var value2500Cell: UITableViewCell!
    @IBOutlet weak var value3000Cell: UITableViewCell!
    @IBOutlet weak var value5000Cell: UITableViewCell!
    
    var allTitleLabels: [UILabel] {
        get {
            return [value100Label,
                    value300Label,
                    value500Label,
                    value800Label,
                    value1000Label,
                    value1500Label,
                    value2000Label,
                    value2500Label,
                    value3000Label,
                    value5000Label]
        }
    }
    
    var allValueCells: [UITableViewCell] {
        get {
            return [value100Cell,
                    value300Cell,
                    value500Cell,
                    value800Cell,
                    value1000Cell,
                    value1500Cell,
                    value2000Cell,
                    value2500Cell,
                    value3000Cell,
                    value5000Cell]
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("Bit rate view controller: viewDidLoad")
        
        for label: UILabel in allTitleLabels {
            label.font = UIFont.preferredFont(forTextStyle: .body)
            label.adjustsFontForContentSizeCategory = true
        }
        
        clearCheckmarks()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func clearCheckmarks() {
        for cell: UITableViewCell in allValueCells {
            cell.accessoryType = .none
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        clearCheckmarks()
        let cell = allValueCells[indexPath.row]
        cell.accessoryType = .checkmark
    }
    
}
