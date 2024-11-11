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
        
        // Configure dashboard based on user role
        configureDashboard(for: userRole)
    }
    
    func configureDashboard(for role: String?) {
        guard let role = role else { return }
        
        // Disable all buttons initially
        ownerButton.isEnabled = false
        supervisorButton.isEnabled = false
        managerButton.isEnabled = false
        employeeButton.isEnabled = false

        // Enable the button(s) according to the role
        switch role {
        case "owner":
            ownerButton.isEnabled = true
        case "supervisor":
            supervisorButton.isEnabled = true
        case "manager":
            managerButton.isEnabled = true
        case "employee":
            employeeButton.isEnabled = true
        default:
            print("Unknown role")
        }
    }
}
