//
//  ProfileController.swift
//  Spotty
//
//  Created by Cameron Eubank on 9/2/16.
//  Copyright © 2016 Cameron Eubank. All rights reserved.
//

import UIKit
import Firebase
import AlamofireImage

class ProfileController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet var backgroundImageView: UIImageView!
    @IBOutlet var userImageView: UIImageView!
    @IBOutlet var userNameLabel: UILabel!
    @IBOutlet var postsLabel: UILabel!
    @IBOutlet var likesLabel: UILabel!
    @IBOutlet var postsCountLabel: UILabel!
    @IBOutlet var likesCountLabel: UILabel!
    @IBOutlet var postsCollectionView: UICollectionView!
    @IBOutlet var badge: UIImageView!
    
    var userID = String()
    var posts:[Post] = []
    var user = User()
    var loggedInUser = User()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.layoutIfNeeded()
        
        //Title
        title = "Profile"
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style: .plain, target: nil, action: nil)

        //Background Image View
        let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        visualEffectView.frame = backgroundImageView.bounds
        backgroundImageView.image = nil
        backgroundImageView.backgroundColor = UIColor.black.ultraDark
        backgroundImageView.contentMode = .scaleToFill
        backgroundImageView.clipsToBounds = true
        backgroundImageView.addSubview(visualEffectView)
        
        //User Image View
        //userImageView.circleWithBorder(UIColor.white, width: 4.0)
        //userImageView.backgroundColor = UIColor.black.ultraDark
        //userImageView.image = nil
        userImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showProfileOptions)))
        
        //Set Labels to "" & "" or "Posts" & "Likes"
        userNameLabel.text = "--"
        postsLabel.text = "Posts"
        likesLabel.text = "Likes"
        postsCountLabel.text = "--"
        likesCountLabel.text = "--"

        //Post Collection View
        postsCollectionView.register(UINib(nibName: "UserPostCell", bundle: nil), forCellWithReuseIdentifier: "cell")
        postsCollectionView.delegate = self
        postsCollectionView.dataSource = self
        postsCollectionView.backgroundColor = UIColor.black.ultraDark
        
        //Retrieve information by ID
        retrieveUserInformationByID(userID, completion: {(complete) in
            
            self.postsCountLabel.text = "\(self.posts.count)"
            
            var likesCount = Int()
            for post in self.posts{
                guard let likes = post.upvote as? Int else{
                    return
                }
                likesCount = likesCount + likes
            }
            
            if likesCount > 1000{
                let doubleLikes = Double(likesCount)
                self.likesCountLabel.text = String(format:"%.2f", doubleLikes/1000) + "k"
            }else{
                self.likesCountLabel.text = "\(likesCount)"
            }
            
            
            if self.posts.count > 1 {
                self.badge.image = UIImage(named: "badge1")
                self.badge.layer.masksToBounds = false
                self.badge.layer.borderColor = UIColor.black.cgColor
                self.badge.clipsToBounds = true
            }
            if self.posts.count > 25 {
                self.badge.image = UIImage(named: "badge2")
                self.badge.layer.masksToBounds = false
                self.badge.layer.borderColor = UIColor.black.cgColor
                self.badge.clipsToBounds = true
            }
            if self.posts.count > 50 {
                self.badge.image = UIImage(named: "badge3")
                self.badge.layer.masksToBounds = false
                self.badge.layer.borderColor = UIColor.black.cgColor
                self.badge.clipsToBounds = true
            }
            if self.posts.count > 75 {
                self.badge.image = UIImage(named: "badge4")
                self.badge.layer.masksToBounds = false
                self.badge.layer.borderColor = UIColor.black.cgColor
                self.badge.clipsToBounds = true
            }
            if self.posts.count > 100 {
                self.badge.image = UIImage(named: "badge5")
                self.badge.layer.masksToBounds = false
                self.badge.layer.borderColor = UIColor.black.cgColor
                self.badge.clipsToBounds = true
            }
        })
        
        //Assign Logged In User
        getUser({(user) in
            self.loggedInUser = user
        })
    }

    func showProfileOptions(){
        
        guard let userID = self.user.id, let loggedInUserID = self.loggedInUser.id else{
            return
        }
        
        let isSelf = userID == loggedInUserID
    
        let alertController = UIAlertController(title: "", message: "More Options", preferredStyle: .actionSheet)
        let dismissAction = UIAlertAction(title: "Dismiss", style: .cancel, handler: nil)
        let logOutAction: UIAlertAction = UIAlertAction(title: "Log out", style: .default, handler: { (action: UIAlertAction!) -> () in
            logoutFromFirebase({(complete) in
                self.dismissViewController()
                self.showLoginController()
            })
        })
        
        if isSelf{
            alertController.addAction(logOutAction)
        }else{
            
        }
        
        alertController.addAction(dismissAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func retrieveUserInformationByID(_ userID: String, completion: @escaping (_ complete: Bool) -> ()){

        //Get User Information
        let userReference = FIRDatabase.database().reference().child("users/\(userID)")
        userReference.observeSingleEvent(of: .value, with: {(snapshot) in
            
            if let dictionary = snapshot.value as? [String: AnyObject]{
                
                self.user.setValuesForKeys(dictionary)

                guard let userImage = self.user.profileImageURL else{
                    return
                }
                
                guard let userName = self.user.name else{
                    return
                }
                
                self.userImageView.af_setImage(withURL: URL(string: userImage)!, filter: AspectScaledToFillSizeCircleFilter(size: self.userImageView.frame.size), imageTransition: .crossDissolve(0.1))
                self.backgroundImageView.af_setImage(withURL: URL(string: userImage)!, filter: AspectScaledToFillSizeFilter(size: self.backgroundImageView.frame.size), imageTransition: .crossDissolve(0.1))
                
                self.userNameLabel.text = userName
                self.userImageView.isUserInteractionEnabled = true
            }
        }, withCancel: nil)
        
        //Get Posts made by the user where userID == id
        let postsReference = FIRDatabase.database().reference().child("posts").queryOrdered(byChild: "userID").queryEqual(toValue: userID)
        postsReference.observe(.childAdded, with: {(snapshot) in
            
            if let dictionary = snapshot.value as? [String: AnyObject]{
                
                let post = Post()
                post.setValuesForKeys(dictionary)
                self.posts.append(post)
            
                //Sort the posts array to show the most recent posts.
                self.posts.sort(by: {(post1, post2) ->
                    Bool in
                    return (post1.timeStamp?.int32Value)! > (post2.timeStamp?.int32Value)!
                })
            }
            
            DispatchQueue.main.async(execute: {
                self.postsCollectionView.reloadData()
            })
            
            if (self.posts.count * Int(snapshot.childrenCount)) / self.posts.count == Int(snapshot.childrenCount) {
                completion(true)
            }
        })
    }
    
    //MARK: - Collection View Delegate & DataSource
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell{
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! UserPostCell
        let post = posts[(indexPath as NSIndexPath).row]
        cell.post = post
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //Show the Detail Controller with the information for the Post Selected.
        let post = posts[(indexPath as NSIndexPath).row]
        self.showDetailController(post)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count
    }
    
    //Size of the Cell
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.bounds.width / 3 - 1, height: view.bounds.width / 3 - 1)
    }
    
    //Line Spacing
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1.0
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    //MARK: - Prepare for Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "detail" {
            let detailController: DetailController = segue.destination as! DetailController
            detailController.post = (sender as? Post)!
        }
    }
}
