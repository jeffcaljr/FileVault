//
//  UploadFilesViewController.swift
//  FileVault
//
//  Created by Jeffery Calhoun on 6/19/16.
//  Copyright © 2016 Jeffery Calhoun. All rights reserved.
//

import UIKit
import Firebase

//TODO:
//Allow the user to cancel upload
//restrict filename length to 20 characters

class UploadFilesViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {
    
    let user = FIRAuth.auth()?.currentUser
    var imageFolderRef = FIRDatabaseReference()
    var imageDBRef = FIRDatabaseReference()
    var fileStorageRef = FIRStorageReference()
    let imagePicker = UIImagePickerController()
    var file = StoredFile(id: "", filename: "", dateCreated: "", downloadURL: "", filetype: "")
    var uploadTask = FIRStorageUploadTask()
    var pickedImage = UIImage()
    let dateFormat = NSDateFormatter.dateFormatFromTemplate("MMM d, yyyy", options: 0, locale: NSLocale.currentLocale())!
    let formatter = NSDateFormatter()
    
    //MARK: Properties
    
    @IBOutlet weak var uploadedImageView: UIImageView!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var uploadButton: UIButton!
    @IBOutlet weak var filenameLabel: UITextField! //RESTRICT TO 20 CHARACTERS!!!
    
    //MARK: Actions
    @IBAction func filenameEdited(sender: AnyObject) {
        if let filename = self.filenameLabel.text{
            //validate that filename contains some characters besides spaces
            let filenameRegEx = "^\\s*$" //FIX: Don't allow user to begin filename with spaces, only letters/numbers
            let filenameTest = NSPredicate(format: "SELF MATCHES %@", filenameRegEx)
            let emptyFilenameResult = filenameTest.evaluateWithObject(filename)
            if emptyFilenameResult == true{
                self.uploadButton.enabled = false
            }
            else{
                self.uploadButton.enabled = true
                self.file.filename = filename
            }
        }
    }
    
    //User has input desired filename and clicked upload
    @IBAction func confirmFilenameAndUpload(sender: AnyObject) {
        self.view.endEditing(true)
        startUpload(pickedImage)
    }
    
    //MARK: Custom Functions
    func resizeImage(image: UIImage, newWidth: CGFloat) -> UIImage {
        
        let scale = newWidth / image.size.width
        let newHeight = image.size.height * scale
        UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight))
        image.drawInRect(CGRectMake(0, 0, newWidth, newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    
    //MARK: ViewController Delegate
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.filenameLabel.delegate = self
        self.imagePicker.delegate = self
        
        //Initialize properties
        self.progressBar.hidden = true
        self.filenameLabel.hidden = true
        self.uploadButton.hidden = true
        self.uploadButton.enabled = false
        
        //Create storage and DB references for Firebase
        imageFolderRef = FIRDatabase.database().reference().child("storedfiles").child("\(user!.uid)").child("images")
        fileStorageRef = FIRStorage.storage().reference().child("\(user!.uid)").child("images")
        

        
        // Present the image picker upon loading the view
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .PhotoLibrary
        presentViewController(imagePicker, animated: true, completion: nil)
        
        
    }

    
    //MARK: Methods to remove keyboard when user touches view
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        //self.filenameLabel.text! = ""
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool{
        self.filenameLabel.text! = ""
        filenameLabel.resignFirstResponder()
        if self.uploadButton.enabled{
            confirmFilenameAndUpload(self)
        }
        return true
    }

    
    //MARK: ImagePickerController Delegate
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            //display chosen image in view while it is being uploaded
            uploadedImageView.contentMode = .ScaleAspectFit
            uploadedImageView.image = pickedImage
            self.pickedImage = pickedImage
            

            self.filenameLabel.hidden = false
            self.uploadButton.hidden = false
        }
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    //User canceled image selection, go back to list screen
    func imagePickerControllerDidCancel(picker: UIImagePickerController){
        imagePicker.dismissViewControllerAnimated(true) {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let rootDestination = storyboard.instantiateViewControllerWithIdentifier("MainScreenController")
            self.presentViewController(rootDestination, animated: false, completion: nil)
        }
        
    }
    
    
    //Takes a selected image and uploads it into The Firebase database and storage
    func startUpload(pickedImage: UIImage){
        
        //convert selected image into data
        let data = UIImageJPEGRepresentation(pickedImage, 1.0)
        
        //create a metadata variable to set the content type/ other properties
        let jpegMetaData = FIRStorageMetadata()
        jpegMetaData.contentType = "image/jpeg"
        
        self.imageDBRef = imageFolderRef.childByAutoId() //DB reference to specific image
        
        
        let generatedFileName = "\(imageDBRef)".componentsSeparatedByString("/").last! //random id generated by DB
        //TODO: DO THE NEXT STEP A BETTER WAY!
        let imageRef = fileStorageRef.child("\(generatedFileName)") //reference to specific image in storage
        
        
        self.formatter.dateFormat = self.dateFormat
        let formattedDate = formatter.stringFromDate(NSDate())
        
        //create the StoredFile that will be uploaded
        self.file = StoredFile(id: generatedFileName, filename: self.file.filename, dateCreated: "\(formattedDate)", downloadURL: "", filetype: jpegMetaData.contentType!)
        
        //start file upload
        self.uploadTask = imageRef.putData(data!, metadata: jpegMetaData, completion: { (metadata, error) in
            if error != nil{
                //an error occured while trying to start file upload
                print(error)
            }
        })
        
        
        
        //MARK: - UploadTask Observers
        
        
        let uploadStartObserver = uploadTask.observeStatus(.Resume, handler: { (snapshot) in
            //uploading task
        })
        
        let uploadFinishedObserver = uploadTask.observeStatus(.Success, handler: { (snapshot) in
            //upload to DB
            //TODO: consider implementing as a transaction in the future
            let retrievedDownloadURL = snapshot.metadata!.downloadURL()!
            
            self.imageDBRef.child("filename").setValue(self.file.filename)
            self.imageDBRef.child("date_uploaded").setValue(self.file.dateCreated)
            self.imageDBRef.child("download_url").setValue("\(retrievedDownloadURL)")
            self.imageDBRef.child("filetype").setValue(self.file.filetype)
            let generatedID = "\(self.imageDBRef)".componentsSeparatedByString("/").last!
            self.imageDBRef.child("id").setValue(generatedID)
            
            //clear this view
            self.uploadedImageView.image = nil
            self.progressBar.progress = 0
            self.progressBar.hidden = true
            
            //Save thumbnail to storage for displaying in file list
            let thumbnail = self.resizeImage(self.pickedImage, newWidth: 61)
            let thumbnailData = NSData(data: UIImageJPEGRepresentation(thumbnail, 1.0)!)
            NSUserDefaults.standardUserDefaults().setObject(thumbnailData, forKey: self.file.id)
            
            print("Thumbnail saved")
            
            //go back to list view
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let destination =  storyboard.instantiateViewControllerWithIdentifier("MainScreenController")
            self.presentViewController(destination, animated: true, completion: nil)
        })
        
        let uploadProgressObserver = uploadTask.observeStatus(.Progress, handler: { (snapshot) in
            self.progressBar.hidden = false
            self.progressBar.progress = Float(snapshot.progress!.fractionCompleted)
        })
        
        let uploadStopObserver = uploadTask.observeStatus(.Failure, handler: { (snapshot) in
            //Upload falied/stopped
            //go back to list view
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let destination =  storyboard.instantiateViewControllerWithIdentifier("MainScreenController")
            self.presentViewController(destination, animated: true, completion: nil)
        })
    }
}