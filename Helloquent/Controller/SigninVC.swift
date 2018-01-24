//
//  SigninVC.swift
//  Helloquent
//
//  Created by Morgan Trudeau on 2017-12-21.
//  Copyright © 2017 Morgan Trudeau. All rights reserved.
//

import Foundation
import UIKit
import FBSDKCoreKit
import FBSDKLoginKit
import FirebaseAuth

class SigninVC: UIViewController {
    
    @IBOutlet weak var m_emailTextField: UITextField!
    @IBOutlet weak var m_passwordTextField: UITextField!
    @IBOutlet weak var m_loginButton: UIButton!
    @IBOutlet weak var m_FBLoginButton: UIButton!
    
    let authProvider = AuthProvider()
    
    private let SIGN_IN_SEGUE: String = "sign_in_segue"
    
    let m_loadingOverlay = LoadingOverlay()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(SigninVC.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        m_loadingOverlay.modalPresentationStyle = .overFullScreen
        
        setUpUI()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        m_emailTextField.text = ""
        m_passwordTextField.text = ""
    }
    
    func setUpUI() {
        
        let roomTextImage = UIImage(named: "rooms_text")
        let roomTextImageView = UIImageView(image: roomTextImage)
        roomTextImageView.center.x = self.view.center.x
        roomTextImageView.center.y = self.view.frame.size.height*0.2
        self.view.addSubview(roomTextImageView)
        
        m_emailTextField.frame = CGRect(x: 0, y: 0, width: 275, height: 40)
        m_emailTextField.center.y = self.view.frame.size.height*0.4
        m_emailTextField.center.x = self.view.center.x
        
        m_passwordTextField.frame = CGRect(x: 0, y: 0, width: 275, height: 40)
        m_passwordTextField.center.y = self.view.frame.size.height*0.49
        m_passwordTextField.center.x = self.view.center.x
        
        m_loginButton.frame = CGRect(x: 0, y: 0, width: 275, height: 45)
        m_loginButton.layer.borderWidth = 2.0
        m_loginButton.layer.borderColor = UIColor.white.cgColor
        m_loginButton.layer.cornerRadius = 5
        m_loginButton.center.y = self.view.frame.size.height*0.58
        m_loginButton.center.x = self.view.center.x
        
        let orTextView = UITextView(frame: CGRect(x: 0, y: 0, width: 200, height: 35))
        orTextView.text = "OR"
        orTextView.backgroundColor = UIColor.clear
        orTextView.textColor = UIColor.white
        orTextView.textAlignment = NSTextAlignment.center
        orTextView.font = UIFont.boldSystemFont(ofSize: 18)
        orTextView.center.x = self.view.center.x
        orTextView.center.y = self.view.frame.size.height*0.655
        self.view.addSubview(orTextView)
        
        
        let FBImage = UIImage.init(named: "facebook_icon")
        let FBImageView = UIImageView.init(frame: CGRect(x: 10, y: 7, width: 30, height: 30))
        FBImageView.image = FBImage
        
        m_FBLoginButton.frame = CGRect(x: 0, y: 0, width: 275, height: 45)
        m_FBLoginButton.layer.borderWidth = 2.0
        m_FBLoginButton.layer.borderColor = UIColor.white.cgColor
        m_FBLoginButton.layer.cornerRadius = 5
        m_FBLoginButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: m_FBLoginButton.frame.width*0.15)
        m_FBLoginButton.center.y = self.view.frame.size.height*0.73
        m_FBLoginButton.center.x = self.view.center.x
        m_FBLoginButton.addSubview(FBImageView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if AuthProvider.Instance.isLoggedIn() {
            self.performSegue(withIdentifier: self.SIGN_IN_SEGUE, sender: nil)
        }
    }
    
    @IBAction func FBLoginButonPressed(_ sender: Any) {
        let login: FBSDKLoginManager = FBSDKLoginManager.init()
        login.logIn(withReadPermissions: ["public_profile"], from: self, handler: {(result, error) in
            
            if error != nil {
                self.alertUser(title: "Problem With Authentication", message: String(describing: error))
            } else if (result?.isCancelled)! {
                print("FBLogin Cancelled")
            } else {
                print("FBLogin Success")
                let credential = FacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
                AuthProvider.Instance.facebookAuth(credential: credential, loginHandler: {(message) in
                    
                    if message != nil {
                        self.alertUser(title: "Problem With Authentication", message: message!)
                    } else {
                        print("Login Successful")
                        self.performSegue(withIdentifier: self.SIGN_IN_SEGUE, sender: nil)
                    }
                })
            }
        })
    }
    
    @IBAction func login(_ sender: Any) {
        
        if m_emailTextField.text != "" && m_passwordTextField.text != "" {
            
            // Present LoadingOverlay as a modal
            present(m_loadingOverlay, animated: false, completion: nil)
            
            AuthProvider.Instance.login(email: m_emailTextField.text!, password: m_passwordTextField.text!, loginHandler: {(message) in
                
                if message != nil {
                    self.dismiss(animated: false, completion: {() in
                        self.alertUser(title: "Problem With Authentication", message: message!)
                    })
                } else {
                    print("Login Successful")
                    self.dismiss(animated: false, completion: {() in
                        self.performSegue(withIdentifier: self.SIGN_IN_SEGUE, sender: nil)
                    })
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
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
}
