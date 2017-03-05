//
//  LoginViewController.swift
//  Spotty
//
//  Created by Cameron Eubank on 8/1/16.
//  Copyright © 2016 Cameron Eubank. All rights reserved.
//

import UIKit
import Firebase
import FBSDKCoreKit
import FBSDKLoginKit

class LoginController: UIViewController, FBSDKLoginButtonDelegate{
    
    var backgroundWebView = UIWebView()
    var backgroundImageView = UIImageView()
    var titleLabel = UILabel()
    var loginButton = FBSDKLoginButton()
    let userDefaults = UserDefaults.standard
    
    override func viewDidLoad() {
        
        backgroundImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.view.bounds.height))
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.image = UIImage(named: "background")
        view.addSubview(backgroundImageView)
        
//        //Background WebView.
//        backgroundWebView = UIWebView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
//        backgroundWebView.center = view.center
//        //Animate WebView with .gif.
//        let gifPath = Bundle.main.path(forResource: "gif3", ofType: "gif")
//        let gif = try? Data(contentsOf: URL(fileURLWithPath: gifPath!))
//        backgroundWebView.load(gif!, mimeType: "image/gif", textEncodingName: String(), baseURL: URL())
//        backgroundWebView.load(gif!, mimeType: "image/gif", textEncodingName: String(), baseURL: URL(string: "www.google.com")!)
//        backgroundWebView.isUserInteractionEnabled = false
//        view.addSubview(backgroundWebView)
        
        //Login Button
        loginButton.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 60)
        loginButton.center = CGPoint(x: view.center.x, y: view.bounds.height - 30)
        loginButton.setTitleColor(UIColor.white, for: UIControlState())
        loginButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        loginButton.readPermissions = ["email"]
        loginButton.delegate = self
        view.addSubview(loginButton)
        
        //Title Label
        titleLabel = UILabel(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 300))
        titleLabel.center = CGPoint(x: view.center.x, y: 150)
        titleLabel.text = "Choozy"
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont(name: "Avenir-Light", size: 95)
        titleLabel.textColor = UIColor.white
        titleLabel.adjustsFontSizeToFitWidth = true
        view.addSubview(titleLabel)
    }
    
    //Facebook Login Button Delegate Methods
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        if error != nil{
            handleLoginAndRegister()
        }else if result.isCancelled{
            print("User cancelled")
        }else{
            handleLoginAndRegister()
        }
    }

    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        
    }
    
    func loginButtonWillLogin(_ loginButton: FBSDKLoginButton!) -> Bool {
        return true
    }
    
    func handleLoginAndRegister(){

        let credential = FIRFacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
        FIRAuth.auth()?.signIn(with: credential, completion: {(user, error) in
            if error != nil{
                print(error!.localizedDescription)
                return
            }else{
                
                guard let user = user else{
                    return
                }
                
                self.createUser(user: user)
            }
        })
    }
    
    func createUser(user: FIRUser){
        
        let imageName = UUID().uuidString
        let storageRef = FIRStorage.storage().reference().child("user_images").child("\(imageName).png")
        
        if let uploadData = UIImageJPEGRepresentation(UIImage(data: try! Data(contentsOf: user.photoURL!))!, 0.75){
            storageRef.put(uploadData, metadata: nil, completion: {(metadata, error) in
                
                if error != nil{
                    print(error?.localizedDescription)
                    return
                }
                
                if let userImageURL = metadata?.downloadURL()?.absoluteString{
                    self.uploadUser(user: user, userImageURL: userImageURL)
                }
            })
        }
    }
    
    func uploadUser(user: FIRUser, userImageURL: String){
        
        let userID = user.uid
        
        guard let userName = user.displayName, let userEmail = user.email else{
            return
        }
        
        let values: [String: AnyObject] = ["id": userID as AnyObject, "name": userName as AnyObject, "email": userEmail as AnyObject, "profileImageURL": userImageURL as AnyObject]
        
        let postsReference = FIRDatabase.database().reference().child("users")
        let postsChildReference = postsReference.child(userID)
        
        postsChildReference.updateChildValues(values, withCompletionBlock: {(error, ref) in
            if error != nil{
                print(error?.localizedDescription)
                return
            }else{
                self.dismissViewController()
            }
        })
    }

    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
}

