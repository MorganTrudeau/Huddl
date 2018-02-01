//
//  SignUpVC.swift
//  Helloquent
//
//  Created by Morgan Trudeau on 2018-01-22.
//  Copyright © 2018 Morgan Trudeau. All rights reserved.
//

import UIKit

class SignUpVC: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var m_displayNameTextField: UITextField!
    @IBOutlet weak var m_emailTextField: UITextField!
    @IBOutlet weak var m_passwordTextField: UITextField!
    @IBOutlet weak var m_confirmPassTextField: UITextField!
    @IBOutlet weak var m_signUpButton: UIButton!
    @IBOutlet weak var m_cancelButton: UIButton!
    
    let m_loadingOverlay = LoadingOverlay()
    
    private let SIGN_UP_SEGUE: String = "sign_up_segue"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(SigninVC.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        m_displayNameTextField.delegate = self
        m_emailTextField.delegate = self
        m_passwordTextField.delegate = self
        m_confirmPassTextField.delegate = self
        
        m_loadingOverlay.modalPresentationStyle = .overFullScreen
        
        setUpUI()
    }
    
    func setUpUI() {
        
        let roomTextImage = UIImage(named: "rooms_text")
        let roomTextImageView = UIImageView(image: roomTextImage)
        roomTextImageView.center.x = self.view.center.x
        roomTextImageView.center.y = self.view.frame.size.height*0.2
        self.view.addSubview(roomTextImageView)
        
        m_displayNameTextField.frame = CGRect(x: 0, y: 0, width: 275, height: 40)
        m_displayNameTextField.center.y = self.view.frame.size.height*0.35
        m_displayNameTextField.center.x = self.view.center.x
        m_displayNameTextField.tag = 1
        
        m_emailTextField.frame = CGRect(x: 0, y: 0, width: 275, height: 40)
        m_emailTextField.center.y = self.view.frame.size.height*0.44
        m_emailTextField.center.x = self.view.center.x
        m_emailTextField.tag = 2
        
        m_passwordTextField.frame = CGRect(x: 0, y: 0, width: 275, height: 40)
        m_passwordTextField.center.y = self.view.frame.size.height*0.53
        m_passwordTextField.center.x = self.view.center.x
        m_passwordTextField.tag = 3
        
        m_confirmPassTextField.frame = CGRect(x: 0, y: 0, width: 275, height: 40)
        m_confirmPassTextField.center.y = self.view.frame.size.height*0.62
        m_confirmPassTextField.center.x = self.view.center.x
        m_confirmPassTextField.tag = 4
        
        m_signUpButton.frame = CGRect(x: 0, y: 0, width: 275, height: 45)
        m_signUpButton.center.y = self.view.frame.size.height*0.71
        m_signUpButton.center.x = self.view.center.x
        m_signUpButton.layer.borderWidth = 2
        m_signUpButton.layer.borderColor = UIColor.white.cgColor
        m_signUpButton.layer.cornerRadius = 5
        
        m_cancelButton.frame = CGRect(x: 0, y: 0, width: 275, height: 45)
        m_cancelButton.center.y = self.view.frame.height*0.80
        m_cancelButton.center.x = self.view.center.x
        m_cancelButton.layer.borderWidth = 2
        m_cancelButton.layer.borderColor = UIColor.white.cgColor
        m_cancelButton.layer.cornerRadius = 5
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        let nextTag = textField.tag + 1
        let nextResponder = textField.superview?.viewWithTag(nextTag) as UIResponder!
        if nextResponder != nil {
            nextResponder?.becomeFirstResponder()
        } else {
            m_signUpButton.sendActions(for: .touchUpInside)
        }
        return false
    }

    @IBAction func signUp(_ sender: Any) {
        if m_emailTextField.text != "" && m_displayNameTextField.text != "" && m_passwordTextField.text != "" {
            if m_passwordTextField.text! == m_confirmPassTextField.text! {
                present(m_loadingOverlay, animated: false, completion: nil)
            
                AuthProvider.Instance.signUp(email: m_emailTextField.text!, displayName: m_displayNameTextField.text!, password: m_passwordTextField.text!, loginHandler: {(message) in
                
                    if message != nil {
                        self.dismiss(animated: false, completion: {() in
                            self.alertUser(title: "Problem Creating User", message: message!)
                        })
                    } else {
                        print("Successfully created user")
                        print("Login Successful")
                        self.dismiss(animated: false, completion: {() in
                            self.dismiss(animated: true, completion: {() in
                                self.performSegue(withIdentifier: self.SIGN_UP_SEGUE, sender: nil)
                            })
                        })
                    }
                })
            } else {
                self.alertUser(title: "Password Error", message: "Passwords do not match")
            }
        } else {
            alertUser(title: "Sign up Incomplete", message: "Please fill out all text fields")
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
