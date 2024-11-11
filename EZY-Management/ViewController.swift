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
            print("Username or password field is empty")
            return
        }
        
        // Firebase Authentication: Sign in with email and password
        Auth.auth().signIn(withEmail: username, password: password) { authResult, error in
            if let error = error {
                print("Login failed: \(error.localizedDescription)")
                return
            }
            
            // Retrieve and pass user role after successful login
            self.getUserRole { role in
                self.userRole = role // Store role for segue
                self.performSegue(withIdentifier: "goToDashboard", sender: self)
            }
        }
    }
    
    // Function to retrieve the user's role from Firestore
    func getUserRole(completion: @escaping (String) -> Void) {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        db.collection("users").document(userID).getDocument { document, error in
            if let document = document, document.exists, let role = document.data()?["role"] as? String {
                completion(role)
            } else {
                print("Error fetching user role: \(error?.localizedDescription ?? "Unknown error")")
                completion("unknown") // Default to "unknown" if no role is found
            }
        }
    }
    
    // Prepare for segue to pass the user role
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToDashboard" {
            if let dashboardVC = segue.destination as? DashboardViewController {
                dashboardVC.userRole = userRole
            }
        }
    }
    
    // MARK: - Helper Method to Dismiss Keyboard
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
