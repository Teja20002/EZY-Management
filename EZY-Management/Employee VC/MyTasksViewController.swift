import UIKit
import Firebase

// Rename Task struct to avoid ambiguity
struct AssignedTask {
    let taskID: String
    let taskName: String
    let description: String
    let deadline: Date
    let isCompleted: Bool
}

class MyTasksViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    var tasks: [AssignedTask] = [] // Array to store tasks for the employee
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Set up the table view
        tableView.dataSource = self
        tableView.delegate = self

        // Fetch tasks for the current logged-in employee
        fetchEmployeeTasks()
    }
    
    func fetchEmployeeTasks() {
        // Fetch current user ID
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No user logged in")
            return
        }
        
        let db = Firestore.firestore()
        
        // Query tasks where the employee is assigned
        db.collection("tasks")
            .whereField("assignedTo", isEqualTo: userID)
            .getDocuments { (snapshot, error) in
                if let error = error {
                    print("Error fetching tasks: \(error.localizedDescription)")
                } else {
                    self.tasks = snapshot?.documents.compactMap { document in
                        let data = document.data()
                        return AssignedTask(
                            taskID: document.documentID,
                            taskName: data["taskName"] as? String ?? "",
                            description: data["description"] as? String ?? "",
                            deadline: (data["deadline"] as? Timestamp)?.dateValue() ?? Date(),
                            isCompleted: data["isCompleted"] as? Bool ?? false
                        )
                    } ?? []
                    self.tableView.reloadData() // Reload table with tasks
                }
            }
    }
    
    // MARK: - UITableViewDataSource Methods

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tasks.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell", for: indexPath)
        
        let task = tasks[indexPath.row]
        
        // Configure cell with task details
        cell.textLabel?.text = task.taskName
        cell.detailTextLabel?.text = "Deadline: \(task.deadline)"
        
        return cell
    }
    
    // MARK: - UITableViewDelegate Methods

    // Handle task selection if needed
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // You can add functionality to show task details or allow task completion
    }
}
