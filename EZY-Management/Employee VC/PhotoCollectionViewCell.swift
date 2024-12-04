//
//  PhotoCollectionViewCell.swift
//  EZY-Management
//
//  Created by Teja Manchala on 12/2/24.
//

import UIKit

class PhotoCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var photoImageView: UIImageView!

    override func prepareForReuse() {
        super.prepareForReuse()
        photoImageView.image = UIImage(named: "placeholder")
    }


override func awakeFromNib() {
    super.awakeFromNib()
    if photoImageView == nil {
        print("photoImageView is nil in awakeFromNib!")
    }
}
}
