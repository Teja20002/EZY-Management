//
//  TaskDetailsForManagerViewController.swift
//  EZY-Management
//

import UIKit
import FirebaseFirestore

class TaskDetailsForManagerViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet weak var taskNameLabel: UILabel!
    @IBOutlet weak var taskDescriptionLabel: UILabel!
    @IBOutlet weak var photosCollectionView: UICollectionView!
    
    var task: [String: Any]?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        photosCollectionView.dataSource = self
        photosCollectionView.delegate = self
        
        // Register the cell if using a NIB
        let nib = UINib(nibName: "PhotoCollectionViewCell", bundle: nil)
        photosCollectionView.register(nib, forCellWithReuseIdentifier: "PhotoCell")
        
        fetchTaskDetails()
    }

    private func fetchTaskDetails() {
        guard let taskID = task?["taskID"] as? String else { return }
        let db = Firestore.firestore()

        db.collection("tasks").document(taskID).getDocument { snapshot, error in
            if let error = error {
                print("Error fetching task: \(error.localizedDescription)")
            } else if let data = snapshot?.data() {
                print("Fetched task data: \(data)")
                self.task = data
                DispatchQueue.main.async {
                    self.configureView()
                }
            }
        }
    }

    private func configureView() {
        guard let task = task else { return }
        taskNameLabel.text = task["taskName"] as? String ?? "No Task Name"
        taskDescriptionLabel.text = task["description"] as? String ?? "No Description"
        photosCollectionView.reloadData()
    }

    @objc func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let photos = task?["uploadedPhotos"] as? [String] ?? []
        return photos.count
    }

    @objc(collectionView:cellForItemAtIndexPath:) func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as? PhotoCollectionViewCell else {
            fatalError("Unable to dequeue PhotoCell")
        }
        
        let photos = task?["uploadedPhotos"] as? [String] ?? []
        let photoURL = photos[indexPath.row]

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
