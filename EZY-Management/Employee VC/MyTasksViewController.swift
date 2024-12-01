import UIKit
import Firebase

// Struct to represent tasks
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
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No user logged in")
            return
        }

        let db = Firestore.firestore()
        db.collection("tasks")
            .whereField("assignedTo", isEqualTo: userID)
            .getDocuments { (snapshot, error) in
                if let error = error {
                    print("Error fetching tasks: \(error.localizedDescription)")
                } else {
                    self.tasks = snapshot?.documents.compactMap { document in
                        let data = document.data()
                        // Debugging: Log task data from Firebase
                        print("Raw Task Data: \(data)")

                        // Safely parse task details
                        return AssignedTask(
                            taskID: document.documentID,
                            taskName: data["taskName"] as? String ?? "No Task Name",
                            description: data["description"] as? String ?? "No Description",
                            deadline: (data["deadline"] as? Timestamp)?.dateValue() ?? Date(),
                            isCompleted: data["isCompleted"] as? Bool ?? false
                        )
                    } ?? []
                    print("Tasks fetched: \(self.tasks)")
                    self.tableView.reloadData()
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
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
        cell.detailTextLabel?.text = "Deadline: \(formatter.string(from: task.deadline))"

        return cell
    }

    // MARK: - UITableViewDelegate Methods

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedTask = tasks[indexPath.row]
        print("Selected Task: \(selectedTask)") // Debugging
        performSegue(withIdentifier: "goToTaskDetails", sender: selectedTask)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToTaskDetails",
           let taskDetailsVC = segue.destination as? TaskDetailsViewController,
           let selectedTask = sender as? AssignedTask {
            print("Passing Task to TaskDetailsViewController: \(selectedTask)") // Debugging
            taskDetailsVC.task = [
                "taskID": selectedTask.taskID,
                "taskName": selectedTask.taskName,
                "description": selectedTask.description,
                "deadline": selectedTask.deadline,
                "isCompleted": selectedTask.isCompleted
            ]
        } else {
            print("Error: Failed to pass task data to TaskDetailsViewController.")
        }
    }
}
