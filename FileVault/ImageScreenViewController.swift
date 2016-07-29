//
//  ImageScreenViewController.swift
//  FileVault
//
//  Created by Jeffery Calhoun on 6/20/16.
//  Copyright © 2016 Jeffery Calhoun. All rights reserved.
//

import UIKit

//TODO:
//Allow user to go back with back button, even if an image is currently loading.
class ImageScreenViewController: UIViewController {
    
    var file = StoredFile()

    //MARK: Properties
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var loadingSpinner: UIActivityIndicatorView!
    @IBOutlet weak var navigationBar: UINavigationBar!
    
    //MARK: ViewController Delegate
    override func viewDidLoad() {
        super.viewDidLoad()
        loadingSpinner.startAnimating()
    }
    
    override func viewDidAppear(animated: Bool) {
        let URL = NSURL(string: file.downloadURL)!
        let imageData = NSData(contentsOfURL: URL)!
        loadingSpinner.stopAnimating()
        imageView.image = UIImage(data: imageData)
        navigationBar.topItem!.title! = file.filename
    }
    
    
}
