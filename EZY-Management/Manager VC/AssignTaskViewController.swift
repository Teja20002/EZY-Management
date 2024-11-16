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
        fetchEmployees()
        employeePicker.delegate = self
        employeePicker.dataSource = self
    }
    
    func fetchEmployees() {
        let db = Firestore.firestore()
        
        db.collection("users").whereField("role", isEqualTo: "employee").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error fetching employees: \(error.localizedDescription)")
                self.showAlert(title: "Error", message: "Could not load employee data. Please try again.")
            } else {
                self.employees = querySnapshot?.documents.compactMap { document in
                    guard let name = document.data()["name"] as? String else {
                        print("Missing name for employee: \(document.documentID)")
                        return nil
                    }
                    let id = document.documentID
                    print("Fetched Employee: \(name) with ID: \(id)")
                    return Employee(id: id, name: name)
                } ?? []
                
                if self.employees.isEmpty {
                    self.showAlert(title: "No Employees", message: "No employees found to assign tasks.")
                } else {
                    self.selectedEmployeeID = self.employees.first?.id
                }
                self.employeePicker.reloadAllComponents()
            }
        }
    }
    
    @IBAction func assignTaskButtonTapped(_ sender: UIButton) {
        guard let taskName = taskNameTextField.text, !taskName.isEmpty,
              let description = descriptionTextField.text, !description.isEmpty,
              let selectedEmployeeID = selectedEmployeeID else {
            showAlert(title: "Missing Information", message: "Please fill in all fields and select an employee.")
            return
        }
        
        fetchCurrentUserName { [weak self] userName in
            guard let self = self else { return }
            guard let userName = userName else {
                self.showAlert(title: "Error", message: "Unable to fetch your name. Please try again.")
                return
            }
            
            let priority = self.prioritySegmentControl.selectedSegmentIndex == 0 ? "High" : "Normal"
            
            let taskData: [String: Any] = [
                "taskName": taskName,
                "description": description,
                "assignedTo": selectedEmployeeID,
                "assignedBy": userName,  // Store the name instead of UID
                "createdAt": Timestamp(),
                "deadline": self.deadlineDatePicker.date,
                "priority": priority,
                "isCompleted": false
            ]
            
            let db = Firestore.firestore()
            
            db.collection("tasks").addDocument(data: taskData) { error in
                if let error = error {
                    print("Error assigning task: \(error.localizedDescription)")
                    self.showAlert(title: "Error", message: "Could not assign task. Please try again.")
                } else {
                    print("Task successfully assigned!")
                    self.showAlert(title: "Task Assigned", message: "Task has been successfully assigned.")
                    self.clearFields()
                }
            }
        }
    }
    
    func fetchCurrentUserName(completion: @escaping (String?) -> Void) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            completion(nil)
            return
        }
        
        let db = Firestore.firestore()
        db.collection("users").document(currentUserID).getDocument { document, error in
            if let error = error {
                print("Error fetching current user's name: \(error.localizedDescription)")
                completion(nil)
            } else if let document = document, document.exists {
                let userName = document.data()?["name"] as? String
                completion(userName)
            } else {
                print("User document not found.")
                completion(nil)
            }
        }
    }
    
    func clearFields() {
        taskNameTextField.text = ""
        descriptionTextField.text = ""
        deadlineDatePicker.date = Date()
        employeePicker.selectRow(0, inComponent: 0, animated: true)
        selectedEmployeeID = employees.first?.id
    }
    
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true)
    }
}

extension AssignTaskViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return employees.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return employees[row].name
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedEmployeeID = employees[row].id
        print("Selected Employee: \(employees[row].name) with ID: \(selectedEmployeeID ?? "")")
    }
}
