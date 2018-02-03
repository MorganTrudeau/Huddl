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
import SDWebImage

protocol FetchRoomData: class {
    func roomDataReceived(room: Room)
    func allRoomDataReceived(rooms: [Room])
}

protocol UserEnteredRoom: class {
    func userEnteredRoom()
}

protocol MediaLoaded: class {
    func mediaLoaded(id: String, image: UIImage)
}

typealias DefaultClosure = () -> Void

typealias SaveHandler = (_ success: Bool) -> Void

typealias ActiveUsersHandler = (_ activeUsers: Int, _ index: Int) -> Void

typealias CreateRoomHandler = (_ room: Room, _ success: Bool) -> Void

typealias GetRoomsHandler = (_ rooms: [Room]) -> Void

typealias ColorFetchHandler = (_ color: String) -> Void

typealias AvatarHandler = (_ avatar: UIImage) -> Void

typealias RoomUserHandler = (_ roomUsers: NSDictionary) -> Void

class DBProvider {
    
    private static let _instance = DBProvider()
    static var Instance: DBProvider {
        return _instance
    }
    
    weak var delegateRooms: FetchRoomData?
    weak var delegateUserEnteredRoom: UserEnteredRoom?
    weak var delegateMedia: MediaLoaded?
    
    var m_currentRoomID: String?
    var m_selectedContactID: String?
    var m_roomAddedHandle: UInt?
    var m_roomChangedHandle: UInt?
    
    let m_cacheStorage = CacheStorage.Instance
    let m_authProvider = AuthProvider.Instance
    
    var dbRef: DatabaseReference {
        return Database.database().reference()
    }
    
    var usersRef: DatabaseReference {
        return dbRef.child(Constants.USERS)
    }
    
    var roomsRef: DatabaseReference {
        return dbRef.child(Constants.ROOMS)
    }
    
    var userRoomsRef: DatabaseReference {
        return dbRef.child(Constants.USER_ROOMS)
    }
    
    var locationRoomsRef: DatabaseReference {
        return dbRef.child(Constants.LOCATION_ROOMS)
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
    
    // User Functions
    
    func createUser(withID: String, email: String, displayName: String, password: String, color: String) {
        let defaultAvatar = "https://firebasestorage.googleapis.com/v0/b/helloquent-a4460.appspot.com/o/Image_Storage%2Favatar.gif?alt=media&token=5dc264a6-3a70-4511-9adf-957d897a1d56"
        let data: Dictionary<String, Any> = [Constants.EMAIL: email, Constants.DISPLAY_NAME: displayName, Constants.PASSWORD: password, Constants.COLOR: color, Constants.AVATAR: defaultAvatar]
        // Store new user in Firebase
        usersRef.child(withID).setValue(data)
        // Store new user in cache
        m_cacheStorage.cacheUser(user: User(id: withID, name: displayName, color: color, avatar: defaultAvatar))
        m_cacheStorage.cacheImage(id: withID, image: UIImage(named: "avatar.gif")!)
    }
    
    func getUsers() {
        var userDictionary = [String:User]()
        usersRef.observeSingleEvent(of: .value, with: {(snapshot) in
            if let users = snapshot.value as? NSDictionary {
                for (key,value) in users {
                    if let user = value as? NSDictionary {
                        if let id = key as? String {
                            if let name = user[Constants.DISPLAY_NAME] as? String {
                                if let color = user[Constants.COLOR] as? String {
                                    if let avatar = user[Constants.ACTIVE_USERS] as? String {
                                        let newUser = User(id: id, name: name, color: color, avatar: avatar)
                                        userDictionary[id] = newUser
                                    }
                                }
                            }
                        }
                    }
                }
                self.m_cacheStorage.cacheUsers(users: userDictionary)
            }
        })
    }
    
    func getUser(id: String, completion: UserHandler?) {
        usersRef.observeSingleEvent(of: .value, with: {(snapshot) in
            if let userData = snapshot.childSnapshot(forPath: id).value as? NSDictionary {
                if let name = userData[Constants.DISPLAY_NAME] as? String {
                    if let color = userData[Constants.COLOR] as? String {
                        if let avatar = userData[Constants.AVATAR] as? String {
                            let user = User(id: id, name: name, color: color, avatar: avatar)
                            self.m_cacheStorage.cacheUser(user: user)
                            completion?(user)
                        }
                    }
                }
            }
        })
    }
    
    func saveProfile(displayName: String, color: String, avatar: UIImage?, avatarURL: String, completion: DefaultClosure?) {
        
        // Update current user profile
        if avatar != nil {
            let path = "\(NSUUID().uuidString)"
            let data = UIImageJPEGRepresentation(avatar!, 0.1)
            self.imageStorageRef.child(path).putData(data!, metadata: nil) {(metadata, error) in
                guard error == nil else {
                    print("Error occured while saving data")
                    return
                }
                let metadataURL = String(describing: metadata!.downloadURL()!)
                
                // Store updated user in cache
                let updatedUser = User(id: AuthProvider.Instance.userID(), name: displayName, color: color, avatar: metadataURL)
                self.m_cacheStorage.cacheUser(user: updatedUser)
                
                // Store image in cache
                self.m_cacheStorage.cacheImage(id: AuthProvider.Instance.userID(), image: avatar!)
                
//                // Add updated user to AuthProvider user dictionary
//                self.m_authProvider.users![self.m_authProvider.userID()]! = updatedUser
//
//                // Store updated user dictionary in cache
//                self.m_cacheStorage.cacheUsers(users: self.m_authProvider.users!)
                
                // Update user in Firebase
                self.usersRef.child(AuthProvider.Instance.userID()).runTransactionBlock({(data: MutableData) in
                    if var user = data.value as? [String: Any] {
                        user[Constants.AVATAR] = metadataURL
                        user[Constants.DISPLAY_NAME] = displayName
                        user[Constants.COLOR] = color
                        data.value = user
                        completion?()
                    }
                    return TransactionResult.success(withValue: data)})
            }
        } else {
            // Store updated user in cache
            let updatedUser = User(id: AuthProvider.Instance.userID(), name: displayName, color: color, avatar: avatarURL)
            self.m_cacheStorage.cacheUser(user: updatedUser)
            
            // Update user in Firebase
            self.usersRef.child(AuthProvider.Instance.userID()).runTransactionBlock({(data: MutableData) in
                if var user = data.value as? [String: Any] {
                    user[Constants.DISPLAY_NAME] = displayName
                    user[Constants.COLOR] = color
                    data.value = user
                    completion?()
                }
                return TransactionResult.success(withValue: data)})
            }
    }
    
    // Room Functions
    
    func createRoom(name: String, description: String?, password: String?, roomCreated: CreateRoomHandler?){
        var success = false
        var newRoom: Room?
        let data: Dictionary<String, Any> = [Constants.ROOM_NAME: name, Constants.DESCRIPTION: description ?? "", Constants.PASSWORD: password ?? "", Constants.ACTIVE_USERS: 0]
        userRoomsRef.observeSingleEvent(of: DataEventType.value, with: {(snapshot: DataSnapshot) in
            if !snapshot.hasChild(name) {
                
                self.userRoomsRef.child(name).setValue(data)
                self.roomsRef.child(name).setValue(data)
                newRoom = Room(id: name, name: name, description: description!, password: password!, activeUsers: 0)
                success = true
            }
            roomCreated?(newRoom!, success)
        })
    }
    
    func getUserRooms(completion: GetRoomsHandler?) {
        userRoomsRef.observeSingleEvent(of: DataEventType.value) {
            (snapshot: DataSnapshot) in
            
            var rooms = [Room]()
            
            if let roomData = snapshot.value as? NSDictionary {
                
                for (key, value) in roomData {
                    
                    if let room = value as? NSDictionary {
                        
                        if let roomName = room[Constants.ROOM_NAME] as? String {
                            
                            if let description = room[Constants.DESCRIPTION] as? String {
                                
                                if let password = room[Constants.PASSWORD] as? String {
                                    
                                    if let activeUsers = room[Constants.ACTIVE_USERS] as? Int {
                                        
                                        let id = key as! String
                                        let newRoom = Room(id: id, name: roomName, description: description, password: password, activeUsers: activeUsers)
                                        rooms.append(newRoom)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            completion?(rooms)
        }
    }
    
    func createLocationRoom(id: String, name: String, description: String?, password: String?) {
        let data: Dictionary<String, Any> = [Constants.ROOM_NAME: name, Constants.DESCRIPTION: description ?? "", Constants.PASSWORD: password ?? "", Constants.ACTIVE_USERS: 0]
        roomsRef.observeSingleEvent(of: DataEventType.value, with: {(snapshot: DataSnapshot) in
            if !snapshot.hasChild(id) {
                self.roomsRef.child(id).setValue(data)
            }
        })
    }
    
    func addRoomUser(userID: String) {
        roomsRef.child(m_currentRoomID!).child(Constants.ROOM_USERS).setValue([userID:true])
    }
    
    func getRoomUsers(completion: RoomUserHandler?) {
        roomsRef.child(m_currentRoomID!).observeSingleEvent(of: .value, with: {(snapshot) in
            if let room = snapshot.value as? NSDictionary {
                if let roomUsers = room[Constants.ROOM_USERS] as? NSDictionary {
                    completion?(roomUsers)
                }
            }
        })
    }
    
    func getActiveRooms(completion: GetRoomsHandler?) {
        roomsRef.observeSingleEvent(of: DataEventType.value) {
            (snapshot: DataSnapshot) in
            
            var rooms = [Room]()
            
            if let roomData = snapshot.value as? NSDictionary {
                
                for (key, value) in roomData {
                    
                    if let room = value as? NSDictionary {
                        
                        if let activeUsers = room[Constants.ACTIVE_USERS] as? Int {
                            
                            if activeUsers > 0 {
                        
                                if let roomName = room[Constants.ROOM_NAME] as? String {
                                
                                    if let description = room[Constants.DESCRIPTION] as? String {
                                
                                        if let password = room[Constants.PASSWORD] as? String {
                                    
                                            let id = key as! String
                                            let newRoom = Room(id: id, name: roomName, description: description, password: password, activeUsers: activeUsers)
                                            rooms.append(newRoom)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            completion?(rooms)
        }
    }
    
    func getSavedRooms(savedIDs: [String], completion: GetRoomsHandler?) {
        
        var rooms = [Room]()
        
        roomsRef.observeSingleEvent(of: .value, with: {(snapshot) in
            
            for id in savedIDs {
                
                if snapshot.hasChild(id) {
                    
                    if let room = snapshot.childSnapshot(forPath: id).value as? NSDictionary {
                        
                        if let roomName = room[Constants.ROOM_NAME] as? String {
                            
                            if let description = room[Constants.DESCRIPTION] as? String {
                                
                                if let password = room[Constants.PASSWORD] as? String {
                                    
                                    if let activeUsers = room[Constants.ACTIVE_USERS] as? Int {
                                        
                                        let id = id
                                        let newRoom = Room(id: id, name: roomName, description: description, password: password, activeUsers: activeUsers)
                                        rooms.append(newRoom)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            completion?(rooms)
        })
    }
    
    func hasRoom(roomID: String, index: Int, completion: ActiveUsersHandler?) {
        roomsRef.observeSingleEvent(of: DataEventType.value, with: {(snapshot: DataSnapshot) in
            
            if snapshot.hasChild(roomID) {
                
                let child = snapshot.childSnapshot(forPath: "\(roomID)/active_users")
                    
                if let activeUsers = child.value as? Int {
        
                    completion?(activeUsers, index)
                }
            } else {
                completion?(0, index)
            }
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
                    
                    if let description = data[Constants.DESCRIPTION] as? String {
                    
                        if let password =  data[Constants.PASSWORD] as? String {
                        
                            if let activeUsers = data[Constants.ACTIVE_USERS] as? Int {
                                
                                let id = snapshot.key as String
                                let newRoom = Room(id: id, name: roomName, description: description, password: password, activeUsers: activeUsers)
                                self.delegateRooms?.roomDataReceived(room: newRoom)
                            }
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
                            
                            if let description = room[Constants.DESCRIPTION] as? String {
                            
                                if let password = room[Constants.PASSWORD] as? String {
                                
                                    if let activeUsers = room[Constants.ACTIVE_USERS] as? Int {
                                        
                                        let id = key as! String
                                        let newRoom = Room(id: id, name: roomName, description: description, password: password, activeUsers: activeUsers)
                                        rooms.append(newRoom)
                                    }
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
    
    func decreaseActiveUsers(completion: DefaultClosure?) {
        roomsRef.child(m_currentRoomID!).runTransactionBlock({(data: MutableData) in
            if var room = data.value as? [String: Any] {
                var activeUsers = room[Constants.ACTIVE_USERS] as? Int
                activeUsers = activeUsers! - 1
                room[Constants.ACTIVE_USERS] = activeUsers
                data.value = room
            }
            return TransactionResult.success(withValue: data)}, andCompletionBlock:     {(error: Error?, success: Bool, snapshot: DataSnapshot?) in
                if success {
                    completion?()
                }
        })
    }
    
    func loadMedia(id: String, url: String, completion: ImageHandler?) {
        if let mediaURL = URL(string: url) {
            do {
                let data = try Data(contentsOf: mediaURL)
                if let _ = UIImage(data: data) {
                    let _ = SDWebImageDownloader.shared().downloadImage(with: mediaURL, options: [], progress: nil, completed: {(image, data, error, finished) in
                        
                        if error != nil {
                            print("Image download error: \(String(describing: error!))")
                        } else {
                            completion?(image!)
                            self.m_cacheStorage.cacheImage(id: id, image: image!)
                            self.delegateMedia?.mediaLoaded(id: id, image: image!)
                        }
                    })
                } else {
                    // video is mediaURL
                }
            } catch {
                print("Error downloading Data")
            }
        }
    }

    
    
}
