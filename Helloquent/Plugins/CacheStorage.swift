//
//  CacheStorage.swift
//  Helloquent
//
//  Created by Morgan Trudeau on 2018-02-01.
//  Copyright © 2018 Morgan Trudeau. All rights reserved.
//

import Foundation
import Cache
import JSQMessagesViewController

typealias AllUsersHandler = (_ users: [String:User]) -> Void
typealias ImageHandler = (_ image: UIImage) -> Void
typealias MessagesHandler = (_ messages: [JSQMessage]) -> Void

protocol ImageCacheDelegate: class {
    func imageCacheUpdated()
}

protocol NotificationCacheDelegate: class {
    func notificationReceived()
}

class CacheStorage {
    
    private static let _instance = CacheStorage()
    
    static var Instance: CacheStorage {
        return _instance
    }
    
    weak var imageCacheDelegate: ImageCacheDelegate?
    weak var notificationCacheDelegate: NotificationCacheDelegate?
    
    /**
     User Storage
    **/
    
    // Storage handling cache of users
    lazy var m_userStorage: Storage = {
        let diskConfig = DiskConfig(name: "UserCache")
        let memoryConfig = MemoryConfig(expiry: .never, countLimit: 10, totalCostLimit: 10)
        let storage = try! Storage(diskConfig: diskConfig, memoryConfig: memoryConfig)
        return storage
    }()
    
    // Caches user
    // User ID as key
    func cacheUser(user: User) {
        do{
            try m_userStorage.setObject(user, forKey: user.id)
            print("Cached user: \(user.id), \(user.name)")
        } catch {
            print("User cache error: \(error)")
        }
    }
    
    /**
     Image Storage
    **/
    
    // Storage handling cache of images/ videos
    lazy var m_mediaStorage: Storage = {
        let diskConfig = DiskConfig(name: "MediaCache")
        let memoryConfig = MemoryConfig(expiry: .never, countLimit: 10, totalCostLimit: 10)
        let storage = try! Storage(diskConfig: diskConfig, memoryConfig: memoryConfig)
        return storage
    }()
    
    // Converts image to cachable type ImageWrapper
    func wrapImage(image: UIImage) -> ImageWrapper {
        let wrappedImage = ImageWrapper(image: image)
        return wrappedImage
    }
    
    // Caches image
    // URL as key
    func cacheImage(id: String, image: UIImage) {
        let wrappedImage = wrapImage(image: image)
        do{
            try m_mediaStorage.setObject(wrappedImage, forKey: id)
            imageCacheDelegate?.imageCacheUpdated()
            print("Cached image with key: \(id)")
        } catch {
            print("Image cache error: \(error)")
        }
    }
    
    // Caches video
    // URL as key
    func cacheVideo(id: String, url: String) {
        do {
            try m_mediaStorage.setObject(url, forKey: url)
            print("Cache video with key: \(url)")
        } catch {
            print("Video cache error: \(error)")
        }
    }
    
    /**
     Room Storage
    **/
    
    // Storage handling cache of rooms for savedRooms/userRooms listViews, Tabbar badges, and room/chat notifications on tableview cells
    lazy var m_roomStorage: Storage = {
        let diskConfig = DiskConfig(name: "RoomCache")
        let memoryConfig = MemoryConfig(expiry: .never, countLimit: 10, totalCostLimit: 10)
        let storage = try! Storage(diskConfig: diskConfig, memoryConfig: memoryConfig)
        return storage
    }()
    
    // Caches arrays of Room objects
    // "saved"/"user" as key
    // Use to load data for savedRoomsTableView and userRoomsTableView
    func cacheRooms(type: String, rooms: [Room]) {
        do {
            try m_roomStorage.setObject(rooms, forKey: type)
            print("Cache rooms with type: \(type)")
        } catch {
            print("Room cache error: \(error)")
        }
    }
    
    // Caches array of IDs representing individual rooms or chats that have unread messages
    // "chat" or "room" as key
    // Loaded at app start to apply badges to tab bar
    // Called everytime a push notification is received while app is active AND if target room or chat doesn't doesnt already have unread messages
    func cacheTabNotifications(notifications: [String], type: String) {
        do{
            try m_roomStorage.setObject(notifications, forKey: type)
        } catch {
            print("Cache tab notification error: \(error)")
        }
    }
    
    // Caches number of unread notifications for either a room or chat
    // Room or chat ID as key
    // Called everytime a push notification is received while app is active
    func increaseCellNotifications(id: String) {
        var roomNotifications = 1
        if let currentRoomNotifications = try? m_roomStorage.object(ofType: Int.self, forKey: id) {
            roomNotifications = currentRoomNotifications + 1
        }
        do {
            try m_roomStorage.setObject(roomNotifications, forKey: id)
            self.notificationCacheDelegate?.notificationReceived()
        } catch {
            print("Room notification error: \(error)")
        }
        
    }
    
    /**
     Message Storage
    **/
    
    // Storage handling cache of messages
    lazy var m_messagesStorage: Storage = {
        let diskConfig = DiskConfig(name: "MessageCache")
        let memoryConfig = MemoryConfig(expiry: .never, countLimit: 10, totalCostLimit: 10)
        let storage = try! Storage(diskConfig: diskConfig, memoryConfig: memoryConfig)
        return storage
    }()
    
    // Caches array of messages for ChatVC and PersonalChatVC
    // RoomID/ChatID as key
    func cacheMessages(id: String, messages: [Message]) {
        do {
            try m_messagesStorage.setObject(messages, forKey: id)
            print("Cached messages for rooom: \(id)")
        } catch {
            print("Messages cache error: \(error)")
        }
    }
    
    // Retrieves messages for room/chat
    // Converts to JSQMessage array and returns
    func fetchMessages(roomID: String, completion: MessagesHandler?) {
        var jsqMessages = [JSQMessage]()
        m_messagesStorage.async.object(ofType: [Message].self, forKey: roomID, completion: {(result) in
            switch result {
            case .value(let messages):
                for message in messages {
                    if message.text != "" {
                        let jsqMessage = JSQMessage(senderId: message.senderID, displayName: message.senderName, text: message.text)
                        jsqMessages.append(jsqMessage!)
                    } else {
                        if let image = try? self.m_mediaStorage.object(ofType: ImageWrapper.self, forKey: message.url).image {
                            let messageMedia = JSQPhotoMediaItem(image: image)
                            if message.senderID != AuthProvider.Instance.userID() {
                                messageMedia?.appliesMediaViewMaskAsOutgoing = false
                            }
                            let jsqMessage = JSQMessage(senderId: message.senderID, displayName: message.senderName, media: messageMedia)
                            jsqMessages.append(jsqMessage!)
                        } else {
                            let url = try? self.m_mediaStorage.object(ofType: String.self, forKey: message.url)
                            let video = URL(string: url!)
                            let messageMedia = JSQVideoMediaItem(fileURL: video, isReadyToPlay: true)
                            if message.senderID != AuthProvider.Instance.userID() {
                                messageMedia?.appliesMediaViewMaskAsOutgoing = false
                            }
                            let jsqMessage = JSQMessage(senderId: message.senderID, displayName: message.senderName, media: messageMedia)
                            jsqMessages.append(jsqMessage!)
                        }
                    }
                }
                DispatchQueue.main.async {
                    completion?(jsqMessages)
                }
            case .error(let error):
                print("Fetch messages error: \(error)")
            }
        })
    }
}

