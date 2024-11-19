import UIKit
import FirebaseFirestore
import FirebaseAuth

class AssignTaskToManager: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    @IBOutlet weak var taskNameTextField: UITextField!
    @IBOutlet weak var taskDescriptionTextView: UITextView!
    @IBOutlet weak var deadlineDatePicker: UIDatePicker!
    @IBOutlet weak var managerPicker: UIPickerView!
    @IBOutlet weak var prioritySegmentControl: UISegmentedControl!

    var managers: [(userID: String, name: String)] = [] // List of manager user IDs and their names
    var selectedManagerID: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        fetchManagers()
        managerPicker.delegate = self
        managerPicker.dataSource = self
    }

    // MARK: - Fetch Managers
    func fetchManagers() {
        let db = Firestore.firestore()
        db.collection("users").whereField("role", isEqualTo: "manager").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error fetching managers: \(error.localizedDescription)")
            } else {
                self.managers = querySnapshot?.documents.compactMap { document in
                    let userID = document.documentID
                    let name = document.data()["name"] as? String ?? "Unknown"
                    return (userID, name)
                } ?? []
                print("Fetched \(self.managers.count) managers.")
                if self.managers.isEmpty {
                    print("No managers found.")
                } else {
                    self.selectedManagerID = self.managers.first?.userID
                }
                self.managerPicker.reloadAllComponents()
            }
        }
    }

    // MARK: - Assign Task Button Action
    @IBAction func assignTaskButtonTapped(_ sender: UIButton) {
        guard let taskName = taskNameTextField.text, !taskName.isEmpty,
              let description = taskDescriptionTextView.text, !description.isEmpty,
              let selectedManagerID = selectedManagerID else {
            showAlert(title: "Missing Information", message: "Please fill in all fields.")
            return
        }

        let deadline = deadlineDatePicker.date
        let priority = prioritySegmentControl.selectedSegmentIndex == 0 ? "High" : "Normal"

        createTaskWithOwnerName(taskName: taskName, description: description, deadline: deadline, assignedTo: selectedManagerID, priority: priority)
    }

    // MARK: - Create Task
    func createTaskWithOwnerName(taskName: String, description: String, deadline: Date, assignedTo: String, priority: String) {
        let db = Firestore.firestore()
        let newTaskRef = db.collection("tasks").document()

        fetchCurrentUserName { [weak self] ownerName in
            guard let self = self, let ownerName = ownerName else {
                self?.showAlert(title: "Error", message: "Unable to fetch your name. Please try again.")
                return
            }

            print("Creating Task with Data:")
            print("Task Name: \(taskName)")
            print("Description: \(description)")
            print("Assigned By (Owner Name): \(ownerName)")
            print("Assigned To (UID): \(assignedTo)")
            print("Priority: \(priority)")
            print("Deadline: \(deadline)")

            let taskData: [String: Any] = [
                "taskID": newTaskRef.documentID,
                "taskName": taskName,
                "description": description,
                "assignedBy": ownerName, // Owner's name
                "assignedTo": assignedTo,
                "createdAt": Timestamp(date: Date()),
                "deadline": Timestamp(date: deadline),
                "priority": priority,
                "isCompleted": false
            ]

            newTaskRef.setData(taskData) { error in
                if let error = error {
                    print("Error creating task: \(error.localizedDescription)")
                    self.showAlert(title: "Error", message: "Could not create task. Please try again.")
                } else {
                    print("Task successfully assigned to manager!")
                    self.showAlert(title: "Success", message: "Task successfully assigned.")
                    self.clearFields()
                }
            }
        }
    }

    // MARK: - Fetch Current User Name
    func fetchCurrentUserName(completion: @escaping (String?) -> Void) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            print("Error: No logged-in user.")
            completion(nil)
            return
        }

        print("Fetching name for user ID: \(currentUserID)")

        let db = Firestore.firestore()
        db.collection("users").document(currentUserID).getDocument { document, error in
            if let error = error {
                print("Error fetching current user's name: \(error.localizedDescription)")
                completion(nil)
            } else if let document = document, document.exists {
                let userName = document.data()?["name"] as? String
                if let userName = userName {
                    print("Fetched user name: \(userName)")
                } else {
                    print("Name field is missing in user document.")
                }
                completion(userName)
            } else {
                print("User document not found for ID: \(currentUserID)")
                completion(nil)
            }
        }
    }

    // MARK: - Clear Fields
    func clearFields() {
        taskNameTextField.text = ""
        taskDescriptionTextView.text = ""
        deadlineDatePicker.date = Date()
        if !managers.isEmpty {
            managerPicker.selectRow(0, inComponent: 0, animated: true)
            selectedManagerID = managers[0].userID
        }
    }

    // MARK: - Picker View Data Source & Delegate
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return managers.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return managers[row].name
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedManagerID = managers[row].userID
        print("Selected Manager: \(managers[row].name) with ID: \(managers[row].userID)")
    }

    // MARK: - Show Alert
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true)
    }
}
