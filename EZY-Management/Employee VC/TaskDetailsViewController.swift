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
    @IBOutlet weak var uploadPhotoButton: UIButton!

    var task: [String: Any]? {
        didSet {
            if isViewLoaded {
                configureView()
            }
        }
    }

    var uploadedPhotoURLs: [String] = [] // To store uploaded photo URLs

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        configureView()
    }

    // MARK: - Setup Methods
    private func setupCollectionView() {
        photoCollectionView.dataSource = self
        photoCollectionView.delegate = self
        let nib = UINib(nibName: "PhotoCollectionViewCell", bundle: nil)
        photoCollectionView.register(nib, forCellWithReuseIdentifier: "PhotoCell")
        print("CollectionView setup complete with nib registration.")
    }

    // MARK: - Configure View with Task Data
    private func configureView() {
        guard let task = task else {
            print("Task data is nil, skipping view configuration.")
            return
        }

        print("Configuring view with task: \(task)")

        taskNameLabel.text = task["taskName"] as? String ?? "No Task Name"
        taskDescriptionLabel.text = task["description"] as? String ?? "No Description"
        
        if let deadline = task["deadline"] as? Date {
            deadlineLabel.text = formattedDate(deadline)
        } else if let timestamp = task["deadline"] as? Timestamp {
            let deadline = timestamp.dateValue()
            deadlineLabel.text = formattedDate(deadline)
        } else {
            deadlineLabel.text = "No Deadline"
        }

        if let assignedBy = task["assignedBy"] as? [String: Any],
           let name = assignedBy["name"] as? String {
            assignedByLabel.text = "Assigned By: \(name)"
        } else {
            assignedByLabel.text = task["assignedBy"] as? String ?? "Assigned By: Unknown"
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
        return formatter.string(from: date)
    }

    // MARK: - Upload Photo
    @IBAction func uploadPhotoTapped(_ sender: UIButton) {
        print("Upload Photo button tapped!")

        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.mediaTypes = ["public.image"]
            picker.allowsEditing = true
            present(picker, animated: true)
        } else {
            print("Photo library is not available.")
        }
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
        guard let taskID = task?["taskID"] as? String else {
            print("Error: Task ID missing.")
            return
        }

        let db = Firestore.firestore()
        db.collection("tasks").document(taskID).updateData([
            "isSubmitted": true,
            "uploadedPhotos": uploadedPhotoURLs
        ]) { error in
            if let error = error {
                print("Error submitting task: \(error.localizedDescription)")
                self.showAlert(title: "Error", message: "Failed to submit the task. Please try again.")
            } else {
                print("Task submitted successfully!")
                DispatchQueue.main.async {
                    self.showAlert(title: "Success", message: "Task submitted for review.") {
                        self.closeScreen()
                    }
                }
            }
        }
    }

    private func closeScreen() {
        if let navigationController = self.navigationController {
            navigationController.popViewController(animated: true)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }

    // MARK: - Alert Helper
    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            completion?()
        }))
        present(alert, animated: true)
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
                } else {
                    DispatchQueue.main.async {
                        cell.photoImageView.image = UIImage(named: "placeholder")
                    }
                }
            }
        }
        return cell
    }
}
