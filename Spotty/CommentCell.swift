//
//  CommentCell.swift
//  Spotty
//
//  Created by Cameron Eubank on 9/5/16.
//  Copyright © 2016 Cameron Eubank. All rights reserved.
//

import UIKit
import Alamofire
import AlamofireImage

class CommentCell: UITableViewCell {
    
    @IBOutlet var backgroundUnderlayView: UIView!
    @IBOutlet var commentUserImageView: UIImageView!
    @IBOutlet var commentAuthorLabel: UILabel!
    @IBOutlet var commentLabel: UILabel!
    
    var comment: Comment?{
        didSet{
            if let commentContent = comment?.comment, let commentProfileImageURL = comment?.profileImageURL, let commentAuthorName = comment?.userName, let commentTimeStamp = comment?.timeStamp{
                let nameString = NSAttributedString(string:commentAuthorName, attributes: [NSForegroundColorAttributeName: UIColor.white.pure, NSFontAttributeName: UIFont.init(name: "Jellee-Roman", size: 13.0)!])
                let dateString = NSAttributedString(string: "  •  " + getDateStringFromNumber(commentTimeStamp), attributes: [NSForegroundColorAttributeName: UIColor(r: 220, g: 220, b: 220), NSFontAttributeName: UIFont.init(name: "Jellee-Roman", size: 12.0)!])
                let nameDateString = NSMutableAttributedString()
                nameDateString.append(nameString)
                nameDateString.append(dateString)
        
                let commentString = NSAttributedString(string: "  •  \"" + commentContent + "\"", attributes: [NSForegroundColorAttributeName: UIColor(r: 235, g: 235, b: 235), NSFontAttributeName: UIFont.init(name: "Jellee-Roman", size: 12.0)!])
        
                commentAuthorLabel.attributedText = nameDateString
                commentLabel.attributedText = commentString
                
                self.commentUserImageView.af_setImage(withURL: URL(string: commentProfileImageURL)!, placeholderImage: UIImage(named: "person"), filter: AspectScaledToFillSizeCircleFilter(size: commentUserImageView.frame.size), imageTransition: .crossDissolve(0.1))
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = UIColor.clear
        selectionStyle = .none
        
        backgroundUnderlayView.layer.cornerRadius = 15
        
        commentAuthorLabel.textColor = UIColor.white
//        commentAuthorLabel.isUserInteractionEnabled = true
//        commentAuthorLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(goToUserPostsFromComment)))
        commentLabel.textColor = UIColor.white
        
//        commentUserImageView.isUserInteractionEnabled = true
//        commentUserImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(goToUserPostsFromComment)))
    }
//
//    func goToUserPostsFromComment(){
//        guard let userID = comment?.userID else{
//            return
//        }
//
////        let profileController = ProfileController()
////        profileController.userID = (userID)
////        
//        var topVC = UIApplication.shared.keyWindow?.rootViewController
//        while((topVC!.presentedViewController) != nil) {
//            topVC = topVC!.presentedViewController
//        }
////        topVC!.present(profileController, animated: true, completion: nil)
//        self.perform
//        topVC!.showProfileControllerFromCell(userID)
//    }
}
