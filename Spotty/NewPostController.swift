//
//  NewPostController.swift
//  Spotty
//
//  Created by Cameron Eubank on 9/5/16.
//  Copyright © 2016 Cameron Eubank. All rights reserved.
//

import UIKit
import CoreLocation
import Firebase
import MobileCoreServices
import MediaPlayer
import AlamofireImage

class NewPostController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate, UIGestureRecognizerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var mediaView: UIView!
    @IBOutlet var filtersCollectionView: UICollectionView!
    @IBOutlet var commentOverlayView: UIView!
    @IBOutlet var postCommentTextField: UITextField!
    @IBOutlet var postFlatButton: UIButton!
    @IBOutlet var postParkButton: UIButton!
    @IBOutlet var postStairButton: UIButton!
    @IBOutlet var postUserImageView: UIImageView!
    @IBOutlet var postLocationImageView: UIImageView!
    @IBOutlet var postLocationLabel: UILabel!
    @IBOutlet var postAsUserButton: UIButton!
    var loadingView = LoadingView()
    var moviePlayerController = MPMoviePlayerController()
    var postImageView = UIImageView()
    
    var locationManager = CLLocationManager()
    var location = Location()
    
    var defaultCameraImage = UIImage(named: "cameraImage")
    
    var userName = String()
    var userImageURL = String()
    
    var postType = ""
    var colorScheme = (dark: UIColor(), flat: UIColor())
    
    var filters:[ImageFilter] = [ImageFilter.filters.none, ImageFilter.filters.sepia, ImageFilter.filters.xRay, ImageFilter.filters.circularScreen, ImageFilter.filters.halfTone, ImageFilter.filters.heightField, ImageFilter.filters.pixels, ImageFilter.filters.toneCurve, ImageFilter.filters.lineOverlay, ImageFilter.filters.lineScreen, ImageFilter.filters.maskToAlpha, ImageFilter.filters.maxComponent, ImageFilter.filters.minComponent, ImageFilter.filters.chrome, ImageFilter.filters.fade, ImageFilter.filters.instant, ImageFilter.filters.mono, ImageFilter.filters.noir, ImageFilter.filters.process, ImageFilter.filters.tonal, ImageFilter.filters.transfer, ImageFilter.filters.spotColor, ImageFilter.filters.linearCurve, ImageFilter.filters.thermal]
    
 
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.layoutIfNeeded()
        
        //Get a Random Color Scheme
        colorScheme = UIColor().randomColorScheme()
        
        //Background Color
        self.view.backgroundColor = colorScheme.dark
        self.view.translatesAutoresizingMaskIntoConstraints = true
        
        self.view.center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
        self.view.autoresizingMask = [UIViewAutoresizing.flexibleLeftMargin, UIViewAutoresizing.flexibleRightMargin, UIViewAutoresizing.flexibleTopMargin, UIViewAutoresizing.flexibleBottomMargin]
        
        //Media View
        mediaView.backgroundColor = colorScheme.flat
        
        //Post Image View
        postImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: mediaView.bounds.width, height: mediaView.bounds.width))
        postImageView.center = mediaView.center
        postImageView.layer.zPosition = mediaView.layer.zPosition
        postImageView.backgroundColor = colorScheme.flat
        postImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleImageViewTapped)))
        postImageView.isUserInteractionEnabled = true
        postImageView.contentMode = .scaleAspectFill
        postImageView.isUserInteractionEnabled = true
        
        //filtersCollectionView
        filtersCollectionView.register(UINib(nibName: "ImageFilterCell", bundle: nil), forCellWithReuseIdentifier: "cell")
        filtersCollectionView.delegate = self
        filtersCollectionView.dataSource = self
        filtersCollectionView.backgroundColor = colorScheme.flat
        let collectionViewLayout = UICollectionViewFlowLayout()
        collectionViewLayout.scrollDirection = .horizontal
        filtersCollectionView.collectionViewLayout = collectionViewLayout
        filtersCollectionView.isScrollEnabled = true
        
        //Category Buttons
        postFlatButton.backgroundColor = colorScheme.flat
        postFlatButton.tag = 1
        postFlatButton.addTarget(self, action: #selector(setCategoryForPost), for: .touchUpInside)
        postParkButton.backgroundColor = colorScheme.flat
        postParkButton.tag = 2
        postParkButton.addTarget(self, action: #selector(setCategoryForPost), for: .touchUpInside)
        postStairButton.backgroundColor = colorScheme.flat
        postStairButton.tag = 3
        postStairButton.addTarget(self, action: #selector(setCategoryForPost), for: .touchUpInside)
        
        //Comment Overlay View
        commentOverlayView.backgroundColor = colorScheme.flat
        
        //Post Comment Text View
        postCommentTextField.backgroundColor = UIColor.clear
        postCommentTextField.textColor = UIColor.white
        postCommentTextField.delegate = self
        
        //Post Location Label
        postLocationLabel.backgroundColor = colorScheme.flat
        
        //Post as User Button
        postAsUserButton.backgroundColor = colorScheme.flat
        postAsUserButton.addTarget(self, action: #selector(createPost), for: .touchUpInside)
        
        //Down Gesture Recognizer to dismiss the view controller.
        let downGesture = UISwipeGestureRecognizer(target: self, action: #selector(dismissViewController))
        downGesture.direction = .down
        self.view.addGestureRecognizer(downGesture)
        
        //Set views for before picture taken
        setViewsForBeforePictureTaken()
        
        //Loading View
        loadingView = getLoadingView(text: "Posting...", backgroundColor: colorScheme.dark, activityIndicatorColor: UIColor.white.flat)
        loadingView.alpha = 0
        loadingView.center = scrollView.center
        view.addSubview(loadingView)
        
        //SetupCamera
        openCamera()
    }
    
    func setViewsForBeforePictureTaken(){
        
        postImageView.image = defaultCameraImage
        
        postCommentTextField.attributedPlaceholder = NSAttributedString(string:"--", attributes: [NSForegroundColorAttributeName: UIColor(r: 255, g: 255, b: 255, a: 1.0)])
        postCommentTextField.isEnabled = false
        
        postFlatButton.setTitle("--", for: UIControlState())
        postFlatButton.isEnabled = false
        
        postParkButton.setTitle("--", for: UIControlState())
        postParkButton.isEnabled = false
        
        postStairButton.setTitle("--", for: UIControlState())
        postStairButton.isEnabled = false
        
        postLocationImageView.image = nil
        postLocationImageView.alpha = 0.0
        
        postLocationLabel.text = "--"
        
        postAsUserButton.setTitle("--", for: UIControlState())
        postAsUserButton.isEnabled = false
    }
    
    func setViewsForAfterPictureTaken(){

        filtersCollectionView.fadeIn()
        filtersCollectionView.reloadData()
        
        postUserImageView.af_setImage(withURL: URL(string: userImageURL)!, placeholderImage: UIImage(named: "person"), filter: AspectScaledToFillSizeCircleFilter(size: postUserImageView.frame.size), imageTransition: .crossDissolve(0.1))
        
        postCommentTextField.attributedPlaceholder = NSAttributedString(string:"Say something about this spot...", attributes: [NSForegroundColorAttributeName: UIColor.white.flat.withAlphaComponent(0.7)])
        postCommentTextField.isEnabled = true
        postCommentTextField.tintColor = colorScheme.dark
        NotificationCenter.default.addObserver(self, selector: #selector(NewPostController.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(NewPostController.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        postFlatButton.setTitle("Eat", for: UIControlState())
        postFlatButton.isEnabled = true
        
        postParkButton.setTitle("Drink", for: UIControlState())
        postParkButton.isEnabled = true
        
        postStairButton.setTitle("Play", for: UIControlState())
        postStairButton.isEnabled = true
        
        postLocationImageView.image = defaultCameraImage
        postLocationImageView.fadeIn()
        
        guard let subAddress = location.subAddress, let address = location.address, let city = location.city else{
            return
        }
        
        postLocationLabel.text = subAddress + " " + address + " - " + city
        
        postAsUserButton.setTitle("Post as " + userName, for: UIControlState())
        postAsUserButton.isEnabled = true
    }
    
    func handleImageViewTapped() {
        if postImageView.image == defaultCameraImage{
            openCamera()
        }
    }

    func applyFilterToImage(image: UIImage, filter: ImageFilter) -> UIImage{
        
        var filteredImage = UIImage()
    
        if postImageView.image != defaultCameraImage{
            postImageView.image = selectedImageFromPicker!
                if postImageView.image != defaultCameraImage{
                    let context = CIContext(options: nil)
   
                    if let currentFilter = CIFilter(name: filter.name!) {
                        let beginImage = CIImage(image: postImageView.image!)
                        if currentFilter.inputKeys.contains(kCIInputImageKey) {currentFilter.setValue(beginImage, forKey: kCIInputImageKey)}
                        if currentFilter.inputKeys.contains(kCIInputIntensityKey) {currentFilter.setValue(filter.intensity, forKey: kCIInputIntensityKey)}

                        if let output = currentFilter.outputImage {
                            if let cgimg = context.createCGImage(output, from: output.extent) {
                                let processedImage = UIImage(cgImage: cgimg)
                                filteredImage = processedImage
                            }
                        }
                    }
                }
            }
        
        return filteredImage
    }
    
    func setCategoryForPost(_ sender: UIButton){
        
        if sender.tag == 1{
            postFlatButton.backgroundColor = UIColor().randomFlatColor()
            postParkButton.backgroundColor = colorScheme.flat
            postStairButton.backgroundColor = colorScheme.flat
            postType = "Flat"
        }else if sender.tag == 2{
            postFlatButton.backgroundColor = colorScheme.flat
            postParkButton.backgroundColor = UIColor().randomFlatColor()
            postStairButton.backgroundColor = colorScheme.flat
            postType = "Park"
        }else if sender.tag == 3{
            postFlatButton.backgroundColor = colorScheme.flat
            postParkButton.backgroundColor = colorScheme.flat
            postStairButton.backgroundColor = UIColor().randomFlatColor()
            postType = "Stair"
        }
    }
    
    func openCamera() {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera){
            let picker = UIImagePickerController()
            picker.view.frame = self.view.bounds
            picker.delegate = self
            picker.sourceType = UIImagePickerControllerSourceType.camera
            picker.mediaTypes = [kUTTypeMovie as String, kUTTypeImage as String]
            picker.allowsEditing = true
            self.view.addSubview(picker.view)
            present(picker, animated: true, completion: nil)
        }
    }
    
    var selectedMovieURL: URL?
    var selectedImageFromPicker: UIImage?
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {

        guard let mediaType = info[UIImagePickerControllerMediaType] as? String else{
            return
        }

        if mediaType.contains("movie"){
            
            if let movieURL = info["UIImagePickerControllerMediaURL"] as? URL{
                selectedMovieURL = movieURL
            }
            if let selectedMovie = selectedMovieURL{
                locationManager.getCurrentLocationDictionary(){
                    (data: [String: String]) in data //Retrieve data from our getCurrentLocationDictionary() completion handler.
                    
                    //Map the location object with data retrieved from the completion handler of our getCurrentLocationDictionary() method.
                    self.location.setValuesForKeys(data)
                    
                    if (self.location.city != nil || self.location.city != "") && (self.location.state != nil || self.location.state != ""){
                        self.setViewsForAfterPictureTaken()
                        picker.view.fadeOut()
                        self.filtersCollectionView.isUserInteractionEnabled = false
        
                        self.moviePlayerController = MPMoviePlayerController(contentURL: selectedMovie)
                            if let player = self.moviePlayerController as? MPMoviePlayerController{
                                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.startStopMoviePlayer))
                                tapGesture.delegate = self
                                player.view.frame = self.mediaView.bounds
                                player.scalingMode = .aspectFill
                                player.isFullscreen = false
                                player.controlStyle = .none
                                player.repeatMode = .one
                                player.view.isUserInteractionEnabled = true
                                player.view.addGestureRecognizer(tapGesture)
                                self.mediaView.addSubview(player.view)
                            
                                //self.dismiss(animated: true, completion: {(complete) in
                                
                                player.prepareToPlay()
                                //})
                        }
                    }
                }
            }
        }
        
        if mediaType.contains("image"){
            if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage{
                selectedImageFromPicker = editedImage
            }
            if let selectedImage = selectedImageFromPicker{
                postImageView.image = selectedImage
                self.mediaView.addSubview(postImageView)
                
                locationManager.getCurrentLocationDictionary(){
                    (data: [String: String]) in data //Retrieve data from our getCurrentLocationDictionary() completion handler.
                    
                    //Map the location object with data retrieved from the completion handler of our getCurrentLocationDictionary() method.
                    self.location.setValuesForKeys(data)
                    
                    if (self.location.city != nil || self.location.city != "") && (self.location.state != nil || self.location.state != ""){
                        self.setViewsForAfterPictureTaken()
                        picker.view.fadeOut()
                        self.filtersCollectionView.isUserInteractionEnabled = true
                    }
                }
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }

    func createPost(){

        loadingView.startLoading()
   
        let postID = UUID().uuidString
        var storageRef = FIRStorageReference()
        var uploadData = Data()
        
        if selectedMovieURL != nil{
            storageRef = FIRStorage.storage().reference().child("post_media").child("\(postID).mov")
            if let postURL = selectedMovieURL{
                uploadData = try! Data(contentsOf: postURL)
            }
        }else{
            storageRef = FIRStorage.storage().reference().child("post_media").child("\(postID).png")
            if let postImage = postImageView.image{
                uploadData = UIImageJPEGRepresentation(postImage, 0.75)!
            }
        }
    
        storageRef.put(uploadData, metadata: nil, completion: {(metadata, error) in
            
            if error != nil{
                print(error?.localizedDescription)
                self.loadingView.stopLoading()
                return
            }
            
            guard let firebaseUserID = FIRAuth.auth()?.currentUser!.uid, let lat = self.location.latitude, let long = self.location.longitude, let cityFromLocation = self.location.city, let stateFromLocation = self.location.state, let postComment = self.postCommentTextField.text else{
                self.loadingView.stopLoading()
                return
            }
            
            let userID = firebaseUserID
            let timeStamp: NSNumber = NSNumber(value: NSDate().timeIntervalSince1970)
            let latitude = Double(lat)
            let longitude = Double(long)
            let city = cityFromLocation
            let state = stateFromLocation
            let category = self.postType
            let comment = postComment
            let upvote = 0
            let downvote = 0
            let viewCount = 0
            
            if let postImageURL = metadata?.downloadURL()?.absoluteString{
                
                if let subAddress = self.location.subAddress, let address = self.location.address{

                    if category != ""{
                        let values: [String: AnyObject] = ["postID": postID as AnyObject, "userID": userID as AnyObject, "timeStamp": timeStamp, "latitude": latitude! as AnyObject, "longitude": longitude! as AnyObject, "subAddress": subAddress as AnyObject, "address": address as AnyObject, "city": city as AnyObject, "state": state as AnyObject, "category": category as AnyObject, "comment": comment as AnyObject, "upvote": upvote as AnyObject, "downvote": downvote as AnyObject, "views": viewCount as AnyObject, "postMediaURL": postImageURL as AnyObject]
                    
                        self.uploadPost(values)
                    }else{
                        self.loadingView.stopLoading()
                        self.showAlert("Hold up!", message: "You need to select a category before posting!")
                    }
                }
            }
        })
    }
    
    func uploadPost(_ values: [String: AnyObject]){
        
        guard let postID = values["postID"] as? String else{
            self.loadingView.stopLoading()
            print("Post ID was nil?")
            return
        }
        
        let postsReference = FIRDatabase.database().reference().child("posts/\(postID)")
        postsReference.updateChildValues(values, withCompletionBlock: {(error, ref) in
            if error != nil{
                print(error?.localizedDescription)
                self.loadingView.stopLoading()
                return
            }else{
                self.loadingView.stopLoading()
                self.moviePlayerController.stop()
                self.dismissViewController()
            }
        })
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
    
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        if motion == .motionShake{
            if postImageView.image != defaultCameraImage{
                openCamera()
                postImageView.fadeOut()
            }
        }
    }
    
    //MARK: - Collection View Delegate & DataSource
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell{
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! ImageFilterCell
        let filter = filters[(indexPath as NSIndexPath).row]
        DispatchQueue.main.async(execute: {
            cell.imageView.image = self.applyFilterToImage(image: self.postImageView.image!, filter: filter)
        })
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let filter = filters[(indexPath as NSIndexPath).row]
        postImageView.image = applyFilterToImage(image: postImageView.image!, filter: filter)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filters.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 50, height: 50)
    }
    
    //Line Spacing
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 5
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
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
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
}
