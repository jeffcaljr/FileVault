//
//  FileListViewController.swift
//  FileVault
//
//  Created by Jeffery Calhoun on 6/19/16.
//  Copyright © 2016 Jeffery Calhoun. All rights reserved.
//

import UIKit
import Firebase
import SwiftyJSON

class FileListViewController: UIViewController, UITableViewDelegate {
    
    let currentUser = FIRAuth.auth()?.currentUser
    let rootRef = FIRDatabase.database().reference()
    var userFilesReference: FIRDatabaseReference = FIRDatabaseReference()
    var files = [StoredFile]()
    var gestureRecognizer = UILongPressGestureRecognizer()
    var sendingFile = StoredFile()
    var alertMenu = UIAlertController()
    
    //MARK: Properties
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var navigationBar: UINavigationBar!
    
    //MARK: Actions
    
    //MARK: ViewController Delegate
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //FIXME:
        //THIS LINE IS CAUSING CRASHES BECAUSE ITS TRYING TO UNWRAP currentUser that doesnt exist
        //LOOK AT WHAT CODE IS SEGUING INTO THIS VIEW AND CONSIDER REVISING
        //If password reset email is sent but not used, firebase tries to log them in but the auth is faulty
        //THE ERROR APPEARS TO BE THAT CURRENTUSER NO LONGER EXIST HERE
        //POSSIBLY FIREBASE TAKING TOO LONG TO AUTHENTICATE BEFORE SEGUE? NOT LIKELY
        self.userFilesReference = rootRef.child("storedfiles").child("\(currentUser!.uid)")
        
        getFilesFromDatabase()
        //FIX:
        //self.gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(FileListViewController.presentCellMenu(_:)))
        //self.tableView.addGestureRecognizer(gestureRecognizer)
        self.gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(FileListViewController.presentCellMenu(_:)))
        self.view.addGestureRecognizer(gestureRecognizer)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Prevent this view from rotating
    override func shouldAutorotate() -> Bool {
        return false
    }
    
    //MARK: TableView Delegate
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return files.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell{
        let cell = self.tableView.dequeueReusableCellWithIdentifier("FileCell") as! FileTableViewCell
        cell.filename.text! = self.files[indexPath.row].filename
        cell.uploadDate.text! = self.files[indexPath.row].dateCreated
        
        //load thumbnail
        if let thumbnailData = NSUserDefaults.standardUserDefaults().objectForKey(self.files[indexPath.row].id){
            if let data = thumbnailData as? NSData{
                cell.thumbnail.image = UIImage(data: data)
            }
            else{
                print("Couldnt convert stored data to NSData")
            }
        }

        
        //FIX:
//        self.gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(FileListViewController.presentCellMenu(_:)))
//        cell.addGestureRecognizer(self.gestureRecognizer)
        return cell
    }
    
    //Transition to display screen when a cell is clicked
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let destination = storyboard.instantiateViewControllerWithIdentifier("ImageDisplayScreen") as! ImageScreenViewController
        destination.file = files[indexPath.row]
        self.presentViewController(destination, animated: false, completion: nil)
    }
    
    
    func getFilesFromDatabase(){
        let refHandle = self.userFilesReference.observeEventType(FIRDataEventType.Value, withBlock: { (snapshot) in
            //Clear datasource in memory to allow for proper table reload
            self.files.removeAll()
            //Parse JSON from DB
            if let postDict = snapshot.value as? NSDictionary{
                let json = JSON(postDict)
                for folder in json{
                    //folder.0 is the folder name, folder.1 is the folder content in JSON
                    for file in folder.1{
                        //file.0 is the randomly generated fileID, file.1 is a dictionary of user properties
                        let fileData = file.1
                        //Create a new StoredFile for each file retrieved from the database
                        let newFile = StoredFile(id: fileData["id"].rawString()!, filename: fileData["filename"].rawString()!, dateCreated: fileData["date_uploaded"].rawString()!, downloadURL: fileData["download_url"].rawString()!, filetype: fileData["filetype"].rawString()!)
                        
                        self.files.append(newFile)
                    }
                }
            }
            else{
                //an error occured, DB is most likely empty
                print("Empty database?")
            }
            
            self.tableView.reloadData()
        })
    }
    
    //Prevent a popup menu when a cell is longpressed that displays editing options
    //FIX: Longpress registers too many times, causes multiple files to be deleted and app to crash
    func presentCellMenu(gesture: UIGestureRecognizer){
        if gesture.state == UIGestureRecognizerState.Began{
            print("long pressed cell-2")
            //Determine which cell has been selected
            let touchPoint = gesture.locationInView(self.view)
            if let indexPath = tableView.indexPathForRowAtPoint(touchPoint){
                //title will be displayed in popup menu
                let menuTitle = files[indexPath.row].filename //should be file title
                
                //Get ID of selected file to allow for reference in storage and DB
                let id = files[indexPath.row].id
                
                createAlertMenu(id, menuTitle: menuTitle, indexPath: indexPath)
                
            }
           
        }
    }
    
    //Creates alert menu for long-pressed cells
    //TODO: Consider deleteing from local memory/tableview first so that the UI doesn't freeze for too long
    
    func createAlertMenu(id: String, menuTitle: String, indexPath: NSIndexPath?){
        self.alertMenu = UIAlertController(title: menuTitle, message: nil, preferredStyle: .ActionSheet)
        
        //Add Rename option?
        
        //Add Delete option
        self.alertMenu.addAction(UIAlertAction(title: "Delete", style: .Default, handler: { (action) in
            //delete from storage
            UIApplication.sharedApplication().beginIgnoringInteractionEvents()
            
            let fileStorageRef = FIRStorage.storage().reference().child("\(self.currentUser!.uid)").child("images").child("\(id)")
            
            fileStorageRef.deleteWithCompletion({ (error) in
                if error != nil{
                    print("Error deleting file '\(id)' from storage")
                    UIApplication.sharedApplication().endIgnoringInteractionEvents()
                }
                else{
                    //deleted from storage
                    //delete from db
                    
                    //reference to file in DB
                    let fileDBRef = self.rootRef.child("storedfiles").child("\(self.currentUser!.uid)").child("images").child(id)
                    
                    fileDBRef.removeValueWithCompletionBlock({ (error, reference) in
                        if error != nil{
                            print("Error deleting file '\(id)' from database")
                            UIApplication.sharedApplication().endIgnoringInteractionEvents()
                        }
                        else{
                            //delete from memory/tableview
                            self.files.removeAtIndex(indexPath!.row)
                            UIApplication.sharedApplication().endIgnoringInteractionEvents()
                            self.tableView.reloadData()
                            
                            //delete from NSUSERDEFUALTS
                            if NSUserDefaults.standardUserDefaults().objectForKey(id) != nil{
                                NSUserDefaults.standardUserDefaults().removeObjectForKey(id)
                                print("removed from user defaults")
                            }
                        }
                    })
                }
            })
        }))
        
        
        self.alertMenu.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { (action) in
            //
        }))
        
        self.presentViewController(self.alertMenu, animated: true, completion: nil)
    }
    
    //Used to segue back to file list screen
    @IBAction func returnToMainScreen(segue: UIStoryboardSegue) {
        //
    }
    
}

