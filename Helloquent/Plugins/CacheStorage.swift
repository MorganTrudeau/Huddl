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
    
    /**
     User Storage
    **/

    lazy var m_userStorage: Storage = {
        let diskConfig = DiskConfig(name: "UserCache")
        let memoryConfig = MemoryConfig(expiry: .never, countLimit: 10, totalCostLimit: 10)
        let storage = try! Storage(diskConfig: diskConfig, memoryConfig: memoryConfig)
        return storage
    }()
    
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
    
    lazy var m_mediaStorage: Storage = {
        let diskConfig = DiskConfig(name: "MediaCache")
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
            try m_mediaStorage.setObject(wrappedImage, forKey: id)
            delegate?.cacheUpdated()
            print("Cached image with key: \(id)")
        } catch {
            print("Image cache error: \(error)")
        }
    }
    
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
    
    lazy var m_roomStorage: Storage = {
        let diskConfig = DiskConfig(name: "RoomCache")
        let memoryConfig = MemoryConfig(expiry: .never, countLimit: 10, totalCostLimit: 10)
        let storage = try! Storage(diskConfig: diskConfig, memoryConfig: memoryConfig)
        return storage
    }()
    
    func cacheRooms(type: String, rooms: [Room]) {
        do {
            try m_roomStorage.setObject(rooms, forKey: type)
            print("Cache rooms with type: \(type)")
        } catch {
            print("Room cache error: \(error)")
        }
    }
    
    
    
    /**
     Message Storage
    **/
    
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
                completion?(jsqMessages)
            case .error(let error):
                print("Fetch messages error: \(error)")
            }
        })
    }
}

