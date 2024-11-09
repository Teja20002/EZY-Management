//
//  ViewController.swift
//  EZY-Management
//
//  Created by Teja Manchala on 11/9/24.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        
    }
    
    @IBOutlet weak var usernameTextField: UITextField!
    
    @IBOutlet weak var passwordTextField: UITextField!
    

    @IBAction func loginButtonTapped(_ sender: UIButton) {
        // Check if both text fields are not empty
            guard let username = usernameTextField.text, !username.isEmpty,
                  let password = passwordTextField.text, !password.isEmpty else {
                print("Username or password field is empty")
                return
            }
            
            // Proceed with login (we'll add more functionality here later)
            print("Logging in with username: \(username) and password: \(password)")
    }
    
    
}

