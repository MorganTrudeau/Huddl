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

protocol FetchContactData: class {
    func contactDataReceived(contacts: [Contact])
}

protocol FetchChatRoomData: class {
    func chatRoomDataReceived(chatRooms: [ChatRoom])
}

protocol SavedChatRoom: class {
    func chatRoomSaved(success: Bool)
}

class DBProvider {
    
    private static let _instance = DBProvider()
    static var Instance: DBProvider {
        return _instance
    }
    
    weak var delegateContacts: FetchContactData?
    weak var delegateChatRooms: FetchChatRoomData?
    weak var delegateSaveChatRoom: SavedChatRoom?
    
    var currentRoomName: String?
    var selectedContactID: String?
    
    var dbRef: DatabaseReference {
        return Database.database().reference()
    }
    
    var contactsRef: DatabaseReference {
        return dbRef.child(Constants.CONTACTS)
    }
    
    var chatRoomsRef: DatabaseReference {
        return dbRef.child(Constants.CHAT_ROOMS)
    }
    
    var messagesRef: DatabaseReference {
        return dbRef.child(Constants.MESSAGES)
    }
    
    var chatRoomMessagesRef: DatabaseReference {
        return messagesRef.child(currentRoomName!)
    }
    
    var personalChatMessagesRef: DatabaseReference {
        return messagesRef.child(AuthProvider.Instance.userID() + selectedContactID!)
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
        contactsRef.observeSingleEvent(of: DataEventType.value) {
            (snapshot: DataSnapshot) in
            
            var contacts = [Contact]()
            
            if let myContacts = snapshot.value as? NSDictionary {
                
                for (key, value) in myContacts {
                    
                    if let contactData = value as? NSDictionary {
                       
                        if key as! String != AuthProvider.Instance.userID() {
                            
                            if let email = contactData[Constants.EMAIL] as? String {
                                
                                let id = key as! String
                                let newContact = Contact(id: id, name: email)
                                contacts.append(newContact)
                            }
                        }
                    }
                }
            }
            self.delegateContacts?.contactDataReceived(contacts: contacts)
        }
    }
    
    func saveChatRoom(name: String, password: String?) {
        var success = false
        let data: Dictionary<String, Any> = [Constants.ROOM_NAME: name, Constants.PASSWORD: password ?? ""]
        chatRoomsRef.observeSingleEvent(of: DataEventType.value, with: {(snapshot: DataSnapshot) in
            if !snapshot.hasChild(name) {
                self.chatRoomsRef.child(name).setValue(data)
                success = true
            }
            self.delegateSaveChatRoom?.chatRoomSaved(success: success)
        })
    }
    
    func getChatRooms() {
        chatRoomsRef.observeSingleEvent(of: DataEventType.value) {
            (snapshot: DataSnapshot) in
            
            var chatRooms = [ChatRoom]()
            
            if let myChatRooms = snapshot.value as? NSDictionary {
                
                for (key, value) in myChatRooms {
                    
                    if let chatRoomData = value as? NSDictionary {
                        
                        if let roomName = chatRoomData[Constants.ROOM_NAME] as? String {
                            let id = key as! String
                            let newRoom = ChatRoom(id: id, name: roomName)
                            chatRooms.append(newRoom)
                        }
                    }
                }
            }
            self.delegateChatRooms?.chatRoomDataReceived(chatRooms: chatRooms)
        }
    }
    
    

}
