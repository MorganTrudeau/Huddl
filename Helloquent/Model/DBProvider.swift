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

protocol LikesDelegate: class {
    func likesReceived(likes: Int, indexPath: IndexPath)
}

typealias DefaultClosure = () -> Void
typealias SuccessHandler = (_ success: Bool) -> Void
typealias CreateRoomHandler = (_ room: Room?, _ success: Bool) -> Void
typealias GetRoomsHandler = (_ rooms: [Room]) -> Void
typealias GetLocationRoomsHandler = (_ rooms: [LocationRoom]) -> Void
typealias ColorFetchHandler = (_ color: String) -> Void
typealias AvatarHandler = (_ avatar: UIImage) -> Void
typealias RoomUserHandler = (_ roomUsers: [String]) ->  Void
typealias UserHandler = (_ user: User) -> Void
typealias BlockListHander = (_ blockedList: [String]) -> Void

class DBProvider {
    
    private static let _instance = DBProvider()
    static var Instance: DBProvider {
        return _instance
    }
    
    weak var delegateRooms: FetchRoomData?
    weak var delegateUserEnteredRoom: UserEnteredRoom?
    weak var delegateLikes: LikesDelegate?
    
    var m_currentRoom: Room?
    var m_currentChatID: String?
    
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
    
    var chatsRef: DatabaseReference {
        return dbRef.child(Constants.CHATS)
    }
    
    var likedRoomsRef: DatabaseReference {
        return dbRef.child(Constants.LIKED_ROOMS)
    }
    
    var userRoomsRef: DatabaseReference {
        return dbRef.child(Constants.USER_ROOMS)
    }
    
    var locationRoomsRef: DatabaseReference {
        return dbRef.child(Constants.LOCATION_ROOMS)
    }
    
    var roomMessagesRef: DatabaseReference {
        return dbRef.child(Constants.ROOM_MESSAGES)
    }
    
    var roomMessagesChildRef: DatabaseReference {
        return roomMessagesRef.child(m_currentRoom!.id)
    }
    
    var chatMessagesRef: DatabaseReference {
        return dbRef.child(Constants.CHAT_MESSAGES)
    }
    
    var chatMessagesChildRef: DatabaseReference {
        return chatMessagesRef.child(m_currentChatID!)
    }
    
    var mediaMessagesRef: DatabaseReference {
        return dbRef.child(Constants.MEDIA_MESSAGES)
    }
    
    var reportsRef: DatabaseReference {
        return dbRef.child(Constants.REPORTS)
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
        let defaultAvatar = "https://firebasestorage.googleapis.com/v0/b/rooms-68d7a.appspot.com/o/Image_Storage%2F041F1F01-03A7-4749-B9BC-5331B63C20F8?alt=media&token=9cbf6b34-a969-4530-8f91-4d8308e6cbfa"
        let data: Dictionary<String, Any> = [Constants.EMAIL: email, Constants.DISPLAY_NAME: displayName, Constants.PASSWORD: password, Constants.COLOR: color, Constants.AVATAR: defaultAvatar]
        // Store new user in Firebase
        usersRef.child(withID).setValue(data)
    }
    
    func getUser(id: String, completion: UserHandler?) {
        self.usersRef.observeSingleEvent(of: .value, with: {(snapshot) in
            DispatchQueue.global().async {
                if let userData = snapshot.childSnapshot(forPath: id).value as? NSDictionary {
                    if let name = userData[Constants.DISPLAY_NAME] as? String {
                        if let color = userData[Constants.COLOR] as? String {
                            if let avatar = userData[Constants.AVATAR] as? String {
                                if let chats = userData[Constants.CHATS] as? [String:String] {
                                    let user = User(id: id, name: name, color: color, avatar: avatar, chats: chats)
                                    self.m_cacheStorage.cacheUser(user: user)
                                    self.loadMedia(url: user.avatar, completion: {() in
                                        completion?(user)
                                    })
                                } else {
                                    let user = User(id: id, name: name, color: color, avatar: avatar, chats: [:])
                                    self.m_cacheStorage.cacheUser(user: user)
                                    self.loadMedia(url: user.avatar, completion: {() in
                                        completion?(user)
                                    })
                                }
                            }
                        }
                    }
                }
            }
        })
    }
    
    func updateRoomUsers(roomUser: String) {
        self.roomsRef.child(self.m_currentRoom!.id).observeSingleEvent(of: .value, with: {(snapshot) in
            if var room = snapshot.value as? NSDictionary {
                if var roomUsers = room[Constants.ROOM_USERS] as? [String] {
                    roomUsers.append(roomUser)
                    print("Updated room users: \(roomUsers)")
                    self.roomsRef.child("\(self.m_currentRoom!.id)/\(Constants.ROOM_USERS)").setValue(roomUsers)
                } else {
                    room.setValue([roomUser], forKey: Constants.ROOM_USERS)
                    self.roomsRef.child(self.m_currentRoom!.id).setValue(room)
                }
            }
        })
    }
    
    func getRoomUsers(completion: RoomUserHandler?) {
        self.roomsRef.child(self.m_currentRoom!.id).observeSingleEvent(of: .value, with: {(snapshot) in
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
    
    func blockUser(userID: String) {
        self.usersRef.child(userID).observeSingleEvent(of: .value, with: {(snapshot) in
            if var user = snapshot.value as? NSDictionary {
                if var blockedUsers = user[Constants.BLOCKED_USERS] as? [String] {
                    if (!blockedUsers.contains { $0 == self.m_authProvider.userID() }) {
                        blockedUsers.append(self.m_authProvider.userID())
                        print("\(userID) blocked")
                        self.usersRef.child("\(userID)/\(Constants.BLOCKED_USERS)").setValue(blockedUsers)
                    }
                } else {
                    user.setValue([self.m_authProvider.userID()], forKey: Constants.BLOCKED_USERS)
                    self.usersRef.child(userID).setValue(user)
                }
            }
        })
    }
    
    func unblockUser(userID: String) {
        self.usersRef.child(userID).observeSingleEvent(of: .value, with: {(snapshot) in
            if let user = snapshot.value as? NSDictionary {
                if var blockedUsers = user[Constants.BLOCKED_USERS] as? [String] {
                    blockedUsers = blockedUsers.filter { $0 != self.m_authProvider.userID() }
                    print("\(userID) unblocked")
                    self.usersRef.child("\(userID)/\(Constants.BLOCKED_USERS)").setValue(blockedUsers)
                }
            }
        })
    }
    
    func getBlockedList(completion: BlockListHander?) {
        self.usersRef.child(m_authProvider.userID()).observeSingleEvent(of: .value, with: {(snapshot) in
            if let user = snapshot.value as? NSDictionary {
                if let blockedUsers = user[Constants.BLOCKED_USERS] as? [String] {
                    completion?(blockedUsers)
                }
                else {
                    completion?([])
                }
            }
        })
    }
    
    func reportMessage(roomID: String, message: Int) {
        let uudid =  UUID().uuidString
        self.reportsRef.child(uudid).setValue([roomID:message])
    }
    
    func saveProfile(displayName: String, color: String, avatar: UIImage?, completion: SuccessHandler?) {
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
                
                // Update user in Firebase
                self.usersRef.child(AuthProvider.Instance.userID()).runTransactionBlock({(data: MutableData) in
                    if var user = data.value as? [String: Any] {
                        user[Constants.AVATAR] = metadataURL
                        user[Constants.DISPLAY_NAME] = displayName
                        user[Constants.COLOR] = color
                        data.value = user
                        
                        // Store updated user in cache
                        self.m_cacheStorage.cacheUser(user: User(id: self.m_authProvider.userID(), name: displayName, color: color, avatar: metadataURL, chats: user[Constants.CHATS] as? [String:String] ?? [:]))
                        
                        completion?(true)
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
                    self.m_cacheStorage.cacheUser(user: User(id: self.m_authProvider.userID(), name: displayName, color: color, avatar: user[Constants.AVATAR] as! String, chats: user[Constants.CHATS] as? [String:String] ?? [:]))
                    
                    completion?(false)
                }
                return TransactionResult.success(withValue: data)})
            }
    }
    
    /**
     Room Functions
     **/
    
    func createRoom(name: String, description: String?, password: String?, roomCreated: CreateRoomHandler?){
        var newRoom: Room?
        let data: Dictionary<String, Any> = [Constants.ROOM_NAME: name, Constants.DESCRIPTION: description ?? "", Constants.PASSWORD: password ?? "", Constants.LIKES: 0]
        userRoomsRef.observeSingleEvent(of: DataEventType.value, with: {(snapshot: DataSnapshot) in
            if !snapshot.hasChild(name) {
                let uudid =  UUID().uuidString
                self.userRoomsRef.child(uudid).setValue(data)
                self.roomsRef.child(uudid).setValue(data)
                newRoom = Room(name: name, description: description!, id: uudid, password: password!, likes: 0)
                roomCreated?(newRoom!, true)
            } else {
                roomCreated?(nil, false)
            }
        })
    }
    
    func createLocationRoom(id: String, name: String, description: String?, password: String?, lat: String, long: String) {
        let data: Dictionary<String, Any> = [Constants.ROOM_NAME: name, Constants.DESCRIPTION: description ?? "", Constants.PASSWORD: password ?? "", Constants.LIKES: 0, Constants.LATITUDE: lat, Constants.LONGITUDE: long]
        roomsRef.observeSingleEvent(of: DataEventType.value, with: {(snapshot: DataSnapshot) in
            if !snapshot.hasChild(id) {
                self.roomsRef.child(id).setValue(data)
                self.locationRoomsRef.child(id).setValue(data)
            }
        })
    }
    
    func createChat(receiverID: String) {
        let chatID = "\(m_authProvider.userID())\(receiverID)"
        let senderID = m_authProvider.userID()
        
        // Create chat reference for sender
        self.usersRef.child(senderID).observeSingleEvent(of: .value, with: {(snapshot) in
            var user = snapshot.value as! NSDictionary
            if var chats = user[Constants.CHATS] as? NSDictionary {
                chats.setValue(chatID, forKey: receiverID)
                user.setValue(chats, forKey: Constants.CHATS)
                self.usersRef.child(senderID).setValue(user)
            } else {
                user.setValue([receiverID:chatID], forKey: Constants.CHATS)
                self.usersRef.child(senderID).setValue(user)
            }
            if let name = user[Constants.DISPLAY_NAME] as? String {
                if let color = user[Constants.COLOR] as? String {
                    if let avatar = user[Constants.AVATAR] as? String {
                        if let chats = user[Constants.CHATS] as? NSDictionary {
                            let u = User(id: senderID, name: name, color: color, avatar: avatar, chats: chats as! [String : String])
                            self.m_cacheStorage.cacheUser(user: u)
                        }
                    }
                }
            }
        })
        
        // Create chat reference for receiver
        self.usersRef.child(receiverID).observeSingleEvent(of: .value, with: {(snapshot) in
            var user = snapshot.value as! NSDictionary
            if var chats = user[Constants.CHATS] as? NSDictionary {
                chats.setValue(chatID, forKey: senderID)
                self.usersRef.child("\(receiverID)/\(Constants.CHATS)").setValue(chats)
            } else {
                user.setValue([senderID:chatID], forKey: Constants.CHATS)
                self.usersRef.child(receiverID).setValue(user)
            }
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
                                    if let likes = room[Constants.LIKES] as? Int {
                                        let id = key as! String
                                        let newRoom = Room(name: roomName, description: description, id: id, password: password, likes: likes)
                                        rooms.append(newRoom)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            rooms.sort(by: { $0.name < $1.name })
            completion?(rooms)
            self.m_cacheStorage.cacheRooms(type: "user", rooms: rooms)
        }
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
                                    if let likes = room[Constants.LIKES] as? Int {
                                        if let latitude = room[Constants.LATITUDE] as? String {
                                            if let longitude = room[Constants.LONGITUDE] as? String {
                                                let room = LocationRoom(name: roomName, description: description, id: id as! String, password: password, likes: likes, latitude: latitude, longitude: longitude)
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
    
    func getLikedRooms(completion: GetRoomsHandler?) {
        likedRoomsRef.observeSingleEvent(of: DataEventType.value) {
            (snapshot: DataSnapshot) in
            var rooms = [Room]()
            if let roomData = snapshot.value as? NSDictionary {
                for (key, value) in roomData {
                    if let room = value as? NSDictionary {
                        if let likes = room[Constants.LIKES] as? Int  {
                            if let roomName = room[Constants.ROOM_NAME] as? String {
                                if let description = room[Constants.DESCRIPTION] as? String {
                                    if let password = room[Constants.PASSWORD] as? String {
                                        let id = key as! String
                                        let newRoom = Room(name: roomName, description: description, id: id, password: password, likes: likes)
                                        rooms.append(newRoom)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            rooms.sort(by: { $0.likes > $1.likes })
            completion?(rooms)
        }
    }
    
    func getLikes(id: String, indexPath: IndexPath) {
        likedRoomsRef.child("\(id)/\(Constants.LIKES)").observeSingleEvent(of: .value, with: {(snapshot) in
            if let likes = snapshot.value as? Int {
                self.delegateLikes?.likesReceived(likes: likes, indexPath: indexPath)
            }
        })
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
                                    if let likes = room[Constants.LIKES] as? Int {
                                        let id = key as! String
                                        let newRoom = Room(name: roomName, description: description, id: id, password: password, likes: likes)
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
    
    func hasLikedRoom(id: String, completion: @escaping SuccessHandler) {
        likedRoomsRef.observeSingleEvent(of: .value, with: {(snapshot) in
            if snapshot.hasChild(id) {
                completion(true)
            } else {
                completion(false)
            }
        })
    }
    
    func increaseLikes() {
        hasLikedRoom(id: m_currentRoom!.id, completion: {(hasRoom) in
            if hasRoom {
                self.likedRoomsRef.child(self.m_currentRoom!.id).runTransactionBlock({(data: MutableData) in
                    if var room = data.value as? [String: Any] {
                        var likes = room[Constants.LIKES] as? Int
                        likes = likes! + 1
                        room[Constants.LIKES] = likes
                        data.value = room
                    }
                    return TransactionResult.success(withValue: data)
                })
            } else {
                let likedRoom: Dictionary<String, Any> = [Constants.ROOM_NAME: self.m_currentRoom!.name, Constants.DESCRIPTION: self.m_currentRoom!.description , Constants.PASSWORD: self.m_currentRoom!.password , Constants.LIKES: 1]
                self.likedRoomsRef.child(self.m_currentRoom!.id).setValue(likedRoom)
            }
        })
    }
    
    func decreaseLikes() {
        likedRoomsRef.child(m_currentRoom!.id).observeSingleEvent(of: .value, with: {(snapshot) in
            if let room = snapshot.value as? NSDictionary {
                if let likes = room[Constants.LIKES] as? Int {
                    if likes > 1 {
                        self.likedRoomsRef.child(self.m_currentRoom!.id).runTransactionBlock({(data: MutableData) in
                            if var room = data.value as? [String: Any] {
                                var likes = room[Constants.LIKES] as? Int
                                if likes! > 0 {
                                    likes = likes! - 1
                                }
                                room[Constants.LIKES] = likes
                                data.value = room
                            }
                            return TransactionResult.success(withValue: data)
                        })
                    } else {
                        self.likedRoomsRef.child(self.m_currentRoom!.id).removeValue()
                    }
                }
            }
        })
        roomsRef.child(m_currentRoom!.id).runTransactionBlock({(data: MutableData) in
            if var room = data.value as? [String: Any] {
                var likes = room[Constants.LIKES] as? Int
                if likes! > 0 {
                    likes = likes! - 1
                }
                room[Constants.LIKES] = likes
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
    
    /**
     Functions for future implementation
    **/
    
//    func increaseActiveUsers() {
//        roomsRef.child(m_currentRoom!.id).runTransactionBlock({(data: MutableData) in
//            if var room = data.value as? [String: Any] {
//                var activeUsers = room[Constants.ACTIVE_USERS] as? Int
//                activeUsers = activeUsers! + 1
//                room[Constants.ACTIVE_USERS] = activeUsers
//                data.value = room
//            }
//            return TransactionResult.success(withValue: data)
//        })
//        locationRoomsRef.child(m_currentRoom!.id).runTransactionBlock({(data: MutableData) in
//            if var room = data.value as? [String: Any] {
//                var activeUsers = room[Constants.ACTIVE_USERS] as? Int
//                activeUsers = activeUsers! + 1
//                room[Constants.ACTIVE_USERS] = activeUsers
//                data.value = room
//            }
//            return TransactionResult.success(withValue: data)
//        })
//    }
//    
//    func decreaseActiveUsers(completion: DefaultClosure?) {
//        roomsRef.child(m_currentRoom!.id).runTransactionBlock({(data: MutableData) in
//            if var room = data.value as? [String: Any] {
//                var activeUsers = room[Constants.ACTIVE_USERS] as? Int
//                if activeUsers! > 0 {
//                    activeUsers = activeUsers! - 1
//                }
//                room[Constants.ACTIVE_USERS] = activeUsers
//                data.value = room
//            }
//            return TransactionResult.success(withValue: data)
//        })
//        locationRoomsRef.child(m_currentRoom!.id).runTransactionBlock({(data: MutableData) in
//            if var room = data.value as? [String: Any] {
//                var activeUsers = room[Constants.ACTIVE_USERS] as? Int
//                activeUsers = activeUsers! - 1
//                room[Constants.ACTIVE_USERS] = activeUsers
//                data.value = room
//            }
//            return TransactionResult.success(withValue: data)
//        })
//    }
//    
//    func removeRoomsObserver(withHandle: String) {
//        if withHandle == Constants.CHILD_ADDED_HANDLE {
//            roomsRef.removeObserver(withHandle: m_roomAddedHandle!)
//        } else if withHandle == Constants.CHILD_CHANGED_HANDLE {
//            roomsRef.removeObserver(withHandle: m_roomChangedHandle!)
//        }
//    }
//
//    func observeRoomsChanged() {
//        m_roomChangedHandle = roomsRef.observe(DataEventType.childChanged) { (snapshot: DataSnapshot) in
//            self.delegateUserEnteredRoom?.userEnteredRoom()
//        }
//    }
//    
//    func observeRoomsAdded() {
//        m_roomAddedHandle = roomsRef.observe(DataEventType.childAdded) {(snapshot: DataSnapshot) in
//            
//            if let data = snapshot.value as? NSDictionary {
//                
//                if let roomName = data[Constants.ROOM_NAME] as? String {
//                    
//                    if let description = data[Constants.DESCRIPTION] as? String {
//                        
//                        if let password =  data[Constants.PASSWORD] as? String {
//                            
//                            if let likes = data[Constants.LIKES] as? Int {
//                                
//                                let id = snapshot.key as String
//                                let newRoom = Room(name: id, description: roomName, id: description, password: password, likes: likes)
//                                self.delegateRooms?.roomDataReceived(room: newRoom)
//                            }
//                        }
//                    }
//                }
//            }
//        }
//    }
    
}
