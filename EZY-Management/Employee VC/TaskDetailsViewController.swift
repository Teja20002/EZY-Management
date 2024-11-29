import UIKit
import Firebase
import FirebaseFirestore
import FirebaseStorage

class TaskDetailsViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate {

    @IBOutlet weak var taskNameLabel: UILabel!
    @IBOutlet weak var taskDescriptionLabel: UILabel!
    @IBOutlet weak var deadlineLabel: UILabel!
    @IBOutlet weak var assignedByLabel: UILabel!
    @IBOutlet weak var photoCollectionView: UICollectionView!
    @IBOutlet weak var submitTaskButton: UIButton!

    var task: [String: Any] = [:] // Task data passed to this view
    var uploadedPhotoURLs: [String] = [] // To store uploaded photo URLs

    override func viewDidLoad() {
        super.viewDidLoad()

        // Configure the view once, since task is already set
        configureView()
        setupCollectionView()
    }

    // MARK: - Setup Methods
    private func setupCollectionView() {
        photoCollectionView.dataSource = self
        photoCollectionView.delegate = self
        photoCollectionView.register(UINib(nibName: "PhotoCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "PhotoCell")
    }

    // MARK: - Configure View with Task Data
    private func configureView() {
        print("Configuring view with task: \(task)")

        // Task Name
        taskNameLabel.text = task["taskName"] as? String ?? "No Task Name"

        // Task Description
        taskDescriptionLabel.text = task["description"] as? String ?? "No Description"

        // Deadline
        if let deadline = task["deadline"] as? Date {
            deadlineLabel.text = formattedDate(deadline)
        } else {
            deadlineLabel.text = "No Deadline"
        }

        // Assigned By
        assignedByLabel.text = task["assignedBy"] as? String ?? "Assigned By: Unknown"
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
        return formatter.string(from: date)
    }

    // MARK: - Upload Photo
    @IBAction func uploadPhotoTapped(_ sender: UIButton) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.mediaTypes = ["public.image"]
        picker.allowsEditing = true
        present(picker, animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let image = info[.editedImage] as? UIImage {
            uploadPhoto(image: image)
        }
        dismiss(animated: true)
    }

    private func uploadPhoto(image: UIImage) {
        let storageRef = Storage.storage().reference()
        let fileName = UUID().uuidString
        let photoRef = storageRef.child("taskPhotos/\(fileName).jpg")

        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("Error: Unable to compress image.")
            return
        }

        photoRef.putData(imageData, metadata: nil) { [weak self] _, error in
            if let error = error {
                print("Error uploading photo: \(error.localizedDescription)")
                return
            }

            photoRef.downloadURL { url, _ in
                guard let url = url else {
                    print("Error: Unable to get download URL.")
                    return
                }

                self?.uploadedPhotoURLs.append(url.absoluteString)
                DispatchQueue.main.async {
                    self?.photoCollectionView.reloadData()
                }
            }
        }
    }

    // MARK: - Submit Task
    @IBAction func submitTaskTapped(_ sender: UIButton) {
        submitTask()
    }

    private func submitTask() {
        guard let taskID = task["taskID"] as? String else {
            print("Error: Task ID missing.")
            return
        }

        let db = Firestore.firestore()
        db.collection("tasks").document(taskID).updateData([
            "isCompleted": true,
            "uploadedPhotos": uploadedPhotoURLs
        ]) { error in
            if let error = error {
                print("Error updating task: \(error.localizedDescription)")
            } else {
                print("Task marked as completed!")
                DispatchQueue.main.async {
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
    }

    // MARK: - Collection View Data Source
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return uploadedPhotoURLs.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as? PhotoCollectionViewCell else {
            fatalError("Error: Unable to dequeue PhotoCollectionViewCell.")
        }

        let photoURL = uploadedPhotoURLs[indexPath.item]
        if let url = URL(string: photoURL) {
            DispatchQueue.global().async {
                if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        cell.photoImageView.image = image
                    }
                }
            }
        }

        return cell
    }
}

// MARK: - Custom UICollectionViewCell
class PhotoCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var photoImageView: UIImageView!
}
