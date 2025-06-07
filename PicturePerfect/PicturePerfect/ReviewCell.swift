//
//  ReviewCell.swift
//  PicturePerfect
//
//  Created by Munir Emam on 6/4/25.
//

import UIKit

class ReviewCell: UICollectionViewCell {
    
    @IBOutlet weak var reviewImage: UIImageView!
    
    @IBOutlet weak var reviewUserName: UILabel!
    
    @IBOutlet weak var reviewContent: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        reviewImage.layer.cornerRadius
        reviewImage.frame.size.width / 2 
        reviewImage.clipsToBounds = true
    }
}
