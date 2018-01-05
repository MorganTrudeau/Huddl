//
//  AuthProvider.swift
//  Helloquent
//
//  Created by Morgan Trudeau on 2017-12-22.
//  Copyright © 2017 Morgan Trudeau. All rights reserved.
//

import Foundation
import FirebaseAuth

typealias LoginHandler = (_ msg: String?) -> Void

struct LoginErrorCode {
    static let INVALID_EMAIL = "Invalid email"
    static let WRONG_PASSWORD = "Invalid password"
    static let USER_NOT_FOUND = "User not found"
    static let EMAIL_IN_USE = "Email already in use"
    static let WEAK_PASSWORD = "Password should be at least 6 characters long"
    static let PROBLEM_CONNECTING = "Could not connect. Try again later."
}

class AuthProvider {
    private static let _instance = AuthProvider()
    
    static var Instance: AuthProvider {
        return _instance
    }
    
    func login(email: String, password: String, loginHandler: LoginHandler?) {
        Auth.auth().signIn(withEmail: email, password: password, completion: {(user, error) in
            
            if error != nil {
                self.handleErrors(error: error! as NSError, loginHandler: loginHandler)
            } else {
                loginHandler?(nil)
            }
        })
    }
    
    func isLoggedIn() -> Bool {
        if Auth.auth().currentUser != nil {
            return true
        }
        return false
    }
    
    func userID() -> String {
        return Auth.auth().currentUser!.uid
    }
    
    func currentUserName() -> String {
        return (Auth.auth().currentUser?.email)!
    }
    
    func signUp(email: String, password: String, loginHandler: LoginHandler?) {
        Auth.auth().createUser(withEmail: email, password: password, completion: {(user, error) in
            
            if error != nil {
                self.handleErrors(error: error! as NSError, loginHandler: loginHandler)
            } else if user?.uid != nil {
                //Store in db
                DBProvider.Instance.saveUser(withID: user!.uid, email: email, password: password)
                
                //Sign in user
                self.login(email: email, password: password, loginHandler: loginHandler)
                    
                loginHandler?(nil)
            }
        })
    }
    
    func logout() -> Bool {
        do {
            try Auth.auth().signOut()
            return true
        } catch {
            return false
        }
    }
    
    private func handleErrors(error: NSError, loginHandler: LoginHandler?) {
        
        if let errorCode = AuthErrorCode(rawValue: error.code) {
            switch errorCode {
            case .wrongPassword:
                loginHandler?(LoginErrorCode.WRONG_PASSWORD)
                break
                
            case .invalidEmail:
                loginHandler?(LoginErrorCode.INVALID_EMAIL)
                break
                
            case .userNotFound:
                loginHandler?(LoginErrorCode.USER_NOT_FOUND)
                break
            
            case .emailAlreadyInUse:
                loginHandler?(LoginErrorCode.EMAIL_IN_USE)
                break
            
            case .weakPassword:
                loginHandler?(LoginErrorCode.WEAK_PASSWORD)
                break
                
            default:
                loginHandler?(error.localizedDescription)
                break
            }
        }
    }
    
    
    
}

