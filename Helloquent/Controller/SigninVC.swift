//
//  SigninVC.swift
//  Helloquent
//
//  Created by Morgan Trudeau on 2017-12-21.
//  Copyright © 2017 Morgan Trudeau. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit

class SigninVC: UIViewController {
    
    private let CHATROOMS_SEGUE: String = "chat_rooms_segue"
    
    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var passwordTextField: UITextField!
    
    let authProvider = AuthProvider()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let loginButton = FBSDKLoginButton.init()
        loginButton.center = CGPoint.init(x: self.view.bounds.size.width / 2, y: self.view.frame.size.height / 2 + 150)
        view.addSubview(loginButton)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if AuthProvider.Instance.isLoggedIn() {
            self.performSegue(withIdentifier: self.CHATROOMS_SEGUE, sender: nil)
        }
    }
    
    @IBAction func login(_ sender: Any) {
        
        if emailTextField.text != "" && passwordTextField.text != "" {
            AuthProvider.Instance.login(email: emailTextField.text!, password: passwordTextField.text!, loginHandler: {(message) in
                
                if message != nil {
                    self.alertUser(title: "Problem With Authentication", message: message!)
                } else {
                    print("Login Successful")
                    self.performSegue(withIdentifier: self.CHATROOMS_SEGUE, sender: nil)
                }
            })
        } else {
            alertUser(title: "Email and Password Required", message: "Please enter an email and password")
        }
    }
    
    
    @IBAction func signUp(_ sender: Any) {
        
        if emailTextField.text != "" && passwordTextField.text != "" {
            
            AuthProvider.Instance.signUp(email: emailTextField.text!, password: passwordTextField.text!, loginHandler: {(message) in
                
                if message != nil {
                    self.alertUser(title: "Problem Creating User", message: message!)
                } else {
                    print("Successfully created user")
                    self.performSegue(withIdentifier: self.CHATROOMS_SEGUE, sender: nil)
                }
            })
        } else {
            alertUser(title: "Email and Password Required", message: "Please enter an email and password")
        }
    }
    
    func alertUser(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    

}
