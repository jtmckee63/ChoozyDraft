//
//  SideMenuController.swift
//  Spotty
//
//  Created by Cameron Eubank on 10/8/16.
//  Copyright © 2016 Cameron Eubank. All rights reserved.
//

import UIKit
import SideMenu
import AlamofireImage

class SideMenuController: UIViewController {
    
    @IBOutlet var backgroundImageView: UIImageView!
    @IBOutlet var userImageView: UIImageView!
    @IBOutlet var userNameLabel: UILabel!
    @IBOutlet var menuItemsView: UIView!
    @IBOutlet var viewProfileView: UIView!
    @IBOutlet var viewProfileButton: UIButton!
    @IBOutlet var aboutView: UIView!
    @IBOutlet var aboutButton: UIButton!
    @IBOutlet var distanceView: UIView!
    @IBOutlet var distanceSlider: UISlider!
    @IBOutlet var distanceLabel: UILabel!
    @IBOutlet var distanceValueLabel: UILabel!
    @IBOutlet var logoutView: UIView!
    @IBOutlet var logoutButton: UIButton!
    @IBOutlet var footerLabel: UILabel!
    
    var loggedInUser = User()
    var userDefaults = UserDefaults()
    
    struct constants{
        static let minimumSearchDistance: Float = 1
        static let maximumSearchDistance: Float = 10000
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.layoutIfNeeded()
            
        
        //Background
        self.view.backgroundColor = UIColor.purple.dark
        menuItemsView.backgroundColor = UIColor.purple.dark
        
        //Background Image View
        backgroundImageView.image = UIImage(named: "background")
        backgroundImageView.clipsToBounds = true
        
        //User Image View
        userImageView.isUserInteractionEnabled = false
        userImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(goToProfileView)))
        
        //View Profile View
        viewProfileView.backgroundColor = UIColor.purple.flat
        viewProfileButton.isUserInteractionEnabled = false
        viewProfileButton.addTarget(self, action: #selector(goToProfileView), for: .touchUpInside)
        
        //About View
        aboutView.backgroundColor = UIColor.purple.flat
        aboutButton.addTarget(self, action: #selector(goToAboutView), for: .touchUpInside)
        
        //Distance View
        distanceView.backgroundColor = UIColor.purple.flat
        distanceLabel.text = "Distance"
        distanceValueLabel.text = "\(userDefaults.getDistance()) miles"
        distanceSlider.minimumValue = constants.minimumSearchDistance
        distanceSlider.maximumValue = constants.maximumSearchDistance
        distanceSlider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
        
        //Logout View
        logoutView.backgroundColor = UIColor.purple.flat
        logoutButton.isUserInteractionEnabled = false
        logoutButton.addTarget(self, action: #selector(logout), for: .touchUpInside)
        
        //Setup UI
        setupUI()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        let distance = Int(distanceSlider.value)
        userDefaults.setValue(distance, forKey: "distance")
    }
    
    func sliderChanged(){
        let distance = Int(distanceSlider.value)
        distanceValueLabel.text = "\(distance) miles"
    }
    
    func setupUI(){

        getUser({(user) in
            self.loggedInUser = user
            self.userImageView.isUserInteractionEnabled = true
            self.viewProfileButton.isUserInteractionEnabled = true
            self.logoutButton.isUserInteractionEnabled = true
        })
        
        guard let profileImage = loggedInUser.profileImageURL, let name = loggedInUser.name else{
            return
        }
        
//        self.userImageView.af_setImage(withURL: URL(string: profileImage)!, filter: AspectScaledToFillSizeCircleFilter(size: self.userImageView.frame.size), imageTransition: .crossDissolve(0.1))
//        self.backgroundImageView.af_setImage(withURL: URL(string: profileImage)!, filter: AspectScaledToFillSizeFilter(size: self.backgroundImageView.frame.size), imageTransition: .crossDissolve(0.1))
        
        self.userImageView.af_setImage(withURL: URL(string: profileImage)!, placeholderImage: UIImage(named: "person"), filter: AspectScaledToFillSizeCircleFilter(size: self.userImageView.frame.size), imageTransition: .crossDissolve(0.1))
        
        userNameLabel.text = name
        userNameLabel.textColor = UIColor.white.flat
        
        let distance = userDefaults.getDistance()
        distanceSlider.value = Float(distance)
        distanceValueLabel.text = "\(distance) miles"
        
        footerLabel.text = "Choozy - Version 0.1"
        footerLabel.textColor = UIColor.white.dark
    }
    
    func logout(){
        logoutFromFirebase({(complete) in
            self.showLoginController()
        })
    }
    
    func goToProfileView(){
        guard let userID = loggedInUser.id else{
            return
        }
        self.showProfileController(userID)
    }
    
    func goToAboutView(){
        self.showAboutController()
    }
    
    //MARK: - Prepare for Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "profile"{
            let profileController: ProfileController = segue.destination as! ProfileController
            profileController.userID = (sender as? String)!
        }
    }
}
