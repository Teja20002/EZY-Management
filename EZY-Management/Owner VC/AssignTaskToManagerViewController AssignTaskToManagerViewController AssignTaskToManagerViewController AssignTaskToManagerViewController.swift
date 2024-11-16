import UIKit
import FirebaseFirestore
import FirebaseAuth

class AssignTaskToManager: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    @IBOutlet weak var taskNameTextField: UITextField!
    @IBOutlet weak var taskDescriptionTextView: UITextView!
    @IBOutlet weak var deadlineDatePicker: UIDatePicker!
    @IBOutlet weak var managerPicker: UIPickerView!  // Picker to select the manager
    @IBOutlet weak var prioritySegmentControl: UISegmentedControl! // Segment for selecting priority

    var managers: [(userID: String, name: String)] = [] // List of manager user IDs and their names
    var selectedManagerID: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Fetch the list of managers from Firestore
        fetchManagers()

        managerPicker.delegate = self
        managerPicker.dataSource = self
    }

    // Fetch the list of managers (user IDs with role "manager")
    func fetchManagers() {
        let db = Firestore.firestore()

        db.collection("users").whereField("role", isEqualTo: "manager").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error fetching managers: \(error.localizedDescription)")
            } else {
                self.managers = querySnapshot?.documents.compactMap { document in
                    // Fetch userID and name of the manager from Firestore
                    let userID = document.documentID
                    let name = document.data()["name"] as? String ?? "Unknown"
                    return (userID, name)
                } ?? []
                if self.managers.isEmpty {
                    print("No managers found")
                }
                self.managerPicker.reloadAllComponents() // Reload the picker view with manager names
            }
        }
    }

    // Action to handle assigning the task when button is pressed
    @IBAction func assignTaskButtonTapped(_ sender: UIButton) {
        guard let taskName = taskNameTextField.text, !taskName.isEmpty,
              let description = taskDescriptionTextView.text, !description.isEmpty,
              let selectedManagerID = selectedManagerID else {
            showAlert(title: "Missing Information", message: "Please fill in all fields.")
            return
        }

        // Get the deadline from the date picker
        let deadline = deadlineDatePicker.date

        // Get priority value from the segmented control (0 for High Priority, 1 for Normal)
        let priority = prioritySegmentControl.selectedSegmentIndex == 0 ? "High" : "Normal"

        // Call function to create the task
        createTask(taskName: taskName, description: description, deadline: deadline, assignedTo: selectedManagerID, priority: priority)
    }

    // Function to create a task in Firestore
    func createTask(taskName: String, description: String, deadline: Date, assignedTo: String, priority: String) {
        let db = Firestore.firestore()
        let newTaskRef = db.collection("tasks").document() // Auto-generate ID

        // Get the logged-in user's UID for the assignedBy field
        guard let ownerUserID = Auth.auth().currentUser?.uid else {
            print("Error: No user is logged in.")
            showAlert(title: "Error", message: "You must be logged in to assign tasks.")
            return
        }

        print("Creating Task with Data:")
        print("Task Name: \(taskName)")
        print("Description: \(description)")
        print("Assigned By (UID): \(ownerUserID)")
        print("Assigned To (UID): \(assignedTo)")
        print("Priority: \(priority)")
        print("Deadline: \(deadline)")

        let taskData: [String: Any] = [
            "taskID": newTaskRef.documentID,
            "taskName": taskName,
            "description": description,
            "assignedBy": ownerUserID, // The current logged-in owner
            "assignedTo": assignedTo, // The manager selected by the owner
            "createdAt": Timestamp(date: Date()),
            "deadline": Timestamp(date: deadline),
            "priority": priority,  // High or Normal priority
            "isCompleted": false
        ]

        newTaskRef.setData(taskData) { error in
            if let error = error {
                print("Error creating task: \(error.localizedDescription)")
                self.showAlert(title: "Error", message: "Failed to create task. Please try again.")
            } else {
                print("Task successfully created!")
                self.showAlert(title: "Task Created", message: "Task has been successfully created.")
                self.clearFields()
            }
        }
    }

    // Function to clear all fields after task is assigned
    func clearFields() {
        taskNameTextField.text = ""
        taskDescriptionTextView.text = ""
        deadlineDatePicker.date = Date()
        if !managers.isEmpty {
            managerPicker.selectRow(0, inComponent: 0, animated: true)
            selectedManagerID = managers[0].userID
        }
    }

    // MARK: - UIPickerViewDelegate & UIPickerViewDataSource
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1 // Only one component (column) for manager selection
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return managers.count // Number of managers
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        // Display manager names in the picker
        return managers[row].name
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // Set the selected manager user ID
        selectedManagerID = managers[row].userID
        print("Selected Manager: \(managers[row].name) with ID: \(managers[row].userID)")
    }

    // Helper function to show alerts
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true)
    }
}
