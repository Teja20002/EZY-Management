import UIKit
import Firebase

// Define a struct to store employee name and ID
struct Employee {
    let id: String
    let name: String
}

class AssignTaskViewController: UIViewController {
    
    @IBOutlet weak var taskNameTextField: UITextField!
    @IBOutlet weak var descriptionTextField: UITextField!
    @IBOutlet weak var deadlineDatePicker: UIDatePicker!
    @IBOutlet weak var employeePicker: UIPickerView!
    @IBOutlet weak var prioritySegmentControl: UISegmentedControl!
    
    var employees: [Employee] = [] // List of employee objects
    var selectedEmployeeID: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Fetch the list of employees to display in the picker
        fetchEmployees()
        
        employeePicker.delegate = self
        employeePicker.dataSource = self
    }
    
    // Fetch the list of employees (user IDs with role "employee")
    func fetchEmployees() {
        let db = Firestore.firestore()
        
        db.collection("users").whereField("role", isEqualTo: "employee").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error fetching employees: \(error.localizedDescription)")
            } else {
                self.employees = querySnapshot?.documents.compactMap { document in
                    // Fetch employee name and ID
                    let name = document.data()["name"] as? String ?? "Unknown"
                    let id = document.documentID
                    return Employee(id: id, name: name)
                } ?? []
                
                self.employeePicker.reloadAllComponents() // Reload the picker with employee names
            }
        }
    }
    
    // Action to handle assigning the task when button is pressed
    @IBAction func assignTaskButtonTapped(_ sender: UIButton) {
        guard let taskName = taskNameTextField.text, !taskName.isEmpty,
              let description = descriptionTextField.text, !description.isEmpty,
              let selectedEmployeeID = selectedEmployeeID else {
            showAlert(title: "Missing Information", message: "Please fill in all fields.")
            return
        }
        
        // Get priority value from the segmented control (0 for High Priority, 1 for Normal)
        let priority = prioritySegmentControl.selectedSegmentIndex == 0 ? "High" : "Normal"
        
        // Define task data
        let taskData: [String: Any] = [
            "taskName": taskName,
            "description": description,
            "assignedTo": selectedEmployeeID,  // Employee selected by the manager
            "assignedBy": Auth.auth().currentUser?.uid ?? "",  // The current logged-in manager
            "createdAt": Timestamp(),
            "deadline": deadlineDatePicker.date,
            "priority": priority,  // High or Normal priority
            "isCompleted": false
        ]
        
        let db = Firestore.firestore()
        
        // Add task to Firestore
        db.collection("tasks").addDocument(data: taskData) { error in
            if let error = error {
                print("Error assigning task: \(error.localizedDescription)")
            } else {
                print("Task successfully assigned!")
                // Optionally: show an alert or navigate back
                self.showAlert(title: "Task Assigned", message: "Task has been successfully assigned.")
            }
        }
    }
    
    // Helper method to show alerts
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true)
    }
}

extension AssignTaskViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1  // Single column for employee selection
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return employees.count  // Number of employees
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        // Display employee names in the picker
        return employees[row].name
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // Set the selected employee ID
        selectedEmployeeID = employees[row].id
    }
}
