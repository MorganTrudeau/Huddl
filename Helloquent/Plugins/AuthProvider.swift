//
//  AuthProvider.swift
//  Helloquent
//
//  Created by Morgan Trudeau on 2017-12-22.
//  Copyright © 2017 Morgan Trudeau. All rights reserved.
//

import Foundation
import FirebaseAuth
import FirebaseMessaging
import FirebaseDatabase
import FBSDKLoginKit
import SDWebImage

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
    
    var users: [String:User]?
    
    func login(email: String, password: String, loginHandler: LoginHandler?) {
        Auth.auth().signIn(withEmail: email, password: password, completion: {(user, error) in
            
            if error != nil {
                self.handleErrors(error: error! as NSError, loginHandler: loginHandler)
            } else {
                loginHandler?(nil)
            }
        })
    }
    
    func facebookAuth(credential: AuthCredential, loginHandler: LoginHandler?) {
        Auth.auth().signIn(with: credential, completion: {(user, error) in
            
            if error != nil {
                self.handleErrors(error: error! as NSError, loginHandler: loginHandler)
            } else {
                // Check Firebase for user exists, if not save in DB
                DBProvider.Instance.usersRef.observeSingleEvent(of: DataEventType.value, with: {(snapshot: DataSnapshot) in
                    if !snapshot.hasChild(user!.uid) {
                        // Store new user in Firebase
                        let userColor = ColorHandler.Instance.userColor()
                        DBProvider.Instance.createUser(withID: user!.uid, email: "", displayName: (user!.displayName)!, password: "", color: userColor)
                    }
                    loginHandler?(nil)
                })
            }
        })
    }
    
    // Set FCM notification token for current user
    func setNotificationToken() {
        if let fcmToken = Messaging.messaging().fcmToken {
            DBProvider.Instance.usersRef.child(AuthProvider.Instance.userID()).observeSingleEvent(of: .value, with: {(snapshot) in
                if let user = snapshot.value as? NSDictionary { 
                    if let token = user[Constants.TOKEN] as? String {
                        if token != fcmToken {
                            user.setValue(fcmToken, forKey: Constants.TOKEN)
                            DBProvider.Instance.usersRef.child(AuthProvider.Instance.userID()).setValue(user)
                        }
                    } else {
                        user.setValue(fcmToken, forKey: Constants.TOKEN)
                        DBProvider.Instance.usersRef.child(AuthProvider.Instance.userID()).setValue(user)
                    }
                }
            })
        }
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
    
    func signUp(email: String, displayName: String, password: String, loginHandler: LoginHandler?) {
        Auth.auth().createUser(withEmail: email, password: password, completion: {(user, error) in
            
            if error != nil {
                self.handleErrors(error: error! as NSError, loginHandler: loginHandler)
            } else if user?.uid != nil {
                //Store in db
                let userColor = ColorHandler.Instance.userColor()
                DBProvider.Instance.createUser(withID: user!.uid, email: email, displayName: displayName, password: password, color: userColor)
                
                self.setDisplayName(displayName: displayName)
                
                //Sign in user
                self.login(email: email, password: password, loginHandler: loginHandler)
            }
        })
    }
    
    func setDisplayName(displayName: String) {
        let currentUser = Auth.auth().currentUser
        let changeRequest = currentUser?.createProfileChangeRequest()
        changeRequest?.displayName = displayName
        changeRequest?.commitChanges(completion: {(error) in
            if error != nil {
                print("Error setting display name")
            } else {
                print("Display name set")
            }
        })
    }
    
    func logout() -> Bool {
        do {
            try Auth.auth().signOut()
            FBSDKLoginManager.init().logOut()
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

