//
//  NotVerifiedViewController.swift
//  FileVault
//
//  Created by Jeffery Calhoun on 6/21/16.
//  Copyright © 2016 Jeffery Calhoun. All rights reserved.
//

import UIKit
import Firebase
//TODO:
//complete fixes in comments
class NotVerifiedViewController: UIViewController {

    @IBAction func resendVerifcation(sender: AnyObject) {
        print("in resend function")
        FIRAuth.auth()?.currentUser?.sendEmailVerificationWithCompletion({ (error) in
            print("resending verificaion email")
            if error != nil{
                print(error)
                print("Couldnt send verification email")
                //USE A LABEL TO LET USR KNOW VERIFICATION NOT SENT
                //ALSO USE A SPINNER TO SHOW USER APP IS PROCESSING
            }
            else{
                //USE A LABEL TO LET USR KNOW VERIFICATION SENT
                //ALSO USE A SPINNER TO SHOW USER APP IS PROCESSING
                print("verification sent")
            }
        })
        print("leaving resend function")
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
