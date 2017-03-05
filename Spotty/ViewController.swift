//
//  ViewController.swift
//  Spotty
//
//  Created by Cameron Eubank on 7/30/16.
//  Copyright © 2016 Cameron Eubank. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import Firebase
import FBSDKLoginKit
import AlamofireImage
import DropDownMenuKit
//UICollectionViewDelegate
//UICollectionViewDataSource
//UICollectionViewDelegateFlowLayout
// UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout,
class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, UISearchBarDelegate, DropDownMenuDelegate{
    
    @IBOutlet var newPostButton: UIButton!
    @IBOutlet var menuBarButtonItem: UIBarButtonItem!
    @IBOutlet var zoomToUserLocationBarButtonItem: UIBarButtonItem!
    @IBOutlet var newPostBarButtonItem: UIBarButtonItem!
    @IBOutlet var refreshBarButtonItem: UIBarButtonItem!
    @IBOutlet var spotsInLocationLabel: UILabel!
    @IBOutlet var mapView: MKMapView!
//    @IBOutlet var collectionView: UICollectionView!
    
    //DropDownMenuKit
    var titleView: DropDownTitleView!
    @IBOutlet var navigationBarMenu: DropDownMenu!
    @IBOutlet var toolbarMenu: DropDownMenu!
    
    //search
    var resultSearchController:UISearchController? = nil

    @IBOutlet weak var searchBar: UISearchBar!
    
    //colors
    var lightBlue = UIColor(red:0.42, green:0.93, blue:1.00, alpha:1.0)
    var blurple = UIColor(red:0.25, green:0.00, blue:1.00, alpha:1.0)
    var black: UIColor = UIColor.black
    
    //map
    var annotation:MKAnnotation!
    var pointAnnotation:MKPointAnnotation!
    var pinAnnotationView:MKPinAnnotationView!
    var localSearchResponse:MKLocalSearchResponse!
    var localSearchRequest:MKLocalSearchRequest!
    var localSearch:MKLocalSearch!
    let searchRadius: CLLocationDistance = 120000
    
    var loggedInUser = User()
    let locationManager = CLLocationManager()
    var posts:[Post] = []
    var postAnnotations:[PostAnnotation] = []
    var loadingView = LoadingView()
    let userDefaults = UserDefaults()
    
    //post check
    var postCheck = false
    

    override func viewDidLoad() {
        super.viewDidLoad()
        //search
        searchBar.sizeToFit()
        searchBar.placeholder = "Search for places"
//        searchBar.self = resultSearchController?.searchBar
        searchBar.showsCancelButton = true
        searchBar.delegate = self
        
        
        resultSearchController?.hidesNavigationBarDuringPresentation = false
        resultSearchController?.dimsBackgroundDuringPresentation = true
        definesPresentationContext = true
        
        //DropDownMenuKit
        let title = prepareNavigationBarMenuTitleView()
        
        prepareNavigationBarMenu(title)
        prepareToolbarMenu()
        updateMenuContentOffsets()
        
//        //Menu Bar Button Item
        menuBarButtonItem.tintColor = UIColor.purple.light
        
        //Zoom to User Location Bar Button Item
        zoomToUserLocationBarButtonItem.target = self
        zoomToUserLocationBarButtonItem.action = #selector(zoomToCurrentUserLocation)
        zoomToUserLocationBarButtonItem.tintColor = UIColor.purple.light
        
        //New Post Bar Button Item
        newPostBarButtonItem.target = self
        newPostBarButtonItem.action = #selector(goToPostController)
        newPostBarButtonItem.tintColor = UIColor.purple.light
        newPostBarButtonItem.isEnabled = false
        
        newPostButton.addTarget(self, action: #selector(goToPostController), for: .touchUpInside)
        newPostButton.tintColor = black
        
        newPostButton.isEnabled = false
        
        
        //Refresh Bar Button Item
        refreshBarButtonItem.target = self
        refreshBarButtonItem.action = #selector(refreshPostData)
        refreshBarButtonItem.tintColor = UIColor.white.flat

    
        //Map View
        mapView.delegate = self
        mapView.showsUserLocation = true

        //Collection View comment out JT
//        collectionView.register(UINib(nibName: "MapPostCell", bundle: nil), forCellWithReuseIdentifier: "cell")
//        collectionView.delegate = self
//        collectionView.dataSource = self
//        collectionView.backgroundColor = UIColor.black.dark
//        let collectionViewLayout = UICollectionViewFlowLayout()
//        collectionViewLayout.scrollDirection = .horizontal
//        collectionView.collectionViewLayout = collectionViewLayout
//        collectionView.isScrollEnabled = true
        
        //Loading View
        loadingView = getLoadingView(text: "Fetching!", backgroundColor: UIColor.black.pure, activityIndicatorColor: UIColor.purple.light)
        loadingView.center = self.view.center
        view.addSubview(loadingView)
        
        //Get Logged In User
        getUser({(user) in
            self.loggedInUser = user
        })
        
        //Add Observer for Posts Being Deleted
        let postsReference = FIRDatabase.database().reference().child("posts")
        postsReference.observe(.childRemoved, with: {(snapshot) in
            self.refreshPostData()
        }, withCancel: nil)
        
        
        postsReference.observe(.childChanged, with: {(snapshot) in
            self.refreshPostData()
        }, withCancel: nil)
        
        //Reload Data
        refreshPostData()
        
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        checkIfUserIsLoggedIn()
        
        //added JT
        navigationBarMenu.container = view
        toolbarMenu.container = view
        
        //added JT
        self.mapView.setUserTrackingMode(MKUserTrackingMode.follow, animated: true);
    }
    
    //search
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        let locManager = CLLocationManager()
        var currentLocation = CLLocation()
        
        currentLocation = locManager.location!
        
        mapView.removeAnnotations(postAnnotations)
        self.mapView .removeAnnotations(self.mapView.annotations)
        
        self.searchBar.setShowsCancelButton(true, animated: true)
        self.searchBar.endEditing(true)
        postCheck = true
        
        let userLoction: CLLocation = currentLocation
        let latitude = userLoction.coordinate.latitude
        let longitude = userLoction.coordinate.longitude
        let latDelta: CLLocationDegrees = 1.0
        let lonDelta: CLLocationDegrees = 1.0
        let span:MKCoordinateSpan = MKCoordinateSpanMake(latDelta, lonDelta)
        let location: CLLocationCoordinate2D = CLLocationCoordinate2DMake(latitude, longitude)
        let region: MKCoordinateRegion = MKCoordinateRegionMake(location, span)
        self.mapView.setRegion(region, animated: true)
        self.mapView.showsUserLocation = true
        let initialLocation = CLLocation(latitude: latitude, longitude: longitude)
        
        
        // 8
        locationManager.stopUpdatingLocation()
        
        let request = MKLocalSearchRequest()
        
        let dirRequest = MKDirectionsRequest()
        
        request.naturalLanguageQuery = searchBar.text
        
        request.region = mapView.region
        
        //        request.region = MKCoordinateRegion(center: initialLocation.coordinate, span: span)
        request.region = MKCoordinateRegionMakeWithDistance(initialLocation.coordinate, 120701, 120701)
        
        let search = MKLocalSearch(request: request)
        search.start
            {
                response, error in
                guard let response = response else {
                    print("There was an error searching for: \(request.naturalLanguageQuery) error: \(error)")
                    return
                }
                
                for item in response.mapItems {
                    // Display the received items
                    print(item.name)
                    //                    self.mapView.addAnnotation(self.annotation)
                    self.addPinToMapView(item.name!, latitude: item.placemark.location!.coordinate.latitude, longitude: item.placemark.location!.coordinate.longitude)
                    self.postCheck = true
                }
        }

        
    }
    //search
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        
        // Clear any search criteria
        searchBar.text = ""
        
        // Dismiss the keyboard
        searchBar.resignFirstResponder()
        
        //remove annotations from search
        self.mapView .removeAnnotations(self.mapView.annotations)
        
        //post check
        postCheck = false

        //reload posts
        refreshPostData()
        
       
    }

    func checkIfUserIsLoggedIn(){
        
        if FIRAuth.auth()?.currentUser?.uid == nil{
            logoutFromFirebase({(complete) in
                self.showLoginController()
            })
        }else{
            newPostBarButtonItem.isEnabled = true
            newPostButton.isEnabled = true
        }
    }
    
    func refreshPostData(){
            //remove the annotations for full refresh
            mapView.removeAnnotations(postAnnotations)
            self.mapView .removeAnnotations(self.mapView.annotations)
        postCheck = false
        self.loadingView.startLoading()
        observePosts(completion: {(complete) in
            if complete{
                //comment out JT
//                self.showSpotsInLocationLabelWithText()
                self.loadingView.stopLoading()
            }
        })
    }
    //added JT
    //drop down kit
    //dropdown menu
    func prepareNavigationBarMenuTitleView() -> String {
        // Both title label and image view are fixed horizontally inside title
        // view, UIKit is responsible to center title view in the navigation bar.
        // We want to ensure the space between title and image remains constant,
        // even when title view is moved to remain centered (but never resized).
        titleView = DropDownTitleView(frame: CGRect(x: 0, y: 0, width: 150, height: 40))
        titleView.addTarget(self,
                            action: #selector(ViewController.willToggleNavigationBarMenu(_:)),
                            for: .touchUpInside)
        titleView.addTarget(self,
                            action: #selector(ViewController.didToggleNavigationBarMenu(_:)),
                            for: .valueChanged)
        titleView.titleLabel.textColor = UIColor.white
        
        //replace choozy with pic
//        let logo = UIImage(named: "choozyTitle")
//        let logoView = UIImageView(image:logo)
//        navigationItem.titleView = logoView
//
//        this works
        titleView.title = "Choozy"
        navigationItem.titleView = titleView
        
        
        return titleView.title!
    }
    
    func prepareNavigationBarMenu(_ currentChoice: String) {
        navigationBarMenu = DropDownMenu(frame: view.bounds)
        navigationBarMenu.delegate = self
        
        let firstCell = DropDownMenuCell()
        
        firstCell.textLabel!.text = "Eat"
        firstCell.textLabel?.textAlignment = NSTextAlignment.center
        firstCell.backgroundColor = UIColor.black
        firstCell.textLabel!.textColor = UIColor.white
        firstCell.menuAction = #selector(ViewController.choose(_:))
        firstCell.menuTarget = self
        if currentChoice == "Eat" {
            firstCell.accessoryType = .checkmark
        }
        
        let secondCell = DropDownMenuCell()
        
        secondCell.textLabel!.text = "Drink"
        secondCell.textLabel?.textAlignment = NSTextAlignment.center
        secondCell.backgroundColor = UIColor.black
        secondCell.textLabel!.textColor = UIColor.white
        secondCell.menuAction = #selector(ViewController.choose(_:))
        secondCell.menuTarget = self
        if currentChoice == "Drink" {
            firstCell.accessoryType = .checkmark
        }
        
        let thirdCell = DropDownMenuCell()
        
        thirdCell.textLabel!.text = "Play"
        thirdCell.textLabel?.textAlignment = NSTextAlignment.center
        thirdCell.backgroundColor = UIColor.black
        thirdCell.textLabel!.textColor = UIColor.white
        thirdCell.menuAction = #selector(ViewController.choose(_:))
        thirdCell.menuTarget = self
        if currentChoice == "Play" {
            firstCell.accessoryType = .checkmark
        }
        
        let fourthCell = DropDownMenuCell()
        
        fourthCell.textLabel!.text = "Posts"
        fourthCell.textLabel?.textAlignment = NSTextAlignment.center
        fourthCell.backgroundColor = UIColor.black
        fourthCell.textLabel!.textColor = UIColor.white
        fourthCell.menuAction = #selector(ViewController.choose(_:))
        fourthCell.menuTarget = self
        if currentChoice == "Posts" {
            firstCell.accessoryType = .checkmark
        }
        
        navigationBarMenu.menuCells = [firstCell, secondCell, thirdCell, fourthCell]
        
        // If we set the container to the controller view, the value must be set
        // on the hidden content offset (not the visible one)
        navigationBarMenu.visibleContentOffset =
            navigationController!.navigationBar.frame.size.height + statusBarHeight()
        
        // For a simple gray overlay in background
        navigationBarMenu.backgroundView = UIView(frame: navigationBarMenu.bounds)
        navigationBarMenu.backgroundView!.backgroundColor = UIColor.black
        navigationBarMenu.backgroundAlpha = 0.7
    }
    
    func prepareToolbarMenu() {
        toolbarMenu = DropDownMenu(frame: view.bounds)
        toolbarMenu.delegate = self
        
        let selectCell = DropDownMenuCell()
        
        selectCell.textLabel!.text = "Select"
        selectCell.imageView!.image = UIImage(named: "Ionicons-ios-checkmark-outline")
        selectCell.showsCheckmark = false
        selectCell.menuAction = #selector(ViewController.select as (ViewController) -> () -> ())
        selectCell.menuTarget = self
        
        let sortKeys = ["Name", "Date", "Size"]
        let sortCell = DropDownMenuCell()
        let sortSwitcher = UISegmentedControl(items: sortKeys)
        
        sortSwitcher.selectedSegmentIndex = sortKeys.index(of: "Name")!
        sortSwitcher.addTarget(self, action: #selector(ViewController.sort(_:)), for: .valueChanged)
        
        sortCell.customView = sortSwitcher
        sortCell.textLabel!.text = "Sort"
        sortCell.imageView!.image = UIImage(named: "Ionicons-ios-search")
        sortCell.showsCheckmark = false
        
        toolbarMenu.menuCells = [selectCell, sortCell]
        toolbarMenu.direction = .up
        
        // For a simple gray overlay in background
        toolbarMenu.backgroundView = UIView(frame: toolbarMenu.bounds)
        toolbarMenu.backgroundView!.backgroundColor = UIColor.black
        toolbarMenu.backgroundAlpha = 0.7
    }
    
    func updateMenuContentOffsets() {
        navigationBarMenu.visibleContentOffset =
            navigationController!.navigationBar.frame.size.height + statusBarHeight()
        toolbarMenu.visibleContentOffset =
            navigationController!.toolbar.frame.size.height
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { (context) in
            // If we put this only in -viewDidLayoutSubviews, menu animation is
            // messed up when selecting an item
            self.updateMenuContentOffsets()
        }, completion: nil)
    }
    
    @IBAction func choose(_ sender: AnyObject) {
        titleView.title = (sender as! DropDownMenuCell).textLabel!.text
        print((sender as! DropDownMenuCell).textLabel!.text)
        //        refresh(location)
        
        self.mapView .removeAnnotations(self.mapView.annotations)
        
        let locManager = CLLocationManager()
        var currentLocation = CLLocation()
        
        currentLocation = locManager.location!
        
        let userLoction: CLLocation = currentLocation
        let latitude = userLoction.coordinate.latitude
        let longitude = userLoction.coordinate.longitude
        let latDelta: CLLocationDegrees = 0.09
        let lonDelta: CLLocationDegrees = 0.09
        let span:MKCoordinateSpan = MKCoordinateSpanMake(latDelta, lonDelta)
        let location: CLLocationCoordinate2D = CLLocationCoordinate2DMake(latitude, longitude)
        let region: MKCoordinateRegion = MKCoordinateRegionMake(location, span)
        self.mapView.setRegion(region, animated: true)
        self.mapView.showsUserLocation = true
        let initialLocation = CLLocation(latitude: latitude, longitude: longitude)
        
        
        // 8
        locationManager.stopUpdatingLocation()
        
        let request = MKLocalSearchRequest()
        
        let dirRequest = MKDirectionsRequest()
        
        
        if titleView.title == "Drink" {
            request.naturalLanguageQuery = "Bar"
            postCheck = true
        }
        
        if titleView.title == "Eat" {
            request.naturalLanguageQuery = "Eat"
            postCheck = true
        }
        
        if titleView.title == "Play" {
            request.naturalLanguageQuery = "Entertainment"
            postCheck = true
        }
        
        if titleView.title == "Choice" {
            request.naturalLanguageQuery = "Venue"
        }
        
        if titleView.title == "Posts" {
            postCheck = false
            //reload posts
            refreshPostData()
        }
        
        request.region = mapView.region
        
        //        request.region = MKCoordinateRegion(center: initialLocation.coordinate, span: span)
        request.region = MKCoordinateRegionMakeWithDistance(initialLocation.coordinate, 120701, 120701)
        
        let search = MKLocalSearch(request: request)
        search.start
            {
                response, error in
                guard let response = response else {
                    print("There was an error searching for: \(request.naturalLanguageQuery) error: \(error)")
                    return
                }
                
                for item in response.mapItems {
                    // Display the received items
                    print(item.name)
                    //                    self.mapView.addAnnotation(self.annotation)
                    self.addPinToMapView(item.name!, latitude: item.placemark.location!.coordinate.latitude, longitude: item.placemark.location!.coordinate.longitude)
                    
                }
        }
        
    }
    
    @IBAction func select() {
        print("Sent select action")
    }
    
    @IBAction func sort(_ sender: AnyObject) {
        print("Sent sort action")
    }
    
    @IBAction func showToolbarMenu() {
        if titleView.isUp {
            titleView.toggleMenu()
        }
        toolbarMenu.show()
    }
    
    @IBAction func willToggleNavigationBarMenu(_ sender: DropDownTitleView) {
        toolbarMenu.hide()
        
        if sender.isUp {
            navigationBarMenu.hide()
        }
        else {
            navigationBarMenu.show()
        }
    }
    
    @IBAction func didToggleNavigationBarMenu(_ sender: DropDownTitleView) {
        print("Sent did toggle navigation bar menu action")
        //        refresh(locationManager)
        
    }
    
    func didTapInDropDownMenuBackground(_ menu: DropDownMenu) {
        if menu == navigationBarMenu {
            titleView.toggleMenu()
        }
        else {
            menu.hide()
        }
    }

    func observePosts(completion: @escaping (_ complete: Bool) -> ()){
        
        //Clear our Posts Array and MapView
        posts.removeAll()
        mapView.removeAnnotations(postAnnotations)
        postAnnotations.removeAll()
        
        //Get the user' current coordinates
        let userLocationCoordinates = self.locationManager.getCurrentLocationCoordinates()
        let userLocation = CLLocation(latitude: userLocationCoordinates.latitude, longitude: userLocationCoordinates.longitude)
        
        //Get Current NSUserDefault search radius in Miles.
        let searchRadius = userDefaults.getDistance()

        let postsReference = FIRDatabase.database().reference().child("posts")
        postsReference.observe(.childAdded, with: {(snapshot) in
            if snapshot.exists(){
                if let dictionary = snapshot.value as? [String: AnyObject]{
                    let post = Post()
                    post.setValuesForKeys(dictionary)
                    
                    //Get CLLocation object from Post Latitude/Longitude
                    guard let postLatitude = post.latitude as? CLLocationDegrees, let postLongitude = post.longitude as? CLLocationDegrees else{
                        return
                    }
                    let postLocation = CLLocation(latitude: postLatitude, longitude: postLongitude)
                    
                    //Only show Posts that are within the searchRadius
                    if isPointWithinMilesFromUser(userLocation: userLocation, postLocation: postLocation, miles: Double(searchRadius)){
                        self.posts.append(post)
                        self.addPostAnnotationToMapView(post)
                    }
                    
                    //Sort the posts array to show the most recent posts IF there is more than 1 post.
                    if self.posts.count > 1{
                        self.posts.sort(by: {(post1, post2) ->
                            Bool in
                            return (post1.timeStamp?.int32Value)! > (post2.timeStamp?.int32Value)!
                        })
                    }
                }
                
//                DispatchQueue.main.async(execute: {
//                    self.collectionView.reloadData()
//                })
                
                completion(true)
        
            }
            
        }, withCancel: nil)
        
        if posts.count == 0 {
//            self.showSpotsInLocationLabelWithText()
            self.loadingView.stopLoading()
        }
    }
    
    //added JT
    //map
    func addPinToMapView(_ title: String, latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let annotation = MyAnnotation(coordinate: location, title: title)
        
        let place = Place()
        place.name = title
        place.latitude = longitude
        place.longitude = longitude
    
        annotation.place = place
        
        mapView.addAnnotation(annotation)
        
    }
    //added JT
    //map
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        
        if locations.first != nil {
            
            // 7
            let userLoction: CLLocation = locations[0]
            let latitude = userLoction.coordinate.latitude
            let longitude = userLoction.coordinate.longitude
            let latDelta: CLLocationDegrees = 0.09
            let lonDelta: CLLocationDegrees = 0.09
            let span:MKCoordinateSpan = MKCoordinateSpanMake(latDelta, lonDelta)
            let location: CLLocationCoordinate2D = CLLocationCoordinate2DMake(latitude, longitude)
            let region: MKCoordinateRegion = MKCoordinateRegionMake(location, span)
            self.mapView.setRegion(region, animated: true)
            self.mapView.showsUserLocation = true
            let initialLocation = CLLocation(latitude: latitude, longitude: longitude)
            
            let sourcePlaceMark = MKPlacemark(coordinate: location, addressDictionary: nil)
            
            // 8
            locationManager.stopUpdatingLocation()
            
            let request = MKLocalSearchRequest()
            
            if titleView.title == "Drink" {
                request.naturalLanguageQuery = "Bar"
                postCheck = true
            }
            
            if titleView.title == "Eat" {
                request.naturalLanguageQuery = "Eat"
                postCheck = true

            }
            
            if titleView.title == "Play" {
                request.naturalLanguageQuery = "Entertainment"
                postCheck = true

            }
            
            if titleView.title == "Choice" {
                request.naturalLanguageQuery = "Entertainment"
                postCheck = true

            }
            
            request.naturalLanguageQuery = "Food and Drink"
            request.region = mapView.region
            
            //            request.region = MKCoordinateRegion(center: initialLocation.coordinate, span: span)
            request.region = MKCoordinateRegionMakeWithDistance(initialLocation.coordinate, 120000, 120000)
            let search = MKLocalSearch(request: request)
            search.start { response, error in
                guard let response = response else {
                    print("There was an error searching for: \(request.naturalLanguageQuery) error: \(error)")
                    return
                }
                
                for item in response.mapItems {
                    // Display the received items
                    print(item.name)
                    //                    self.mapView.addAnnotation(self.annotation)
                    self.addPinToMapView(item.name!, latitude: item.placemark.location!.coordinate.latitude, longitude: item.placemark.location!.coordinate.longitude)
                    
                }
            }
            
        }
        
    }
    func addPostAnnotationToMapView(_ post: Post){

        guard let latitude = post.latitude as? Double, let longitude = post.longitude as? Double else{
            return
        }
        
        let point = PostAnnotation(coordinate: CLLocationCoordinate2DMake(latitude, longitude))
        point.coordinate = CLLocationCoordinate2DMake(latitude, longitude)
        point.post = post
        postAnnotations.append(point)
        
        mapView.showAnnotations(postAnnotations, animated: true)
    }

    //comment out JT
//    func showSpotsInLocationLabelWithText(){
//        let count = self.posts.count
//        var spotsInLocationLabelText = String()
//        if count == 1{
//            spotsInLocationLabelText = "Found \(count) spot near you."
//        }else{
//            spotsInLocationLabelText = "Found \(count) spots near you."
//        }
//        
//        self.spotsInLocationLabel.text = spotsInLocationLabelText
//        self.spotsInLocationLabel.fadeIn()
//        
////        locationManager.getCurrentLocationDictionary({locationDictionary in
////            var spotsInLocationLabelText = String()
////            let count = self.posts.count
////            
////            guard let city = locationDictionary["city"], let state = locationDictionary["state"] else{
////                spotsInLocationLabelText = "Found \(count) in your location"
////                self.spotsInLocationLabel.text = spotsInLocationLabelText
////                self.spotsInLocationLabel.fadeIn()
////                
////                return
////            }
////            
////            if count == 1{
////                spotsInLocationLabelText = "Found \(count) spot in \(city), \(state)"
////            }else{
////                spotsInLocationLabelText = "Found \(count) spots in \(city), \(state)"
////            }
////            
////            self.spotsInLocationLabel.text = spotsInLocationLabelText
////            self.spotsInLocationLabel.fadeIn()
////        })
//    }
    //added JT
    //annotations and adding click options
    func openMapsAppWithDirections(to coordinate: CLLocationCoordinate2D, destinationName name: String) {
        let options = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
        let placemark = MKPlacemark(coordinate: coordinate, addressDictionary: nil)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = name // Provide the name of the destination in the To: field
        mapItem.openInMaps(launchOptions: options)
    }
    
//    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
//        if annotation is MKUserLocation {
//            return nil
//        }
//        let reuseID = "pin"
//        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseID) as? MKPinAnnotationView
//        if(pinView == nil) {
//            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
//            pinView!.canShowCallout = true
//            pinView!.animatesDrop = true
//            //            pinView!.rightCalloutAccessoryView = UIButton(type: UIButtonType.detailDisclosure) as UIButton
//            let smallSquare = CGSize(width: 30, height: 30)
//            let button = UIButton(frame: CGRect(origin: CGPoint.zero, size: smallSquare))
//            button.setBackgroundImage(UIImage(named: "Car"), for: UIControlState())
//            pinView?.leftCalloutAccessoryView = button
//        }
//        else
//        {
//            pinView!.annotation = annotation
//        }
//        
//        
//        return pinView
//        
//    }
    //comment out JT
//    var calloutView = MapPostCell()
    
    
    func mapView(_ MapView: MKMapView, annotationView: MKAnnotationView, calloutAccessoryControlTapped Control: UIControl) {
        
        if Control == annotationView.leftCalloutAccessoryView {
            if let annotation = annotationView.annotation {
                // Unwrap the double-optional annotation.title property or
                // name the destination "Unknown" if the annotation has no title
                let destinationName = (annotation.title ?? nil) ?? "Unknown"
                openMapsAppWithDirections(to: annotation.coordinate, destinationName: destinationName)
            }
        }
        if Control == annotationView.rightCalloutAccessoryView {
     
            let myAnnotation = annotationView.annotation as! MyAnnotation
            let place = myAnnotation.place
            showPlaceController(place)
            
//            if let annotation = annotationView.annotation {
//                
//                
//                
//                
////                let alert = UIAlertController(title: "Alert", message: "Go To Other Scene Page", preferredStyle: UIAlertControllerStyle.alert)
////                alert.addAction(UIAlertAction(title: "Click", style: UIAlertActionStyle.default, handler: nil))
////                self.present(alert, animated: true, completion: nil)
//            }
        }

    }
    ///////////////////////////////////////// /////////
    func zoomToCurrentUserLocation(){
        let location = locationManager.getCurrentLocationCoordinates()
        let region = MKCoordinateRegionMake(CLLocationCoordinate2DMake(location.latitude, location.longitude), MKCoordinateSpanMake(0.125, 0.125))
        mapView.setRegion(region, animated: true)
    }
    func outToCurrentUserLocation(){
        let location = locationManager.getCurrentLocationCoordinates()
        let region = MKCoordinateRegionMake(CLLocationCoordinate2DMake(location.latitude, location.longitude), MKCoordinateSpanMake(0.2, 0.2))
        mapView.setRegion(region, animated: true)
    }
    
    func goToPostController(){
        guard let name = loggedInUser.name, let profileImageURL = loggedInUser.profileImageURL else{
            print("no name, or URL")
            return
        }
        
        self.showPostController(name, userImageURL: profileImageURL)
    }
    
    // MARK: - Core Location Delegate
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus){
        if (status == CLAuthorizationStatus.denied) {
            showAlertWithURL("Whoops!", message: "Location services must be enabled to use this app. Enable location services for this app in your device Settings.", urlMessage: "Open Settings", URL: UIApplicationOpenSettingsURLString)
        }
    }
//    mapView.removeAnnotations(postAnnotations)
//    self.mapView .removeAnnotations(self.mapView.annotations)
    
    //MARK: MapKit Delegate Methods
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if view.annotation!.isKind(of: MKLocalSearchRequest.self){
            print("mksearch")
        }else if (postCheck == false){
            let postAnnotation = view.annotation as! PostAnnotation
            showDetailController(postAnnotation.post)
            print(postAnnotation.post)
        }
        
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard !(annotation is MKUserLocation) else {
            return nil
        }
        
        let annotationIdentifier = "AnnotationIdentifier"
        //added JT
        let reuseID = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseID) as? MKPinAnnotationView
        if (pinView == nil) {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
            pinView!.canShowCallout = true
            pinView!.animatesDrop = true
            let smallSquare = CGSize(width: 30, height: 30)
            
            //left button annotation
            let button = UIButton(frame: CGRect(origin: CGPoint.zero, size: smallSquare))
            button.setBackgroundImage(UIImage(named: "CarIcon"), for: UIControlState())
            pinView?.leftCalloutAccessoryView = button
            
            //right button annotation
            pinView!.rightCalloutAccessoryView = UIButton(type: UIButtonType.detailDisclosure) as UIButton
            let rightButton = UIButton(frame: CGRect(origin: CGPoint.zero, size: smallSquare))
            rightButton.tintColor = UIColor.red
            rightButton.setBackgroundImage(UIImage(named: "ChoozyOut"), for: UIControlState())
            pinView?.rightCalloutAccessoryView = rightButton

        }
        else
        {
            pinView!.annotation = annotation
        }

        
        var annotationView: MKAnnotationView?
        if let dequeuedAnnotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIdentifier) {
            annotationView = dequeuedAnnotationView
            annotationView?.annotation = annotation
        }
        else {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
            annotationView?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        
        if let postAnnotation = annotationView?.annotation as? PostAnnotation {
            
            guard let category = postAnnotation.post.category else{
                return nil
            }
            
            let pinImage = UIImage(named: category)
            let size = CGSize(width: 30, height: 30)
            UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
            pinImage?.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height), blendMode: .normal, alpha: 1.0)
            let img = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            print(category)
            annotationView?.image = img
            
        }   
        
        if (postCheck == true) {
            return pinView
        } else {
           
            return pinAnnotationView
  
        }
       
  
    }

    //comment out JT
    //MARK: - Collection View Delegate & DataSource
//    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell{
//        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! MapPostCell
//        let post = posts[(indexPath as NSIndexPath).row]
//        cell.post = post
//        return cell
////    }
//    
//    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        //Show the Detail Controller with the information for the Post Selected.
//        let post = posts[(indexPath as NSIndexPath).row]
//        self.showDetailController(post)
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return posts.count
//    }
//    
//    //Size of the Cell
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
//        return CGSize(width: 80, height: 80)
//    }
//    
//    //Line Spacing
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
//        return 5
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
//        return 5
//    }
    
    //MARK: - Prepare for Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "detail" {
            let detailController: DetailController = segue.destination as! DetailController
            detailController.post = (sender as? Post)!
        }
        
        if segue.identifier == "showPlace"{
            let placeController: PlaceController = segue.destination as! PlaceController
            placeController.place = (sender as? Place)!
        }
    }
    func statusBarHeight() -> CGFloat {
        let statusBarSize = UIApplication.shared.statusBarFrame.size
        return min(statusBarSize.width, statusBarSize.height)
    }
}

