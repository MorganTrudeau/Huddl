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
typealias UserHandler = (_ user: User) -> Void
typealias ImageHandler = (_ image: UIImage) -> Void
typealias MessagesHandler = (_ messages: [JSQMessage]) -> Void

protocol CacheDelegate: class {
    func cacheUpdated()
}

class CacheStorage {
    
    private static let _instance = CacheStorage()
    
    static var Instance: CacheStorage {
        return _instance
    }
    
    weak var delegate: CacheDelegate?
    
    // User Storage

    lazy var m_userStorage: Storage = {
        let diskConfig = DiskConfig(name: "UserCache")
        let memoryConfig = MemoryConfig(expiry: .never, countLimit: 10, totalCostLimit: 10)
        let storage = try! Storage(diskConfig: diskConfig, memoryConfig: memoryConfig)
        return storage
    }()
    
    func cacheUsers(users: [String:User]) {
        do{
            try m_userStorage.setObject(users, forKey: "users")
        } catch {
            print(error)
        }
    }
    
    func cacheUser(user: User) {
        do{
            try m_userStorage.setObject(user, forKey: user.id)
            print("Cached user: \(user.id), \(user.name)")
            delegate?.cacheUpdated()
        } catch {
            print("User cache error: \(error)")
        }
    }
    
    func fetchAllUsers(completion: AllUsersHandler?) {
        m_userStorage.async.object(ofType: [String:User].self, forKey: "users", completion: {(result) in
            switch result {
            case .value(let users):
                print(users)
                completion?(users)
            case .error(let error):
                print(error)
            }
        })
    }
    
    func fetchUser(id: String, completion: UserHandler?) {
        m_userStorage.async.object(ofType: User.self, forKey: id, completion: {(result) in
            switch result {
            case .value(let user):
                print(user)
                completion?(user)
            case .error(let error):
                print(error)
            }
        })
    }
    
    // Image Storage
    
    lazy var m_imageStorage: Storage = {
        let diskConfig = DiskConfig(name: "ImageCache")
        let memoryConfig = MemoryConfig(expiry: .never, countLimit: 10, totalCostLimit: 10)
        let storage = try! Storage(diskConfig: diskConfig, memoryConfig: memoryConfig)
        return storage
    }()
    
    func wrapImage(image: UIImage) -> ImageWrapper {
        let wrappedImage = ImageWrapper(image: image)
        return wrappedImage
    }
    
    func cacheImage(id: String, image: UIImage) {
        let wrappedImage = wrapImage(image: image)
        do{
            try m_imageStorage.setObject(wrappedImage, forKey: id)
            delegate?.cacheUpdated()
            print("Cached image with key: \(id)")
        } catch {
            print("Image cache error: \(error)")
        }
    }
    
    func fetchImageData(id: String, completion: ImageHandler?) {
        m_imageStorage.async.object(ofType: ImageWrapper.self, forKey: id, completion: {(result) in
            print("Fetching Image with key: \(id)")
            switch result {
            case .value(let wrappedImage):
                let image = wrappedImage.image as UIImage
                completion?(image)
            case .error(let error):
                print("Image fetch error: \(error)")
            }
        })
    }
    
    // Room Storage
    
    lazy var m_roomStorage: Storage = {
        let diskConfig = DiskConfig(name: "RoomCache")
        let memoryConfig = MemoryConfig(expiry: .never, countLimit: 10, totalCostLimit: 10)
        let storage = try! Storage(diskConfig: diskConfig, memoryConfig: memoryConfig)
        return storage
    }()
    
    func cacheRoom(roomID: String, room: Room) {
        do {
            try m_roomStorage.setObject(room, forKey: roomID)
        } catch {
            print("Room cache error: \(error)")
        }
    }
    
    // Message Storage
    
    lazy var m_messagesStorage: Storage = {
        let diskConfig = DiskConfig(name: "MessageCache")
        let memoryConfig = MemoryConfig(expiry: .never, countLimit: 10, totalCostLimit: 10)
        let storage = try! Storage(diskConfig: diskConfig, memoryConfig: memoryConfig)
        return storage
    }()
    
    func cacheMessages(roomID: String, messages: [Message]) {
        do {
            try m_messagesStorage.setObject(messages, forKey: roomID)
            print("Cached messages for rooom: \(roomID)")
        } catch {
            print("Messages cache error: \(error)")
        }
    }
    
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
                        let image = try? self.m_imageStorage.object(ofType: ImageWrapper.self, forKey: message.url).image
                        let messageImage = JSQPhotoMediaItem(image: image)
                        let jsqMessage = JSQMessage(senderId: message.senderName, displayName: message.senderName, media: messageImage)
                        jsqMessages.append(jsqMessage!)
                    }
                }
                completion?(jsqMessages)
            case .error(let error):
                print("Fetch messages error: \(error)")
            }
        })
    }

}

