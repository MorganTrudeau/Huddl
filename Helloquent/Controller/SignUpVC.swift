//
//  SignUpVC.swift
//  Helloquent
//
//  Created by Morgan Trudeau on 2018-01-22.
//  Copyright © 2018 Morgan Trudeau. All rights reserved.
//

import UIKit

class SignUpVC: UIViewController {
    
    @IBOutlet weak var m_displayNameTextField: UITextField!
    
    @IBOutlet weak var m_emailTextField: UITextField!
    
    @IBOutlet weak var m_passwordTextField: UITextField!
    
    @IBOutlet weak var m_confirmPassTextField: UITextField!
    
    @IBOutlet weak var m_signUpButton: UIButton!
    
    @IBOutlet weak var m_cancelButton: UIButton!
    
    private let CHATROOMS_SEGUE: String = "rooms_segue"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(SigninVC.dismissKeyboard))
        view.addGestureRecognizer(tap)
        setUpUI()
    }
    
    func setUpUI() {
        let roomImage = UIImage(named: "big_room")
        let imageView = UIImageView(image: roomImage)
        imageView.center.x = self.view.center.x
        imageView.center.y = self.view.frame.size.height*0.2
        self.view.addSubview(imageView)
        
        m_displayNameTextField.center.y = self.view.frame.size.height*0.4
        
        m_emailTextField.center.y = self.view.frame.size.height*0.49
        
        m_passwordTextField.center.y = self.view.frame.size.height*0.58
        
        m_confirmPassTextField.center.y = self.view.frame.size.height*0.67
        
        m_signUpButton.center.y = self.view.frame.size.height*0.76
        m_signUpButton.layer.borderWidth = 2
        m_signUpButton.layer.borderColor = UIColor.white.cgColor
        m_signUpButton.layer.cornerRadius = 5
        
        m_cancelButton.center.y = self.view.frame.height*0.85
        m_cancelButton.layer.borderWidth = 2
        m_cancelButton.layer.borderColor = UIColor.white.cgColor
        m_cancelButton.layer.cornerRadius = 5
        
    }

    @IBAction func signUp(_ sender: Any) {
        if m_emailTextField.text != "" && m_passwordTextField.text != "" {
            
            AuthProvider.Instance.signUp(email: m_emailTextField.text!, password: m_passwordTextField.text!, loginHandler: {(message) in
                
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
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
}
