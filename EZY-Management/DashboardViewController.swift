//
//  DashboardViewController.swift
//  EZY-Management
//
//  Created by Teja Manchala on 11/10/24.
//

import Foundation
import UIKit

class DashboardViewController: UIViewController {
    
    @IBOutlet weak var ownerButton: UIButton!
    @IBOutlet weak var supervisorButton: UIButton!
    @IBOutlet weak var managerButton: UIButton!
    @IBOutlet weak var employeeButton: UIButton!
    
    var userRole: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        print("Dashboard view loaded")
        // Configure dashboard based on user role
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

        // Show the appropriate button or directly navigate based on role
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
    // Inside DashboardViewController

    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true)
    }

}
