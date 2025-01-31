import UIKit
import Firebase

class ViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    var userRole: String? // Variable to store the user role for the segue

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set text field delegates
        usernameTextField.delegate = self
        passwordTextField.delegate = self
        
        // Tap gesture to dismiss keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Action for Login Button
    @IBAction func loginButtonTapped(_ sender: UIButton) {
        guard let username = usernameTextField.text, !username.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            showAlert(title: "Login Error", message: "Please enter both email and password.")
            return
        }
        
        // Firebase Authentication: Sign in with email and password
        Auth.auth().signIn(withEmail: username, password: password) { authResult, error in
            if let error = error {
                // Show alert if login fails
                self.showAlert(title: "Login Failed", message: error.localizedDescription)
                return
            }
            
            // If login is successful, retrieve and pass the user role
            self.getUserRole { role in
                self.userRole = role
                self.performSegue(withIdentifier: "goToDashboard", sender: self)
            }
        }
    }
    
    // Function to retrieve the user's role from Firestore
    func getUserRole(completion: @escaping (String) -> Void) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("Error: No current user ID found")
            return
        }
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userID)
        
        userRef.getDocument { document, error in
            if let error = error {
                print("Error fetching user role: \(error.localizedDescription)")
                completion("unknown")
                return
            }
            
            if let document = document, document.exists, let role = document.data()?["role"] as? String {
                completion(role) // Role fetched successfully
            } else {
                print("Error: Role not found or document does not exist")
                completion("unknown") // Default to unknown if no role is found
            }
        }
    }
    
    // Show popup with role-based message
    func showRolePopup(role: String) {
        let roleMessage: String
        
        switch role {
        case "owner":
            roleMessage = "Owner login successful!"
        case "supervisor":
            roleMessage = "Supervisor login successful!"
        case "manager":
            roleMessage = "Manager login successful!"
        case "employee":
            roleMessage = "Employee login successful!"
        default:
            roleMessage = "Role could not be determined."
        }
        
        let alert = UIAlertController(title: "Role Confirmation", message: roleMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            // After user acknowledges the role, navigate to the dashboard
            if role != "unknown" {
                self.performSegue(withIdentifier: "goToDashboard", sender: self)
            } else {
                self.showAlert(title: "Role Error", message: "User role could not be determined. Please contact support.")
            }
        }))
        
        self.present(alert, animated: true)
    }
    
    // Prepare for segue to pass the user role
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToDashboard" {
            if let dashboardVC = segue.destination as? DashboardViewController {
                dashboardVC.userRole = userRole
            }
        }
    }
    
    // MARK: - Helper Method to Show Alerts
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true)
    }
    
    // MARK: - Helper Method to Dismiss Keyboard
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
