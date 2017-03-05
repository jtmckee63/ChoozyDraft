//
//  DetailController.swift
//  Spotty
//
//  Created by Cameron Eubank on 9/4/16.
//  Copyright © 2016 Cameron Eubank. All rights reserved.
//

import UIKit
import Firebase
import MobileCoreServices
import MediaPlayer
import Photos
import JRMFloatingAnimation
import AlamofireImage

class DetailController: UIViewController, UIGestureRecognizerDelegate {

    var moviePlayerController = MPMoviePlayerController()
    var postImageView = UIImageView()
    
    @IBOutlet var headerView: UIView!
    @IBOutlet var postAuthorImageView: UIImageView!
    @IBOutlet var postAuthorUsernameLabel: UILabel!
    @IBOutlet var moreOptionsButton: UIButton!
    
    @IBOutlet var mediaView: UIView!
    
    @IBOutlet var postActionsView: UIView!
    @IBOutlet var likeButton: UIButton!
    @IBOutlet var likesCountLabel: UILabel!
    @IBOutlet var viewCountImageView: UIImageView!
    @IBOutlet var viewCountLabel: UILabel!
    @IBOutlet var commentButton: UIButton!
    
    @IBOutlet var footerView: UIView!
    @IBOutlet var postCommentLabel: UILabel!
    @IBOutlet var postAddressLabel: UILabel!
    @IBOutlet var postTimeLabel: UILabel!
    @IBOutlet var viewCommentsButton: UIButton!

    var postAuthor = User()
    var loggedInUser = User()
    var userFromFirebase = User()
    var post = Post() //Post Object Retrieved from Segue.
    var comments: [Comment] = []
    
    var likes = Int()
    var views = Int()
    
    //var colorScheme = (dark: UIColor(), flat: UIColor())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.layoutIfNeeded()
        
        //Title
        title = "Post"

        //colorScheme = (UIColor.purple.dark, UIColor.purple.flat)
        self.view.backgroundColor = UIColor.purple.dark

        //Header View
        headerView.backgroundColor = UIColor.purple.flat
        postAuthorImageView.isUserInteractionEnabled = true
        postAuthorImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(goToUserPostsFromHeader)))
        postAuthorUsernameLabel.text = ""
        moreOptionsButton.addTarget(self, action: #selector(showMoreOptions), for: .touchUpInside)
        
        //Post Actions View
        postActionsView.backgroundColor = UIColor.purple.flat
        likeButton.addTarget(self, action: #selector(likePostAsCurrentUser), for: .touchUpInside)
        commentButton.addTarget(self, action: #selector(goToCommentsControllerWithTextField), for: .touchUpInside)
        
        //Footer View
        footerView.backgroundColor = UIColor.purple.dark
        postCommentLabel.text = ""
        postAddressLabel.text = ""
        postTimeLabel.text = ""
        let viewComments = NSAttributedString(string: "View all comments", attributes: [NSForegroundColorAttributeName: UIColor.white.flat, NSFontAttributeName: UIFont.init(name: "Jellee-Roman", size: 10.0)!])
        let viewCommentsString = NSMutableAttributedString()
        viewCommentsString.append(bullet)
        viewCommentsString.append(viewComments)
        viewCommentsButton.setAttributedTitle(viewCommentsString, for: .normal)
        viewCommentsButton.addTarget(self, action: #selector(goToCommentsController), for: .touchUpInside)

        //Post Address Label
        postAddressLabel.isUserInteractionEnabled = false
        postAddressLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(goToMapsFromCoordinate)))

        //Assign Logged In User
        getUser({(user) in
            self.loggedInUser = user
            self.userFromFirebase = getFirebaseUser(user: self.loggedInUser)
            
            //Likes Observer
            self.addLikesObserver()
            
            //Views Observer
            //self.addViewsObserver()
            
            //Set UI
            self.setViewsBeforeLoadingPostInfo()
            
            //Increase View Count
            //self.increasePostViewCount()
            
            //Refresh Data
            self.refreshData()
        })
        
    }
    
    func addLikesObserver(){
        
        guard let postID = post.postID else{
            print("couldn't find a post ID")
            return
        }

        let upvoteReference = FIRDatabase.database().reference().child("posts/\(postID)")
        upvoteReference.observe(.value, with: {(snapshot) in
    
            if let dictionary = snapshot.value as? [String: AnyObject]{
                
                guard let likes = dictionary["upvote"] as? NSNumber else{
                    return
                }
                
                self.likes = Int(likes)
            }
      
            DispatchQueue.main.async(execute: {
                self.likesCountLabel.text = "\(self.likes)"
                for _ in 0...Int(arc4random_uniform(3) + 2){
                    self.animateLike()
                }
            })
            
        }, withCancel: nil)
    }
    
    func addViewsObserver(){
        
        guard let postID = post.postID else{
            return
        }
        
        let viewsReference = FIRDatabase.database().reference().child("posts/\(postID)")
        viewsReference.observe(.value, with: {(snapshot) in
            
            if let dictionary = snapshot.value as? [String: AnyObject]{
                
                guard let views = dictionary["views"] as? NSNumber else{
                    return
                }
                
                self.views = Int(views)
            }
          
            DispatchQueue.main.async(execute: {
                self.viewCountLabel.text = "\(self.views)"
            })
        })
    }
    
    func animateLike(){
        let randomSize = CGFloat(arc4random_uniform(70) + 10)
        let floatingView = JRMFloatingAnimationView(starting: CGPoint(x: self.likeButton.center.x, y: self.likeButton.center.x))
        floatingView?.frame = CGRect(x: self.likeButton.center.x, y: self.likeButton.center.y, width: randomSize, height: randomSize)
        floatingView?.add(UIImage(named: "likedIcon"))
        floatingView?.fadeOut = true
        floatingView?.floatingShape = JRMFloatingShape.curveRight
        floatingView?.animate()
            
        if floatingView != nil{
            self.view.addSubview(floatingView!)
        }
    }
    
    func setViewsBeforeLoadingPostInfo(){
        
        guard let postMedia = post.postMediaURL else{
            return
        }
        
        //Handle the Media View
        if postMedia.contains(".png") || postMedia.contains(".jpg"){
            postImageView.frame = self.mediaView.bounds
            self.mediaView.addSubview(postImageView)
            postImageView.af_setImage(withURL: URL(string: postMedia)!, filter: AspectScaledToFillSizeFilter(size: postImageView.frame.size), imageTransition: .crossDissolve(0.1))
        }else if postMedia.contains(".mov"){
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(startStopMoviePlayer))
            tapGesture.delegate = self
            let url = URL(string: postMedia)
            self.moviePlayerController = MPMoviePlayerController(contentURL: url)
            if let player = self.moviePlayerController as? MPMoviePlayerController{
                player.view.frame = self.mediaView.bounds
                player.scalingMode = .aspectFill
                player.controlStyle = .none
                player.repeatMode = .one
                player.view.isUserInteractionEnabled = true
                player.view.addGestureRecognizer(tapGesture)
                self.mediaView.addSubview(player.view)
                player.prepareToPlay()
            }
        }
        
        //Format the Likes Label
        let doubleLikes = Double(likes)
        if likes > 1000000{
            self.likesCountLabel.text = String(format:"%.2f", doubleLikes/1000000) + "m"
        }else if likes > 1000{
            self.likesCountLabel.text = String(format:"%.2f", doubleLikes/1000) + "k"
        }else{
            self.likesCountLabel.text = "\(likes)"
        }
        
        //Format the View Label
        let doubleViews = Double(views)
        if views > 1000000{
            self.viewCountLabel.text = String(format:"%.2f", doubleViews/1000000) + "m"
        }else if views > 1000{
            self.viewCountLabel.text = String(format:"%.2f", doubleViews/1000) + "k"
        }else{
            self.viewCountLabel.text = "\(views)"
        }
    }
    
    func refreshData(){
        retrievePostInformation({(complete) in
            if complete{
                self.setViewsAfterLoadingPostInfo()
            }
        })
    }

    func retrievePostInformation(_ completion: @escaping (_ complete: Bool) -> ()){
        
        guard let postAuthorID = post.userID, let postID = post.postID, let subAddress = post.subAddress, let address = post.address, let city = post.city, let state = post.state else{
            return
        }
        
        let postUserReference = FIRDatabase.database().reference().child("users/\(postAuthorID)")
        postUserReference.observeSingleEvent(of: .value, with: {(snapshot) in
            
            if let dictionary = snapshot.value as? [String: AnyObject]{
                self.postAuthor.setValuesForKeys(dictionary)
            }
            
            guard let postAuthorImage = self.postAuthor.profileImageURL, let postAuthorName = self.postAuthor.name, let secondsFromPostDate = self.post.timeStamp, let commentFromPost = self.post.comment else{
                return
            }
            
            //Construct Attributed Strings
            let name = NSAttributedString(string: postAuthorName, attributes: [NSForegroundColorAttributeName: UIColor.white.pure, NSFontAttributeName: UIFont.init(name: "Jellee-Roman", size: 12.0)!])
            let date = NSAttributedString(string: getDateStringFromNumber(secondsFromPostDate), attributes: [NSForegroundColorAttributeName: UIColor.white.flat, NSFontAttributeName: UIFont.init(name: "Jellee-Roman", size: 10.0)!])
            let comment = NSAttributedString(string: "   " + commentFromPost, attributes: [NSForegroundColorAttributeName: UIColor.white.flat, NSFontAttributeName: UIFont.init(name: "Jellee-Roman", size: 10.0)!])
            let address = NSAttributedString(string: subAddress + " " + address + " - " + city + ", " + state, attributes: [NSForegroundColorAttributeName: UIColor.white.flat, NSFontAttributeName: UIFont.init(name: "Jellee-Roman", size: 10.0)!])
            
            //Construct Combinations of Attributed Strings
            let nameCommentString = NSMutableAttributedString()
            nameCommentString.append(bullet)
            nameCommentString.append(name)
            nameCommentString.append(comment)
            
            let addressString = NSMutableAttributedString()
            addressString.append(bullet)
            addressString.append(address)
            
            let dateString = NSMutableAttributedString()
            dateString.append(bullet)
            dateString.append(date)
            
            //Header SubViews
            self.postAuthorImageView.af_setImage(withURL: URL(string: postAuthorImage)!, placeholderImage: UIImage(named: "person"), filter: AspectScaledToFillSizeCircleFilter(size: self.postAuthorImageView.frame.size), imageTransition: .crossDissolve(0.1))
            
            self.postAuthorUsernameLabel.attributedText = name
            
            
            //Footer Subviews
            if commentFromPost.replacingOccurrences(of: " ", with: "") != ""{
                self.postCommentLabel.attributedText = nameCommentString
                self.postCommentLabel.sizeToFit()
            }
            self.postAddressLabel.attributedText = addressString
            self.postTimeLabel.attributedText = dateString
            
        }, withCancel: nil)

        let commentsReference = FIRDatabase.database().reference().child("comments").queryOrdered(byChild: "postID").queryEqual(toValue: postID)
        commentsReference.observe(.childAdded, with: {(snapshot) in

            if let dictionary = snapshot.value as? [String: AnyObject]{
                let comment = Comment()
                comment.setValuesForKeys(dictionary)
                self.comments.append(comment)
            }
            
            let viewComments = NSAttributedString(string: self.comments.count > 1 ? "View all \(self.comments.count) comments" : (self.comments.count == 1 ? "View \(self.comments.count) comment" : "View all comments"), attributes: [NSForegroundColorAttributeName: UIColor.white.flat, NSFontAttributeName: UIFont.init(name: "Jellee-Roman", size: 10.0)!])
            let viewCommentsString = NSMutableAttributedString()
            viewCommentsString.append(bullet)
            viewCommentsString.append(viewComments)
            
            DispatchQueue.main.async(execute: {
                self.viewCommentsButton.setAttributedTitle(viewCommentsString, for: .normal)
            })
            
            completion(true)
            
        }, withCancel: nil)
    }
    
    func setViewsAfterLoadingPostInfo(){
        postAddressLabel.isUserInteractionEnabled = true
    }
    
    func likePostAsCurrentUser(){
        guard let postID = post.postID else{
            return
        }

        let likesCountPlusOne = likes + 1
        let postReference = FIRDatabase.database().reference().child("posts/\(postID)")
        let values: [String: AnyObject] = ["upvote": likesCountPlusOne as AnyObject]
        postReference.updateChildValues(values, withCompletionBlock: {(error, ref) in
            if error != nil{
                print(error?.localizedDescription)
                return
            }else{
                for _ in 0...Int(arc4random_uniform(3) + 2){
                    self.animateLike()
                }
            }
        })
    }
    
    func increasePostViewCount(){
        guard let postID = post.postID else{
            return
        }
        
        let viewCountPlusOne = views + 1
        let postReference = FIRDatabase.database().reference().child("posts/\(postID)")
        let values: [String: AnyObject] = ["views": viewCountPlusOne as AnyObject]
        postReference.updateChildValues(values, withCompletionBlock: {(error, ref) in
            if error != nil{
                print(error?.localizedDescription)
                return
            }
        })
    }
    
    func goToUserPostsFromHeader(){
        guard let userID = postAuthor.id else{
            return
        }
        self.showProfileController(userID)
    }
    
    func goToCommentsController(){
        self.showCommentsController(post)
    }
    
    func goToCommentsControllerWithTextField(){
        self.showCommentsControllerWithTextField(post)
    }
    
    func goToMapsFromCoordinate(){
        guard let latitude = post.latitude, let longitude = post.longitude else{
            self.showAlert("Whoops!", message: "For some reason, we couldn't open this location in Maps.")
            return
        }
        openCoordinateInMap(Double(latitude), longitude: Double(longitude))
    }
    
    func startStopMoviePlayer(){
        if moviePlayerController.isPreparedToPlay{
            if moviePlayerController.playbackState == .playing{
                moviePlayerController.pause()
            }else{
                moviePlayerController.play()
            }
        }
    }
    
    func removeDetailController(){
        //moviePlayerController.stop()
        //self.pop()
    }
    
    func showMoreOptions(){
        
        //Obtain relevant information for reportable content.
        guard let postID = post.postID, let postComment = post.comment, let postAuthorID = postAuthor.id, let postAuthorEmail = postAuthor.email, let loggedInUserID = self.loggedInUser.id, let postMediaURL = post.postMediaURL else{
            return
        }
        
        var isSelf = Bool()
        if postAuthorID == loggedInUserID{isSelf = true}
        var mediaExtension = String()
        if postMediaURL.contains(".png"){
            mediaExtension = ".png"
        }else if postMediaURL.contains(".jpg"){
            mediaExtension = ".jpg"
        }else if postMediaURL.contains(".mov"){
            mediaExtension = ".mov"
        }
        
        let alertController = UIAlertController(title: "", message: "More Options", preferredStyle: .actionSheet)
        let dismissAction = UIAlertAction(title: "Dismiss", style: .cancel, handler: nil)
        
        let reportAction = UIAlertAction(title: "Report as Offensive or Irrelevant", style: .default, handler: { (action: UIAlertAction!) -> () in
            let postReference = FIRDatabase.database().reference().child("reportedPosts/\(postID)")
            let values: [String: AnyObject] = ["postID": postID as AnyObject, "postAuthorID": postAuthorID as AnyObject, "postAuthorEmail": postAuthorEmail as AnyObject, "postComment": postComment as AnyObject, "reportedByUserID": loggedInUserID as AnyObject]
            
            postReference.updateChildValues(values, withCompletionBlock: {(error, ref) in
                if error != nil{
                    print(error?.localizedDescription)
                    return
                }else{
                    self.showAlert("Thank you.\n", message: "We will look into this post.")
                }
            })
        })
        
        
        let deletePostAction: UIAlertAction = UIAlertAction(title: "Delete Post", style: .default, handler: { (action: UIAlertAction!) -> () in
            let storageRef = FIRStorage.storage().reference().child("post_media/\(postID)" + mediaExtension)
            storageRef.delete(completion: {(error) in
                let postReference = FIRDatabase.database().reference().child("posts/\(postID)")
                postReference.removeValue()
                let commentsReference = FIRDatabase.database().reference().child("comments").childByAutoId().child("/\(postID)")
                commentsReference.removeValue()
                self.removeDetailController()
            })
        })
        
        let savePhotoAction: UIAlertAction = UIAlertAction(title: "Save to Camera Roll", style: .default, handler: { (action: UIAlertAction!) -> () in
            
            if mediaExtension.contains(".png") || mediaExtension.contains(".jpg"){
                print("attempting to save image")
                guard let image = self.postImageView.image else{
                    return
                }
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            }else{
                print("attempting to save video")
                let url = URL(string: postMediaURL)
                
                let urlData = NSData(contentsOf: url!);
                if(urlData != nil)
                {
                    //#TODO: - GCD
                    let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0];
                    let filePath="\(documentsPath)/tempFile.mov";
                    urlData?.write(toFile: filePath, atomically: true);
                    PHPhotoLibrary.shared().performChanges({
                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: NSURL(fileURLWithPath: filePath) as URL)
                    }) { completed, error in
                        if completed {
                            print("Video is saved!")
                        }
                    }
                }
            }
            
        })
        
        if isSelf{
            alertController.addAction(deletePostAction)
            alertController.addAction(reportAction)
            alertController.addAction(savePhotoAction)
        }else{
            alertController.addAction(reportAction)
        }
        
        alertController.addAction(dismissAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    
    //MARK: - Gesture Recognizer Delegate
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    //MARK: - Prepare for Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "profile" {
            let profileController: ProfileController = segue.destination as! ProfileController
            profileController.userID = (sender as? String)!
        }
        
        if segue.identifier == "comment" {
            let commentsController: CommentsController = segue.destination as! CommentsController
            commentsController.post = (sender as? Post)!
        }
        
        if segue.identifier == "commentWithTextField"{
            let commentsController: CommentsController = segue.destination as! CommentsController
            commentsController.post = (sender as? Post)!
            commentsController.openTextField = true
        }
    }
}
