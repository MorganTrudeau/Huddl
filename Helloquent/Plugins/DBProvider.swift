//
//  DBProvider.swift
//  Helloquent
//
//  Created by Morgan Trudeau on 2017-12-22.
//  Copyright © 2017 Morgan Trudeau. All rights reserved.
//

import Foundation
import FirebaseDatabase
import FirebaseCore
import FirebaseStorage

protocol FetchData: class {
    
    func dataReceived(contacts: [Contact])
}

class DBProvider {
    private static let _instance = DBProvider()
    
    weak var delegate: FetchData?
    
    static var Instance: DBProvider {
        return _instance
    }
    
    var dbRef: DatabaseReference {
        return Database.database().reference()
    }
    
    var contactsRef: DatabaseReference {
        return dbRef.child(Constants.CONTACTS)
    }
    
    var messagesRef: DatabaseReference {
        return dbRef.child(Constants.MESSAGES)
    }
    
    var mediaMessagesRef: DatabaseReference {
        return dbRef.child(Constants.MEDIA_MESSAGES)
    }
    
    var storageRef: StorageReference {
        return Storage.storage().reference(forURL: "gs://helloquent-a4460.appspot.com")
    }
    
    var imageStorageRef: StorageReference {
        return storageRef.child(Constants.IMAGE_STORAGE)
    }
    
    var videoStorageRef: StorageReference {
        return storageRef.child(Constants.VIDEO_STORAGE)
    }
    
    func saveUser(withID: String, email: String, password: String) {
        let data: Dictionary<String, Any> = [Constants.EMAIL: email, Constants.PASSWORD: password]
        contactsRef.child(withID).setValue(data)
    }
    
    func getContacts() {
        var contacts = [Contact]()
        
        contactsRef.observeSingleEvent(of: DataEventType.value) {
            (snapshot: DataSnapshot) in
            
            var contacts = [Contact]()
            
            if let myContacts = snapshot.value as? NSDictionary {
                
                for (key, value) in  myContacts {
                    
                    if let contactData = value as? NSDictionary {
                       
                        if let email = contactData[Constants.EMAIL] as? String {
                           
                            let id = key as! String
                            let newContact = Contact(id: key as! String, name: email)
                            contacts.append(newContact)
                        }
                    }
                }
            }
            self.delegate?.dataReceived(contacts: contacts)
        }
    }
    
    
    
    
    
    
    
    
    
    
    
}
