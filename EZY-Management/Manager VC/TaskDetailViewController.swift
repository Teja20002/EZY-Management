import UIKit

class TaskDetailViewController: UIViewController {
    @IBOutlet weak var taskNameLabel: UILabel!
    @IBOutlet weak var taskDescriptionLabel: UILabel!
    @IBOutlet weak var deadlineLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!

    var task: Task?

    override func viewDidLoad() {
        super.viewDidLoad()
        displayTaskDetails()
    }

    func displayTaskDetails() {
        guard let task = task else { return }
        taskNameLabel.text = task.taskName
        taskDescriptionLabel.text = task.description
        deadlineLabel.text = "Deadline: \(task.deadline)"
        statusLabel.text = task.isCompleted ? "Completed" : "Not Completed"
    }
}
