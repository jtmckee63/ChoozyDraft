//
//  CommentsController.swift
//  Spotty
//
//  Created by Cameron Eubank on 10/17/16.
//  Copyright © 2016 Cameron Eubank. All rights reserved.
//

import UIKit
import Firebase

class CommentsController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var contentView: UIView!
    @IBOutlet var commentsTableView: UITableView!
    @IBOutlet var postCommentView: UIView!
    @IBOutlet var postCommentTextField: UITextField!
    @IBOutlet var postCommentButton: UIButton!

    var comments: [Comment] = []
    var post = Post()
    var currentFirebaseUser = User()
    var openTextField = Bool()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.layoutIfNeeded()
        
        //Title
        title = "Comments"
        
        //Background View
        self.view.backgroundColor = UIColor.purple.dark
        
        //Scroll View
        scrollView.isScrollEnabled = false
        scrollView.indicatorStyle = .white
        scrollView.backgroundColor = UIColor.purple.dark
 
        //Content View
        contentView.backgroundColor = UIColor.purple.dark
        
        //Comments Table View
        commentsTableView.delegate = self
        commentsTableView.dataSource = self
        commentsTableView.register(UINib(nibName: "CommentCell", bundle: nil), forCellReuseIdentifier: "cell")
        commentsTableView.backgroundColor = UIColor.clear
        commentsTableView.separatorStyle = .none
        commentsTableView.indicatorStyle = .white
        
        //Post Comment View
        postCommentView.backgroundColor = UIColor.black.ultraDark.withAlphaComponent(0.75)
        postCommentTextField.textColor = UIColor.white
        postCommentTextField.delegate = self
        postCommentTextField.attributedPlaceholder = NSAttributedString(string:"Leave a comment...", attributes: [NSForegroundColorAttributeName: UIColor.white.flat.withAlphaComponent(0.7)])
        postCommentTextField.tintColor = UIColor.purple.flat
        postCommentButton.backgroundColor = UIColor.clear
        postCommentButton.addTarget(self, action: #selector(postCommentAsLoggedInUser), for: .touchUpInside)
        
        NotificationCenter.default.addObserver(self, selector: #selector(CommentsController.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(CommentsController.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)

        //Assign Logged In User
        getUser({(user) in
            let loggedInUser = user
            self.currentFirebaseUser = getFirebaseUser(user: loggedInUser)
            self.retrieveComments()
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        if openTextField{
            postCommentTextField.becomeFirstResponder()
        }
    }
    
    func retrieveComments(){
        
        let commentsReference = FIRDatabase.database().reference().child("comments").queryOrdered(byChild: "postID").queryEqual(toValue: post.postID)
        commentsReference.observe(.childAdded, with: {(snapshot) in
            
            if let dictionary = snapshot.value as? [String: AnyObject]{
                let comment = Comment()
                comment.setValuesForKeys(dictionary)
                self.comments.append(comment)
                
                //Sort the posts array to show the most recent posts.
                self.comments.sort(by: {(post1, post2) -> Bool in
                    return (post1.timeStamp?.int32Value)! > (post2.timeStamp?.int32Value)!
                })
            }
            
            DispatchQueue.main.async(execute: {
                self.commentsTableView.reloadData()
                self.scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
            })
  
        }, withCancel: nil)
    }
    
    func postCommentAsLoggedInUser(){
        
        guard let postID = post.postID, let userID = currentFirebaseUser.id, let currentUserName = currentFirebaseUser.name, let profileImageURL = currentFirebaseUser.profileImageURL, let comment = self.postCommentTextField.text else{
            return
        }
        
        if comment.replacingOccurrences(of: " ", with: "") != ""{
            let timeStamp: NSNumber = NSNumber(value: NSDate().timeIntervalSince1970)
            let values: [String: AnyObject] = ["postID": postID as AnyObject, "userID": userID as AnyObject, "userName": currentUserName as AnyObject, "profileImageURL": profileImageURL as AnyObject, "timeStamp": timeStamp, "comment": comment as AnyObject]
            
            let commentsReference = FIRDatabase.database().reference().child("comments")
            let commentsChildReference = commentsReference.childByAutoId()
            
            commentsChildReference.updateChildValues(values, withCompletionBlock: {(error, ref) in
                if error != nil{
                    print(error?.localizedDescription)
                    return
                }else{
                    self.postCommentTextField.text = ""
                    self.view.endEditing(true)
                    self.commentsTableView.setContentOffset(CGPoint.zero, animated: true)
                }
            })
        }else{
            self.showAlert("Hold on!", message: "You can't leave an empty comment!")
        }
    }
    
    //MARK: - Table View Delegate
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! CommentCell
        cell.backgroundUnderlayView.backgroundColor = UIColor.purple.flat
        let comment = comments[(indexPath as NSIndexPath).row]
        cell.comment = comment
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70.0
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let userID = comments[indexPath.row].userID else{
            return
        }
        self.showProfileController(userID)
    }
    
    //MARK: - Text View Delegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    func keyboardWillShow(_ notification: NSNotification) {
        let userInfo = notification.userInfo!
        let keyboardHeight = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue.height
        scrollView.setContentOffset(CGPoint(x: 0, y: keyboardHeight), animated: false)
    }
    
    func keyboardWillHide(_ notification: NSNotification) {
        scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
    }

    //MARK: - Prepare for Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "profile" {
            let profileController: ProfileController = segue.destination as! ProfileController
            profileController.userID = (sender as? String)!
        }
    }
    
    //MARK: - Status Bar Style
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
}
