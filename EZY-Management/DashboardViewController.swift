import UIKit
import FirebaseFirestore
import FirebaseAuth

class DashboardViewController: UIViewController {
    
    @IBOutlet weak var ownerButton: UIButton!
    @IBOutlet weak var supervisorButton: UIButton!
    @IBOutlet weak var managerButton: UIButton!
    @IBOutlet weak var employeeButton: UIButton!
    
    var userRole: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        print("Dashboard view loaded")
        configureDashboard(for: userRole)
    }
    
    func configureDashboard(for role: String?) {
        guard let role = role else {
            showAlert(title: "Role Error", message: "User role could not be determined. Please contact support.")
            return
        }
        
        // Hide all buttons initially
        ownerButton.isHidden = true
        supervisorButton.isHidden = true
        managerButton.isHidden = true
        employeeButton.isHidden = true
        
        // Show the appropriate button and navigate based on role
        switch role {
        case "owner":
            ownerButton.isHidden = false
        case "supervisor":
            supervisorButton.isHidden = false
        case "manager":
            managerButton.isHidden = false
        case "employee":
            employeeButton.isHidden = false
        default:
            showAlert(title: "Role Error", message: "User role is not recognized. Please contact support.")
        }
    }
    
    // MARK: - Button Actions for Navigation
    @IBAction func ownerButtonTapped(_ sender: UIButton) {
        navigateToViewController(identifier: "OwnerViewController")
    }
    
    @IBAction func supervisorButtonTapped(_ sender: UIButton) {
        navigateToViewController(identifier: "SupervisorViewController")
    }
    
    @IBAction func managerButtonTapped(_ sender: UIButton) {
        navigateToViewController(identifier: "ManagerViewController")
    }
    
    @IBAction func employeeButtonTapped(_ sender: UIButton) {
        navigateToViewController(identifier: "EmployeeViewController")
    }
    
    func navigateToViewController(identifier: String) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let destinationVC = storyboard.instantiateViewController(withIdentifier: identifier) as? UIViewController else {
            print("Error: Could not instantiate view controller with identifier \(identifier)")
            return
        }
        self.navigationController?.pushViewController(destinationVC, animated: true)
    }
    
    // Helper function to show alerts
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true)
    }
}
