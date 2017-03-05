//
//  PlaceCell.swift
//  Spotty
//
//  Created by joseph mckee on 11/9/16.
//  Copyright © 2016 Cameron Eubank. All rights reserved.
//

import UIKit
import AlamofireImage

class PlaceCell: UICollectionViewCell {
    
    @IBOutlet weak var postImageView: UIImageView!
    
    var post: Post?{
        didSet{
            if let imageURL = post?.postMediaURL{
                if imageURL.contains(".png") || imageURL.contains(".jpg"){
                    postImageView.af_setImage(withURL: URL(string: imageURL)!, filter: AspectScaledToFillSizeFilter(size: postImageView.frame.size), imageTransition: .crossDissolve(0.1))
                }else if imageURL.contains(".mov"){
                    //postImageView.loadThumbnailImageForVideo(imageURL)
                    postImageView.image = UIImage(named: "whiteBoard")
                }
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

}
