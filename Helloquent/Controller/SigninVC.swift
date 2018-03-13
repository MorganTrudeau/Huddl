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

class SigninVC: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var m_emailTextField: UITextField!
    @IBOutlet weak var m_passwordTextField: UITextField!
    @IBOutlet weak var m_loginButton: UIButton!
    @IBOutlet weak var m_FBLoginButton: UIButton!
    
    let authProvider = AuthProvider()
    let m_loadingOverlay = LoadingOverlay()
    
    private let SIGN_IN_SEGUE: String = "sign_in_segue"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(SigninVC.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        m_emailTextField.delegate = self
        m_passwordTextField.delegate = self
        
        m_loadingOverlay.modalPresentationStyle = .overFullScreen
        
        setUpUI()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        m_emailTextField.text = ""
        m_passwordTextField.text = ""
    }
    
    func setUpUI() {
        
        let roomTextImage = UIImage(named: "huddl")
        let roomTextImageView = UIImageView(image: roomTextImage)
        roomTextImageView.center.x = self.view.center.x
        roomTextImageView.center.y = self.view.center.x - 30
        self.view.addSubview(roomTextImageView)
        
        m_emailTextField.tag = 1
        m_passwordTextField.tag = 2

        m_loginButton.layer.borderWidth = 2.0
        m_loginButton.layer.borderColor = UIColor.white.cgColor
        m_loginButton.layer.cornerRadius = 5
        
        let FBImage = UIImage.init(named: "facebook_icon")
        let FBImageView = UIImageView.init(frame: CGRect(x: 5, y: 5, width: 35, height: 35))
        FBImageView.image = FBImage

        m_FBLoginButton.layer.borderWidth = 2.0
        m_FBLoginButton.layer.borderColor = UIColor.white.cgColor
        m_FBLoginButton.layer.cornerRadius = 5
        m_FBLoginButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 15)
        m_FBLoginButton.addSubview(FBImageView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if AuthProvider.Instance.isLoggedIn() {
            self.performSegue(withIdentifier: self.SIGN_IN_SEGUE, sender: nil)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        let nextTag = textField.tag + 1
        let nextResponder = textField.superview?.viewWithTag(nextTag) as UIResponder!
        if nextResponder != nil {
            nextResponder?.becomeFirstResponder()
        } else {
            m_loginButton.sendActions(for: .touchUpInside)
        }
        return false
    }
    
    @IBAction func FBLoginButonPressed(_ sender: Any) {
        self.present(self.m_loadingOverlay, animated: false, completion: nil)
        let login: FBSDKLoginManager = FBSDKLoginManager.init()
        login.logIn(withReadPermissions: ["public_profile"], from: self, handler: {(result, error) in
            
            if error != nil {
                self.dismiss(animated: false, completion: {() in
                    self.alertUser(title: "Problem With Authentication", message: String(describing: error))
                })
            } else if (result?.isCancelled)! {
                self.dismiss(animated: false, completion: nil)
                print("FBLogin Cancelled")
            } else {
                print("FBLogin Success")
                let credential = FacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
                AuthProvider.Instance.facebookAuth(credential: credential, loginHandler: {(message) in
                    
                    if message != nil {
                        self.dismiss(animated: false, completion: {() in
                            self.alertUser(title: "Problem With Authentication", message: message!)
                        })
                    } else {
                        self.dismiss(animated: false, completion: {() in
                            print("Login Successful")
                            self.performSegue(withIdentifier: self.SIGN_IN_SEGUE, sender: nil)
                        })
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
