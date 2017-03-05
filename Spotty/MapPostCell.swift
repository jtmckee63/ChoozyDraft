////
////  MapPostCell.swift
////  Spotty
////
////  Created by Cameron Eubank on 9/5/16.
////  Copyright © 2016 Cameron Eubank. All rights reserved.
////
//
//import UIKit
//import AVFoundation
//import AlamofireImage
//
//class MapPostCell: UICollectionViewCell {
//    
//    @IBOutlet var postInfoLabel: UILabel!
//    @IBOutlet var postImageView: UIImageView!
//    
//    var post: Post?{
//        didSet{
//            if let imageURL = post?.postMediaURL{
//                if imageURL.contains(".png") || imageURL.contains(".jpg"){
//                    postImageView.af_setImage(withURL: URL(string: imageURL)!, placeholderImage: UIImage(named: "board"), filter: AspectScaledToFillSizeCircleFilter(size: self.postImageView.frame.size), imageTransition: .crossDissolve(0.1))
//                }else if imageURL.contains(".mov"){
//                    let boardURLString = "https://firebasestorage.googleapis.com/v0/b/spotty-77551.appspot.com/o/default_images%2Fboard.png?alt=media&token=8c68e123-3cab-4f84-b455-5347d25f921c"
//                    postImageView.af_setImage(withURL: URL(string: boardURLString)!, placeholderImage: UIImage(named: "board"), filter: AspectScaledToFillSizeCircleFilter(size: self.postImageView.frame.size), imageTransition: .crossDissolve(0.1))
//                }
//            }
//            
//            if let comment = post?.comment, let date = post?.timeStamp{
//                if comment != ""{
//                    postInfoLabel.text = comment
//                }else{
//                    postInfoLabel.text = getDateStringFromNumber(date)
//                }
//            }
//        }
//    }
//    
//    override func awakeFromNib() {
//        super.awakeFromNib()
//        backgroundColor = UIColor.purple.flat
//        postInfoLabel.textColor = UIColor.white
//    }
//
//}
