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
            present(picker, animated: true) {
                print("Image picker presented!")
            }
        } else {
            print("Photo library is not available.")
        }
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let image = info[.editedImage] as? UIImage {
            print("Image selected for upload!")
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

        print("Uploading photo...")
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
                print("Photo uploaded successfully: \(url.absoluteString)")
            }
        }
    }

    // MARK: - Submit Task
    @IBAction func submitTaskTapped(_ sender: UIButton) {
        print("Submit Task Button Tapped")
        submitTask()
    }

    private func submitTask() {
        guard let taskID = task?["taskID"] as? String else {
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
        print("Dequeuing cell for index: \(indexPath.item)")
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as? PhotoCollectionViewCell else {
            fatalError("Error: Unable to dequeue PhotoCollectionViewCell.")
        }

        print("Cell dequeued successfully.")
        let photoURL = uploadedPhotoURLs[indexPath.item]
        print("Setting image for photo URL: \(photoURL)")

        if let url = URL(string: photoURL) {
            DispatchQueue.global().async {
                if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        if cell.photoImageView == nil {
                            print("Error: photoImageView is nil!")
                        } else {
                            print("Successfully setting the image.")
                            cell.photoImageView.image = image
                        }
                    }
                } else {
                    print("Error: Failed to load image from URL \(photoURL)")
                    DispatchQueue.main.async {
                        cell.photoImageView.image = UIImage(named: "placeholder")
                    }
                }
            }
        } else {
            print("Error: Invalid URL \(photoURL)")
            cell.photoImageView.image = UIImage(named: "placeholder")
        }
        
        
        return cell
    }
}
