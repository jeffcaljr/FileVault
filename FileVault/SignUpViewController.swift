//
//  SignUpViewController.swift
//  FileVault
//
//  Created by Jeffery Calhoun on 6/19/16.
//  Copyright © 2016 Jeffery Calhoun. All rights reserved.
//

import UIKit
import Firebase


//TODO:
//FIX CRITICAL BUG IN CODE CAUSING CRASH AFTER LOGIN ON DEVICE
//Use different background image on root screen
//consider adding background image to other auth screens

//hide password text in sign-in and sign-up screens
class SignUpViewController: UIViewController, UITextFieldDelegate {
    
    
    //MARK: - Storyboard Outlets
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var confirmPasswordField: UITextField!
    @IBOutlet weak var loadingSpinner: UIActivityIndicatorView!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var signUpButton: UIButton!
    
    
    //MARK: Storyboard Actions
    //When text inputs are changed, validate email, then passwords
    @IBAction func fieldEdited(sender: AnyObject) {
        
        if let email = self.emailField.text, password = self.passwordField.text, confirmPassword = self.confirmPasswordField.text{
            
            if isValidEmail(email) == false{
                
                self.signUpButton.enabled = false
            }
                
            else{
            
                if isEmptyPassword(password) == true{
                    self.signUpButton.enabled = false
                }
                    
                else{
                    //did the user enter the password correctly twice?
                    
                    if password == confirmPassword{
                        self.signUpButton.enabled = true
                    }
                        
                    else{
                        self.signUpButton.enabled = false
                    }
                }
                
            }
        }
    }
    
    //Remove any error label when user taps an input field
    @IBAction func beginEditing(sender: AnyObject) {
        self.errorLabel.hidden = true
    }
    
    
    //Sign-Up Button clicked
    @IBAction func attemptSignUp(sender: AnyObject) {
        self.view.endEditing(true)
        self.signUp()
    }
    
    
    //MARK: - Methods
    
    //Check if the email field is in a valid format (x123@Y.z)
    func isValidEmail(email: String) -> Bool{
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        let result = emailTest.evaluateWithObject(email)
        return result
    }
    
    
    //Check if the password field is empty
    func isEmptyPassword(password: String) -> Bool{
        let passwordRegEx = "^\\s*$"
        let passwordTest = NSPredicate(format: "SELF MATCHES %@", passwordRegEx)
        let emptyPasswordResult = passwordTest.evaluateWithObject(password)
        
        return emptyPasswordResult
    }
    
    //Attempt Firebase signup and email verification, disabling user interaction during the request
    func signUp(){
        
        self.freezeUIandShowLoadingAnimation()
        
        FIRAuth.auth()?.createUserWithEmail(self.emailField.text!, password: self.passwordField.text!, completion: { (user, error) in
            if error != nil{
                
                if error?.code == 17007{
                    //user already exists
                    self.errorLabel.text! = "Email is already registered"
                    self.errorLabel.hidden = false
                    
                    self.unfreezeUIandHideLoadingAnimation()
                }
                    
                else{
                    print(error)
                    self.errorLabel.text! = "error creating user!"
                    self.errorLabel.hidden = false
                    
                    self.unfreezeUIandHideLoadingAnimation()
                }
            }
                
            else{ //user created
                user?.sendEmailVerificationWithCompletion({ (error) in
                    
                    if error != nil{
                        self.errorLabel.text! = "Error sending verification email"
                        
                        self.errorLabel.hidden = false
                        self.unfreezeUIandHideLoadingAnimation()
                    }
                        
                    else{
                        //User created and verification email sent. Send user to screen prompting verification
                        self.unfreezeUIandHideLoadingAnimation()
                        self.performSegueWithIdentifier("FirstVerificationSegue", sender: self)
                    }
                })
            }
        })
    }
    
    
    func freezeUIandShowLoadingAnimation(){
        self.loadingSpinner.startAnimating()
        UIApplication.sharedApplication().beginIgnoringInteractionEvents()
    }
    
    
    func unfreezeUIandHideLoadingAnimation(){
        UIApplication.sharedApplication().endIgnoringInteractionEvents()
        self.loadingSpinner.stopAnimating()
    }


    //MARK: - ViewController Delegate
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //TEST
        //Trying to stop bug that falsely authenticates user and crashes app on file list screen
        try! FIRAuth.auth()?.signOut()
        //END TEST
        
        //Initialize properties
        self.errorLabel.hidden = true
        
        self.emailField.delegate = self
        self.passwordField.delegate = self
        self.confirmPasswordField.delegate = self

    }
    

    //MARK: Methods to remove keyboard when user touches the view
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool{
        self.emailField.resignFirstResponder()
        self.passwordField.resignFirstResponder()
        self.confirmPasswordField.resignFirstResponder()
        if self.signUpButton.enabled == true{
            signUp()
        }
        return true
    }
    
    
    //MARK: Exit Segues
    //User logged out and is returned to the initial screen
    @IBAction func returnToSignUpScreen(segue: UIStoryboardSegue) {
        do{
            try FIRAuth.auth()?.signOut()
            print("Logged out of firebase")
        } catch{
            print("Error signing out of firebase")
        }
    }
    
}
