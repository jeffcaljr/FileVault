//
//  LoginScreenViewController.swift
//  FileVault
//
//  Created by Jeffery Calhoun on 6/19/16.
//  Copyright © 2016 Jeffery Calhoun. All rights reserved.
//

import UIKit
import Firebase


//TODO: - Reuse verify email and empty password methods from SignUpViewController

class LoginScreenViewController: UIViewController, UITextFieldDelegate {
    
    //MARK: Properties
    @IBOutlet weak var emailLabel: UITextField!
    @IBOutlet weak var passwordLabel: UITextField!
    @IBOutlet weak var loadingSpinner: UIActivityIndicatorView!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var signInButton: UIButton!
    
    //MARK: Actions
    
    //When email or password is edited, validate inputs to determine if sign in button should be enabled
    @IBAction func fieldsEdited(sender: AnyObject) {
        if let email = emailLabel.text, password = passwordLabel.text{
            
            //validate email
            let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
            let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
            let result = emailTest.evaluateWithObject(email)
            if result == false{
                //email is invalid
                signInButton.enabled = false
            }
            else{
                //Email is valid
                
                let passwordRegEx = "^\\s*$"
                let passwordTest = NSPredicate(format: "SELF MATCHES %@", passwordRegEx)
                let emptyPasswordResult = passwordTest.evaluateWithObject(password)
                
                if emptyPasswordResult == true{
                    //password is invalid
                    signInButton.enabled = false
                }
                else{
                    //Password is valid
                    signInButton.enabled = true
                }
            }
        }
        
    }
    
    //Remove any error label when user touches an input field
    @IBAction func beginEditting(sender: AnyObject) {
        self.errorLabel.hidden = true
    }
    
    //user clicks sign-in button
    @IBAction func attemptSignIn(sender: AnyObject) {
        signIn()
    }
    
    
    //MARK: ViewController Delegate
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //make sure no user is signed in
        //try! FIRAuth.auth()?.signOut()
        
        //Initialize view properties
        self.errorLabel.hidden = true
        self.emailLabel.text! = ""
        self.errorLabel.text! = ""
        self.passwordLabel.text! = ""
        self.loadingSpinner.stopAnimating()
        
        
        self.emailLabel.delegate = self
        self.passwordLabel.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func shouldAutorotate() -> Bool {
        return false
    }

    //MARK Keyboard Delegate
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool{
        emailLabel.resignFirstResponder()
        passwordLabel.resignFirstResponder()
        if self.signInButton.enabled == true{
            signIn()
        }
        
        return true
    }
    
    //Used for seguing back to login screen
    @IBAction func cancelResetPassword(segue: UIStoryboardSegue){}
    
    
    func signIn(){
        print("signing in...")
        self.loadingSpinner.startAnimating()
        UIApplication.sharedApplication().beginIgnoringInteractionEvents()
        //try! FIRAuth.auth()?.signOut()
        print("trying now!!!")
//        if let email = self.emailLabel.text{
//            print(email)
//            if let password = self.passwordLabel.text{
//                print("password")
//            }
//            else{
//                print("no password in field!!!")
//            }
//        }
//        else{
//            print("no email in field!!!")
//        }
        
        FIRAuth.auth()?.signInWithEmail(self.emailLabel.text!, password: self.passwordLabel.text!, completion: { (user, error) in
            print("in here")
            if error != nil{
                //an error occured
                print("In signin function")
                if error?.code == 17011{
                    //user doesn't exist
                    print("user doesnt exist")
                    self.loadingSpinner.stopAnimating()
                    self.errorLabel.text! = "Email not registered"
                    self.errorLabel.hidden = false
                    UIApplication.sharedApplication().endIgnoringInteractionEvents()
                }
                else if error?.code == 17009{
                    //invalid password
                    print("invalid password")
                    self.loadingSpinner.stopAnimating()
                    self.errorLabel.text! = "Invalid password"
                    self.errorLabel.hidden = false
                    UIApplication.sharedApplication().endIgnoringInteractionEvents()
                }
                else{
                    //Some other error occured
                    print("other error")
                    self.errorLabel.text! = "Error logging in"
                    self.errorLabel.hidden = false                }
                    self.loadingSpinner.stopAnimating()
                    UIApplication.sharedApplication().endIgnoringInteractionEvents()
            }
            else{
                //login credentials valid
                //check for email verification
                print("login almost complete")
                if user!.emailVerified{
                    self.loadingSpinner.stopAnimating()
                    UIApplication.sharedApplication().endIgnoringInteractionEvents()
                    print("going to login segue")
                    self.performSegueWithIdentifier("LoginSegue", sender: self)
                }
                    
                else{
                    //email not verified. Send user to screen prompting email verification
                    try! FIRAuth.auth()?.signOut()
                    self.loadingSpinner.stopAnimating()
                    UIApplication.sharedApplication().endIgnoringInteractionEvents()
                    print("not verified")
                    self.performSegueWithIdentifier("PromptVerificationSegue", sender: self)
                }
            }
        })
    }

}
