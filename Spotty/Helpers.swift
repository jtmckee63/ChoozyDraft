//
//  Helpers.swift
//  Spotty
//
//  Created by Cameron Eubank on 8/25/16.
//  Copyright © 2016 Cameron Eubank. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import Firebase
import FBSDKLoginKit

let facebookLoginManager = FBSDKLoginManager()
let bullet = NSAttributedString(string: "  •  ", attributes: [NSForegroundColorAttributeName: UIColor.purple.light, NSFontAttributeName: UIFont.init(name: "Jellee-Roman", size: 12.0)!])

func isPointWithinMilesFromUser(userLocation: CLLocation, postLocation: CLLocation, miles: Double) -> Bool{
    return postLocation.distance(from: userLocation) <= Double(1609 * miles)
}

func getDateStringFromNumber(_ time: NSNumber) -> String{
    var dateString = String()
    let seconds = time.doubleValue
    let postTimeAsDate = Date(timeIntervalSince1970: seconds)
    let currentTimeAsDate = Date(timeIntervalSince1970: NSDate().timeIntervalSince1970)
    let calendar = NSCalendar.current
    let dateFormatter = DateFormatter()
    
    let from = calendar.startOfDay(for: postTimeAsDate)
    let to = calendar.startOfDay(for: currentTimeAsDate)
    let components = calendar.dateComponents([.day], from: from, to: to)
    let daysSincePost = components.day!
  
    if calendar.isDateInToday(postTimeAsDate){
        dateFormatter.dateFormat = "h:mm a"
        dateString = "Today - " + dateFormatter.string(from: postTimeAsDate) //Today - 2:12pm
    }else if calendar.isDateInYesterday(postTimeAsDate){
        dateFormatter.dateFormat = "h:mm a"
        dateString = "Yesterday - " + dateFormatter.string(from: postTimeAsDate) //Yesterday - 2:12pm
    }else if daysSincePost > 2 && daysSincePost <= 7{
        dateFormatter.dateFormat = "EEEE - h:mm a"
        dateString = dateFormatter.string(from: postTimeAsDate) //Tuesday - 2:12pm
    }else if daysSincePost > 7{
        dateFormatter.dateFormat = "MM.dd.yy"
        dateString = dateFormatter.string(from: postTimeAsDate) //10.02.16
    }else{
        dateFormatter.dateFormat = "MM.dd.yy - h:mm a"
        dateString = dateFormatter.string(from: postTimeAsDate) //10.02.16
    }
    
    return dateString
}


func openCoordinateInMap(_ latitude: Double, longitude: Double){
    let options = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving, MKLaunchOptionsShowsTrafficKey: true] as [String : Any]
    let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude), addressDictionary: nil))
    mapItem.openInMaps(launchOptions: options as? [String : AnyObject])
}

func logoutFromFirebase(_ completion: @escaping (_ complete: Bool) -> ()){
    do{
        try FIRAuth.auth()?.signOut()
        facebookLoginManager.logOut()
    }catch let logoutError{
        print(logoutError)
    }
    
    completion(true)
}

func getUser(_ completion: @escaping (_ user: User) -> ()){
    let user = User()
    if FIRAuth.auth()?.currentUser?.uid != nil{
    
        guard let userFromFIRAuth = FIRAuth.auth()?.currentUser else{
            return
        }
        
        guard let name = userFromFIRAuth.displayName, let email = userFromFIRAuth.email, let profileImageURL = userFromFIRAuth.photoURL else{
            return
        }
        
        user.setValuesForKeys(["id": userFromFIRAuth.uid, "name": name, "email": email, "profileImageURL": "\(profileImageURL)"])
        completion(user)
    }
}

func getFirebaseUser(user: User) -> User{
    let firebaseUser = User()
    
    if let userID = user.id{
        let userReference = FIRDatabase.database().reference().child("users/\(userID)")
        userReference.observeSingleEvent(of: .value, with: {(snapshot) in
            
            if let dictionary = snapshot.value as? [String: AnyObject]{
                firebaseUser.setValuesForKeys(dictionary)
            }
        })
    }
    
    return firebaseUser
}

func getLoadingView(text: String, backgroundColor: UIColor, activityIndicatorColor: UIColor) -> LoadingView{
    var loadingView = LoadingView()
    loadingView = Bundle.main.loadNibNamed("LoadingView", owner: nil, options: nil)?.last as! LoadingView
    loadingView.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
    loadingView.layer.zPosition = 100
    loadingView.backgroundColor = UIColor.clear
    loadingView.alpha = 0
    loadingView.backgroundView.layer.cornerRadius = 20
    loadingView.backgroundView.clipsToBounds = true
    loadingView.applyShadow(color: UIColor.black.flat, opacity: 0.8, radius: 5)
    loadingView.backgroundView.backgroundColor = backgroundColor
    loadingView.activityIndicatorView.color = activityIndicatorColor
    loadingView.loadingLabel.text = text
    return loadingView
}














