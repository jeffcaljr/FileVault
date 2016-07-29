//
//  ResetPasswordViewController.swift
//  FileVault
//
//  Created by Jeffery Calhoun on 6/21/16.
//  Copyright © 2016 Jeffery Calhoun. All rights reserved.
//

import UIKit
import Firebase


//TODO: - Use prepareForSegue to properly set up segue
//TODO: - Move Firebase code to a service

class ResetPasswordViewController: UIViewController, UITextFieldDelegate {
    
    //MARK: Properties
    
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var loadingSpinner: UIActivityIndicatorView!
    @IBOutlet weak var emailLabel: UITextField!
    @IBOutlet weak var resetPasswordButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    //MARK: Actions
    
    //Monitor the editing of the email field to check that it is constantly valid
    //If it is not, disable the password reset button
    @IBAction func editedEmail(sender: AnyObject) {
        if let email = self.emailLabel.text{
            
            //validate email (aBc123@xyz.???)
            
            let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
            let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
            let result = emailTest.evaluateWithObject(email)
            if result == false{
                //email is invalid
                self.resetPasswordButton.enabled = false
            }
            else{
                //Email is valid
                self.resetPasswordButton.enabled = true
            }
        }

    }
    
    //When user selects a text field, clear any error label being displayed
    @IBAction func editingBegan(sender: AnyObject) {
        self.errorLabel.hidden = true
    }
    
    @IBAction func resetPassword(sender: AnyObject) {
        
        self.resetPasswordButton.enabled = false
        self.cancelButton.enabled = false
        self.emailLabel.enabled = false
        
        FIRAuth.auth()?.sendPasswordResetWithEmail(self.emailLabel.text!, completion: { (error) in
            if error != nil{
                
                if error!.code == 17011{ //"email not registered" error code
                    self.errorLabel.text! = "Email not registered"
                    self.errorLabel.hidden = false
                    
                    self.resetPasswordButton.enabled = true
                    self.cancelButton.enabled = true
                    self.emailLabel.enabled = true
                }
                else{
                    //some other error occured
                    print("error reseting email")
                    self.errorLabel.text! = "Email not registered"
                    self.errorLabel.hidden = false
                    self.resetPasswordButton.enabled = true
                    self.cancelButton.enabled = true
                    self.emailLabel.enabled = true
                }
            }
            else{
                //email reset sent
                self.errorLabel.text! = "Check your email to reset password"
                self.errorLabel.hidden = false
                print("Check your email to reset password")
                self.resetPasswordButton.enabled = true
                self.cancelButton.enabled = true
                self.emailLabel.enabled = true
                self.performSegueWithIdentifier("BackToRootSegue", sender: self)
            }
        })
        
    }
    
    //MARK: ViewController Delegate
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.emailLabel.delegate = self

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: Keyboard Delegate
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.emailLabel.resignFirstResponder()
        if self.resetPasswordButton.enabled == true{
            resetPassword(self)
        }
        return true
    }
}
