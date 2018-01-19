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

protocol FetchRoomData: class {
    func roomDataReceived(room: Room)
    func allRoomDataReceived(rooms: [Room])
}

protocol FetchColorData: class {
    func colorDataReceived(color: String)
}

protocol CreateRoom: class {
    func roomCreated(success: Bool)
}

protocol ActiveUsersDecreased: class {
    func activeUsersDecreased()
}

protocol UserEnteredRoom: class {
    func userEnteredRoom()
}

class DBProvider {
    
    private static let _instance = DBProvider()
    static var Instance: DBProvider {
        return _instance
    }
    
    weak var delegateRooms: FetchRoomData?
    weak var delegateColor: FetchColorData?
    weak var delegateCreateRoom: CreateRoom?
    weak var delegateActiveUsersDecreased: ActiveUsersDecreased?
    weak var delegateUserEnteredRoom: UserEnteredRoom?
    
    var m_currentRoomID: String?
    var m_selectedContactID: String?
    var m_roomAddedHandle: UInt?
    var m_roomChangedHandle: UInt?
    
    var dbRef: DatabaseReference {
        return Database.database().reference()
    }
    
    var usersRef: DatabaseReference {
        return dbRef.child(Constants.USERS)
    }
    
    var roomsRef: DatabaseReference {
        return dbRef.child(Constants.ROOMS)
    }
    
    var messagesRef: DatabaseReference {
        return dbRef.child(Constants.MESSAGES)
    }
    
    var roomMessagesRef: DatabaseReference {
        return messagesRef.child(m_currentRoomID!)
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
    
    func createUser(withID: String, email: String, password: String, color: String) {
        let data: Dictionary<String, Any> = [Constants.EMAIL: email, Constants.PASSWORD: password, Constants.COLOR: color]
        usersRef.child(withID).setValue(data)
    }
    
    func currentUserColor() {
        var currentUserColor = ""
        usersRef.child(AuthProvider.Instance.userID()).observeSingleEvent(of: DataEventType.value, with: {(snapshot: DataSnapshot) in
            if let data = snapshot.value as? NSDictionary {
                if let color = data[Constants.COLOR] as? String {
                    currentUserColor = color
                }
            }
            self.delegateColor?.colorDataReceived(color: currentUserColor)
        })
    }
    
    func createRoom(name: String, password: String?) {
        var success = false
        let data: Dictionary<String, Any> = [Constants.ROOM_NAME: name, Constants.PASSWORD: password ?? "", Constants.ACTIVE_USERS: 0]
        roomsRef.observeSingleEvent(of: DataEventType.value, with: {(snapshot: DataSnapshot) in
            if !snapshot.hasChild(name) {
                self.roomsRef.child(name).setValue(data)
                success = true
            }
            self.delegateCreateRoom?.roomCreated(success: success)
        })
    }
    
    func createLocationRoom(id: String, name: String, password: String?) {
        var success = false
        let data: Dictionary<String, Any> = [Constants.ROOM_NAME: name, Constants.PASSWORD: password ?? "", Constants.ACTIVE_USERS: 0]
        roomsRef.observeSingleEvent(of: DataEventType.value, with: {(snapshot: DataSnapshot) in
            if !snapshot.hasChild(name) {
                self.roomsRef.child(id).setValue(data)
                success = true
            }
            self.delegateCreateRoom?.roomCreated(success: success)
        })
    }
    
    func observeRoomsChanged() {
        m_roomChangedHandle = roomsRef.observe(DataEventType.childChanged) { (snapshot: DataSnapshot) in
            self.delegateUserEnteredRoom?.userEnteredRoom()
        }
    }
    
    func observeRoomsAdded() {
        m_roomAddedHandle = roomsRef.observe(DataEventType.childAdded) {(snapshot: DataSnapshot) in
                
            if let data = snapshot.value as? NSDictionary {
                            
                if let roomName = data[Constants.ROOM_NAME] as? String {
                    
                    if let password =  data[Constants.PASSWORD] as? String {
                        
                        if let activeUsers = data[Constants.ACTIVE_USERS] as? Int {
                            let id = snapshot.key as String
                                let newRoom = Room(id: id, name: roomName, password: password, activeUsers: activeUsers)
                            self.delegateRooms?.roomDataReceived(room: newRoom)
                        }
                    }
                }
            }
        }
    }
    
    func getRooms() {
        roomsRef.observeSingleEvent(of: DataEventType.value) {
            (snapshot: DataSnapshot) in
            
            var rooms = [Room]()
            
            if let roomData = snapshot.value as? NSDictionary {
                
                for (key, value) in roomData {
                    
                    if let room = value as? NSDictionary {
                        
                        if let roomName = room[Constants.ROOM_NAME] as? String {
                            
                            if let password = room[Constants.PASSWORD] as? String {
                                
                                if let activeUsers = room[Constants.ACTIVE_USERS] as? Int {
                                    let id = key as! String
                                    let newRoom = Room(id: id, name: roomName, password: password, activeUsers: activeUsers)
                                    rooms.append(newRoom)
                                }
                            }
                        }
                    }
                }
            }
            self.delegateRooms?.allRoomDataReceived(rooms: rooms)
        }
    }
    
    func removeRoomsObserver(withHandle: String) {
        if withHandle == Constants.CHILD_ADDED_HANDLE {
            roomsRef.removeObserver(withHandle: m_roomAddedHandle!)
        } else if withHandle == Constants.CHILD_CHANGED_HANDLE {
            roomsRef.removeObserver(withHandle: m_roomChangedHandle!)
        }
    }
    
    func increaseActiveUsers() {
        roomsRef.child(m_currentRoomID!).runTransactionBlock({(data: MutableData) in
            if var room = data.value as? [String: Any] {
                var activeUsers = room[Constants.ACTIVE_USERS] as? Int
                activeUsers = activeUsers! + 1
                room[Constants.ACTIVE_USERS] = activeUsers
                data.value = room
            }
            return TransactionResult.success(withValue: data)
        })
    }
    
    func decreaseActiveUsersWithCallback() {
        roomsRef.child(m_currentRoomID!).runTransactionBlock({(data: MutableData) in
            if var room = data.value as? [String: Any] {
                var activeUsers = room[Constants.ACTIVE_USERS] as? Int
                activeUsers = activeUsers! - 1
                room[Constants.ACTIVE_USERS] = activeUsers
                data.value = room
            }
            return TransactionResult.success(withValue: data)}
            
            , andCompletionBlock: {(error: Error?, success: Bool, snapshot: DataSnapshot?) in
                if success {
                    self.delegateActiveUsersDecreased?.activeUsersDecreased()
                }
                })
    }
    
    func decreaseActiveUsers() {
        roomsRef.child(m_currentRoomID!).runTransactionBlock({(data: MutableData) in
            if var room = data.value as? [String: Any] {
                var activeUsers = room[Constants.ACTIVE_USERS] as? Int
                activeUsers = activeUsers! - 1
                room[Constants.ACTIVE_USERS] = activeUsers
                data.value = room
            }
            return TransactionResult.success(withValue: data)})
    }
    
    
}
