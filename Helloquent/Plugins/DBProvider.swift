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
import Cache

protocol FetchRoomData: class {
    func roomDataReceived(room: Room)
    func allRoomDataReceived(rooms: [Room])
}

protocol UserEnteredRoom: class {
    func userEnteredRoom()
}

typealias DefaultClosure = () -> Void

typealias SaveHandler = (_ success: Bool) -> Void

typealias ActiveUsersHandler = (_ activeUsers: Int, _ index: Int) -> Void

typealias CreateRoomHandler = (_ room: Room, _ success: Bool) -> Void

typealias GetRoomsHandler = (_ rooms: [Room]) -> Void

typealias GetLocationRoomsHandler = (_ rooms: [LocationRoom]) -> Void

typealias ColorFetchHandler = (_ color: String) -> Void

typealias AvatarHandler = (_ avatar: UIImage) -> Void

typealias RoomUserHandler = (_ roomUsers: [String]) ->  Void

class DBProvider {
    
    private static let _instance = DBProvider()
    static var Instance: DBProvider {
        return _instance
    }
    
    weak var delegateRooms: FetchRoomData?
    weak var delegateUserEnteredRoom: UserEnteredRoom?
    
    var m_currentRoomID: String?
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
        return Storage.storage().reference(forURL: "gs://rooms-68d7a.appspot.com/")
    }
    
    var imageStorageRef: StorageReference {
        return storageRef.child(Constants.IMAGE_STORAGE)
    }
    
    var videoStorageRef: StorageReference {
        return storageRef.child(Constants.VIDEO_STORAGE)
    }
    
    // User Functions
    
    func createUser(withID: String, email: String, displayName: String, password: String, color: String) {
        let defaultAvatar = "https://firebasestorage.googleapis.com/v0/b/helloquent-a4460.appspot.com/o/Image_Storage%2F59D84132-6661-4CD6-8DC7-E27E14A530B4?alt=media&token=93865466-8228-433b-938e-1cf10fd7c829"
        let data: Dictionary<String, Any> = [Constants.EMAIL: email, Constants.DISPLAY_NAME: displayName, Constants.PASSWORD: password, Constants.COLOR: color, Constants.AVATAR: defaultAvatar]
        // Store new user in Firebase
        usersRef.child(withID).setValue(data)
    }
    
    func getUser(id: String, completion: DefaultClosure?) {
        self.usersRef.observeSingleEvent(of: .value, with: {(snapshot) in
            DispatchQueue.global().async {
                if let userData = snapshot.childSnapshot(forPath: id).value as? NSDictionary {
                    if let name = userData[Constants.DISPLAY_NAME] as? String {
                        if let color = userData[Constants.COLOR] as? String {
                            if let avatar = userData[Constants.AVATAR] as? String {
                                let user = User(id: id, name: name, color: color, avatar: avatar)
                                self.m_cacheStorage.cacheUser(user: user)
                                self.loadMedia(url: user.avatar, completion: {() in
                                    completion?()
                                })
                            }
                        }
                    }
                }
            }
        })
    }
    
    func updateRoomUsers(roomUser: String) {
        self.roomsRef.child(self.m_currentRoomID!).observeSingleEvent(of: .value, with: {(snapshot) in
            var room = snapshot.value as! NSDictionary
            if var roomUsers = room[Constants.ROOM_USERS] as? [String] {
                roomUsers.append(roomUser)
                print("Updated room users: \(roomUsers)")
                self.roomsRef.child("\(self.m_currentRoomID!)/\(Constants.ROOM_USERS)").setValue(roomUsers)
            } else {
                room.setValue([roomUser], forKey: Constants.ROOM_USERS)
                self.roomsRef.child(self.m_currentRoomID!).setValue(room)
            }
        })
    }
    
    func getRoomUsers(completion: RoomUserHandler?) {
        self.roomsRef.child(self.m_currentRoomID!).observeSingleEvent(of: .value, with: {(snapshot) in
            if let room = snapshot.value as? NSDictionary {
                if let roomUsers = room[Constants.ROOM_USERS] as? [String] {
                    completion?(roomUsers)
                    print("Current room users: \(roomUsers)")
                    for userID in roomUsers {
                        self.getUser(id: userID, completion: nil)
                    }
                }
            }
        })
    }
    
    func saveProfile(displayName: String, color: String, avatar: UIImage?, completion: SaveHandler?) {
        
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
                
                // Store image in cache
                self.m_cacheStorage.cacheImage(id: metadataURL, image: avatar!)
                
                // Store updated user in cache
                self.m_cacheStorage.cacheUser(user: User(id: self.m_authProvider.userID(), name: displayName, color: color, avatar: metadataURL))
                
                // Update user in Firebase
                self.usersRef.child(AuthProvider.Instance.userID()).runTransactionBlock({(data: MutableData) in
                    if var user = data.value as? [String: Any] {
                        user[Constants.AVATAR] = metadataURL
                        user[Constants.DISPLAY_NAME] = displayName
                        user[Constants.COLOR] = color
                        data.value = user
                        DispatchQueue.main.sync {
                            completion?(true)
                        }
                    }
                    return TransactionResult.success(withValue: data)})
            }
        } else {
            // Update user in Firebase
            self.usersRef.child(AuthProvider.Instance.userID()).runTransactionBlock({(data: MutableData) in
                if var user = data.value as? [String: Any] {
                    user[Constants.DISPLAY_NAME] = displayName
                    user[Constants.COLOR] = color
                    data.value = user
                    
                    // Store updated user in cache
                    self.m_cacheStorage.cacheUser(user: User(id: self.m_authProvider.userID(), name: displayName, color: color, avatar: user[Constants.AVATAR] as! String))
                    
                    DispatchQueue.main.sync {
                        completion?(false)
                    }
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
                newRoom = Room(name: name, description: description!, id: name, password: password!, activeUsers: 0)
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
                                        let newRoom = Room(name: roomName, description: description, id: id, password: password, activeUsers: activeUsers)
                                        rooms.append(newRoom)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            completion?(rooms)
            self.m_cacheStorage.cacheRooms(type: "user", rooms: rooms)
        }
    }
    
    func createLocationRoom(id: String, name: String, description: String?, password: String?, lat: String, long: String) {
        let data: Dictionary<String, Any> = [Constants.ROOM_NAME: name, Constants.DESCRIPTION: description ?? "", Constants.PASSWORD: password ?? "", Constants.ACTIVE_USERS: 0, Constants.LATITUDE: lat, Constants.LONGITUDE: long]
        roomsRef.observeSingleEvent(of: DataEventType.value, with: {(snapshot: DataSnapshot) in
            if !snapshot.hasChild(id) {
                self.roomsRef.child(id).setValue(data)
            }
        })
        locationRoomsRef.observeSingleEvent(of: .value, with: {(snapshot) in
            if !snapshot.hasChild(id) {
                self.locationRoomsRef.child(id).setValue(data)
            }
        })
    }
    
    func getLocationRooms(completion: GetLocationRoomsHandler?) {
        locationRoomsRef.observeSingleEvent(of: DataEventType.value) {
            (snapshot: DataSnapshot) in
            
            var rooms = [LocationRoom]()
            
            if let roomData = snapshot.value as? NSDictionary {
                
                for (id, value) in roomData {
                    
                    if let room = value as? NSDictionary {
                        
                        if let roomName = room[Constants.ROOM_NAME] as? String {
                            
                            if let description = room[Constants.DESCRIPTION] as? String {
                                
                                if let password = room[Constants.PASSWORD] as? String {
                                    
                                    if let activeUsers = room[Constants.ACTIVE_USERS] as? Int {
                                        
                                        if let latitude = room[Constants.LATITUDE] as? String {
                                            
                                            if let longitude = room[Constants.LONGITUDE] as? String {
                                                
                                                let room = LocationRoom(name: roomName, description: description, id: id as! String, password: password, activeUsers: activeUsers, latitude: latitude, longitude: longitude)
                                                rooms.append(room)
                                            }
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
                                            let newRoom = Room(name: roomName, description: description, id: id, password: password, activeUsers: activeUsers)
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
                                        let newRoom = Room(name: roomName, description: description, id: id, password: password, activeUsers: activeUsers)
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
                                let newRoom = Room(name: id, description: roomName, id: description, password: password, activeUsers: activeUsers)
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
                                        let newRoom = Room(name: roomName, description: description, id: id, password: password, activeUsers: activeUsers)
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
        locationRoomsRef.child(m_currentRoomID!).runTransactionBlock({(data: MutableData) in
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
                if activeUsers! > 0 {
                    activeUsers = activeUsers! - 1
                }
                room[Constants.ACTIVE_USERS] = activeUsers
                data.value = room
            }
            return TransactionResult.success(withValue: data)
        })
        locationRoomsRef.child(m_currentRoomID!).runTransactionBlock({(data: MutableData) in
            if var room = data.value as? [String: Any] {
                var activeUsers = room[Constants.ACTIVE_USERS] as? Int
                activeUsers = activeUsers! - 1
                room[Constants.ACTIVE_USERS] = activeUsers
                data.value = room
            }
            return TransactionResult.success(withValue: data)
        })
    }
    
    func loadMedia(url: String, completion: DefaultClosure?) {
        if !(try! m_cacheStorage.m_mediaStorage.existsObject(ofType: ImageWrapper.self, forKey: url)) {
            if let mediaURL = URL(string: url) {
                do {
                    let data = try Data(contentsOf: mediaURL)
                    if let _ = UIImage(data: data) {
                        let _ = SDWebImageDownloader.shared().downloadImage(with: mediaURL, options: [], progress: nil, completed: {(image, data, error, finished) in
                            
                            if error != nil {
                                print("Image download error: \(String(describing: error!))")
                            } else {
                                self.m_cacheStorage.cacheImage(id: url, image: image!)
                                completion?()
                            }
                        })
                    } else {
                        // video is mediaURL
                    }
                } catch {
                    print("Error downloading Media Data")
                }
            }
        } else {
            completion?()
        }
    }

    
    
}
