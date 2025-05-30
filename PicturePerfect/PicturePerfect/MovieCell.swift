//
//  MovieCell.swift
//  PicturePerfect
//
//  Created by Munir Emam on 5/29/25.
//
import UIKit
class MovieCell: UICollectionViewCell {
    // Connect this outlet to the UIImageView in your storyboard
    @IBOutlet weak var yearLabel: UILabel!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var backdropImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        layer.cornerRadius = 12
        layer.masksToBounds = true
    }
}
