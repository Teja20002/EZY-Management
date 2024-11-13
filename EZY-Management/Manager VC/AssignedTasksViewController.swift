import UIKit
import FirebaseFirestore
import FirebaseAuth

struct Task {
    let taskID: String
    let taskName: String
    let description: String
    let deadline: Date
    let isCompleted: Bool
}

class AssignedTasksViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    var tasks: [Task] = [] // Array to hold fetched tasks
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        
        // Fetch tasks from Firestore
        fetchTasks()
    }
    
    // MARK: - Table View Data Source Methods
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tasks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("Configuring cell for row \(indexPath.row)")
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell", for: indexPath)
        let task = tasks[indexPath.row]
        cell.textLabel?.text = task.taskName
        cell.detailTextLabel?.text = "Deadline: \(task.deadline)"
        return cell
    }
    
    // MARK: - Navigation to Task Detail
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showTaskDetail" {
            if let destinationVC = segue.destination as? TaskDetailViewController,
               let indexPath = tableView.indexPathForSelectedRow {
                destinationVC.task = tasks[indexPath.row]
            }
        }
    }
}

// MARK: - Firestore Data Fetching

extension AssignedTasksViewController {

    func fetchTasks() {
            let db = Firestore.firestore()
            
            // Retrieve the current user's ID
            guard let currentUserID = Auth.auth().currentUser?.uid else {
                print("Error: No current user ID found")
                return
            }
            
            print("Fetching tasks for user ID: \(currentUserID)")

            // Query Firestore to get tasks assigned to the current user (manager)
            db.collection("tasks").whereField("assignedTo", isEqualTo: currentUserID).getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching tasks: \(error.localizedDescription)")
                    return
                }
                
                print("Fetched \(snapshot?.documents.count ?? 0) tasks")
                
                // Convert documents to Task objects
                self.tasks = snapshot?.documents.compactMap { document in
                    let data = document.data()
                    print("Document data: \(data)") // Debug each document’s data
                    
                    return Task(
                        taskID: document.documentID,
                        taskName: data["taskName"] as? String ?? "",
                        description: data["description"] as? String ?? "",
                        deadline: (data["deadline"] as? Timestamp)?.dateValue() ?? Date(),
                        isCompleted: data["isCompleted"] as? Bool ?? false
                    )
                } ?? []
                
                print("Loaded tasks into array: \(self.tasks.count)")
                
                self.tableView.reloadData() // Reload the table view with the new data
            }
        }
}
