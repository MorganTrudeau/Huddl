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
        // Add tap and swipe Gestures to dismiss keyboard
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(SigninVC.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(SigninVC.dismissKeyboard))
        swipeDown.direction = .down
        self.view.addGestureRecognizer(swipeDown)
        
        m_displayNameTextField.delegate = self
        m_emailTextField.delegate = self
        m_passwordTextField.delegate = self
        m_confirmPassTextField.delegate = self
        
        // Used for loading indicator
        m_loadingOverlay.modalPresentationStyle = .overFullScreen
        
        setUpUI()
    }
    
    func setUpUI() {
        m_displayNameTextField.tag = 1
        m_emailTextField.tag = 2
        m_passwordTextField.tag = 3
        m_confirmPassTextField.tag = 4
        
        m_signUpButton.layer.borderWidth = 2
        m_signUpButton.layer.borderColor = UIColor.white.cgColor
        m_signUpButton.layer.cornerRadius = 5
        
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
        if m_emailTextField.text != "" && m_displayNameTextField.text != "" && m_passwordTextField.text != "" && (m_passwordTextField.text?.count)! > 5 {
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
