//
//  AssignTaskToManagerViewController AssignTaskToManagerViewController AssignTaskToManagerViewController AssignTaskToManagerViewController.swift
//  EZY-Management
//
//  Created by Teja Manchala on 11/11/24.
//

// Controlled by OWNER


import UIKit
import FirebaseFirestore

class AssignTaskToManager: UIViewController {

    
    @IBOutlet weak var taskNameTextField: UITextField!
    
    @IBOutlet weak var taskDescriptionTextView: UITextView!
    
    @IBOutlet weak var deadlineDatePicker: UIDatePicker!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    @IBAction func assignTaskButtonTapped(_ sender: UIButton) {
        guard let taskName = taskNameTextField.text, !taskName.isEmpty,
                     let description = taskDescriptionTextView.text, !description.isEmpty else {
                   print("Task name and description are required")
                   return
               }
               
               let deadline = deadlineDatePicker.date
               let assignedTo = "managerUserID" // Replace with the actual Manager's userID selected from a list, if available.
               
               createTask(taskName: taskName, description: description, deadline: deadline, assignedTo: assignedTo)
           }
           
           func createTask(taskName: String, description: String, deadline: Date, assignedTo: String) {
               let db = Firestore.firestore()
               let newTaskRef = db.collection("tasks").document() // Auto-generate ID
               
               let taskData: [String: Any] = [
                   "taskID": newTaskRef.documentID,
                   "taskName": taskName,
                   "description": description,
                   "assignedBy": "ownerUserID", // Replace with actual Owner's userID
                   "assignedTo": assignedTo,
                   "createdAt": Timestamp(date: Date()),
                   "deadline": Timestamp(date: deadline),
                   "isCompleted": false
               ]
               
               newTaskRef.setData(taskData) { error in
                   if let error = error {
                       print("Error creating task: \(error)")
                   } else {
                       print("Task successfully created")
                       self.clearFields()
                   }
               }
           }
           
           func clearFields() {
               taskNameTextField.text = ""
               taskDescriptionTextView.text = ""
               deadlineDatePicker.date = Date()
           }
    

}
