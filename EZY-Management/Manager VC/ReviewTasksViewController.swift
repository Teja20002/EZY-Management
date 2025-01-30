//
//  ReviewTasksViewController.swift
//  EZY-Management
//
//  Created by Teja Manchala on 12/19/24.
//

import UIKit
import FirebaseFirestore

class ReviewTasksViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!

    var submittedTasks: [[String: Any]] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        fetchSubmittedTasks()
        tableView.dataSource = self
        tableView.delegate = self
    }

    // Fetch Submitted Tasks
    private func fetchSubmittedTasks() {
        let db = Firestore.firestore()
        db.collection("tasks").whereField("isSubmitted", isEqualTo: true).getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching submitted tasks: \(error.localizedDescription)")
            } else {
                self.submittedTasks = snapshot?.documents.map { document in
                    var taskData = document.data()
                    taskData["taskID"] = document.documentID // Add the document ID
                    return taskData
                } ?? []
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        }
    }

    // TableView DataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return submittedTasks.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell", for: indexPath)
        let task = submittedTasks[indexPath.row]
        cell.textLabel?.text = task["taskName"] as? String ?? "No Task Name"
        cell.detailTextLabel?.text = task["description"] as? String ?? "No Description"
        return cell
    }

    // Handle Row Selection
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedTask = submittedTasks[indexPath.row]
        performSegue(withIdentifier: "showTaskDetailsSegue", sender: selectedTask)
    }

    // Pass Data to TaskDetailsForManagerViewController
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showTaskDetailsSegue",
           let taskDetailsVC = segue.destination as? TaskDetailsForManagerViewController,
           let task = sender as? [String: Any] {
            taskDetailsVC.task = task
        }
    }
}
