//
//  PlaceContoller.swift
//  
//
//  Created by joseph mckee on 11/9/16.
//
//

import Foundation
import CoreLocation
import UIKit
import Firebase

class PlaceController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var postsCollectionView: UICollectionView!
    //CHT
//    let model = Model()

    var posts: [Post] = []
    var place = Place()
    let locationManager = CLLocationManager()
    
    override func viewDidLoad(){
        super.viewDidLoad()
        
        let collectionViewLayout = UICollectionViewFlowLayout()
        collectionViewLayout.scrollDirection = .vertical
        
        postsCollectionView.register(UINib(nibName: "PlaceCell", bundle: nil), forCellWithReuseIdentifier: "cell")
        
        //CHT
        postsCollectionView.delegate = self
        postsCollectionView.dataSource = self
        
        postsCollectionView.backgroundColor = UIColor.black.dark
        postsCollectionView.collectionViewLayout = collectionViewLayout
        postsCollectionView.isScrollEnabled = true
        
   
        title = place.name!
        print("right screen")
        retrievePostsForPlace(latitude: place.latitude!, longitude: place.longitude!)
    }
    
    
    
    
    func retrievePostsForPlace(latitude: Double, longitude: Double){
        
        //Get the user' current coordinates
        let userLocationCoordinates = locationManager.getCurrentLocationCoordinates()
        let userLocation = CLLocation(latitude: userLocationCoordinates.latitude, longitude: userLocationCoordinates.longitude)
        
        let postsReference = FIRDatabase.database().reference().child("posts")
        postsReference.observe(.childAdded, with: {(snapshot) in
            
            if let dictionary = snapshot.value as? [String: AnyObject]{
                
                let post = Post()
                post.setValuesForKeys(dictionary)
                
                //Get CLLocation object from Post Latitude/Longitude
                guard let postLatitude = post.latitude as? CLLocationDegrees, let postLongitude = post.longitude as? CLLocationDegrees else{
                    return
                }
                
                let postLocation = CLLocation(latitude: postLatitude, longitude: postLongitude)
                
                if isPointWithinMilesFromUser(userLocation: userLocation, postLocation: postLocation, miles: 0.019){ //Translates to 40-ish feet.
                    self.posts.append(post)
                }
                
                //Sort the posts array to show the most recent posts.
                self.posts.sort(by: {(post1, post2) ->
                    Bool in
                    return (post1.timeStamp?.int32Value)! > (post2.timeStamp?.int32Value)!
                })
            }
            
            DispatchQueue.main.async(execute: {
                self.postsCollectionView.reloadData()
            })
        })
    }
    
    //MARK: - Collection View Delegate & DataSource
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell{
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! PlaceCell
        let post = posts[(indexPath as NSIndexPath).row]
        cell.post = post
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //Show the Detail Controller with the information for the Post Selected.
        let post = posts[(indexPath as NSIndexPath).row]
        self.showDetailControllerFromPlace(post)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count
    }
    
//    //Size of the Cell
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
//        return CGSize(width: view.bounds.width / 3 - 1, height: view.bounds.width / 3 - 1)
//    }
    
    //Line Spacing
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1.0
    }
    
    //MARK: - Prepare for Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "detailFromPlace" {
            let detailController: DetailController = segue.destination as! DetailController
            detailController.post = (sender as? Post)!
        }
    }
    
}
