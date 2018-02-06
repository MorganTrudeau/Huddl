//
//  MessagesProvider.swift
//  Helloquent
//
//  Created by Morgan Trudeau on 2017-12-29.
//  Copyright © 2017 Morgan Trudeau. All rights reserved.
//

import Foundation
import FirebaseDatabase
import FirebaseStorage
import UIKit
import JSQMessagesViewController
import SDWebImage
import Cache

protocol MediaMessageDelegate: class {
    func messageReceived(message: JSQMessage)
    func mediaMessageReceived(message: JSQMessage, roomID: String, index: Int)
}

class MessagesProvider {
    
    private static let _instance = MessagesProvider()
    
    static var Instance: MessagesProvider {
        return _instance
    }
    
    let m_dbProvider = DBProvider.Instance
    let m_cacheStorage = CacheStorage.Instance
    
    weak var delegate: MediaMessageDelegate?
    
    typealias UserIDHandler = (_ messages: [JSQMessage]) -> Void
    
    /**
     Stores text or media message in Firebase database and messages cache
    **/
    
    func sendRoomMessage(senderID: String, senderName: String, text: String?, url: String?, roomID: String) {
        // Construct message data to be written to Firebase
        let data: Dictionary<String, Any> = [Constants.SENDER_ID: senderID, Constants.SENDER_NAME: senderName, Constants.TEXT: text ?? "", Constants.URL: url ?? ""]
        
        // Write message to Firebase
        // With completion so messgage cannot be cached offline
        m_dbProvider.roomMessagesRef.childByAutoId().setValue(data, withCompletionBlock: {(error, _) in
            if error == nil {
                var messages = [Message]()
                // Fetch cached messages from room to update
                if let cachedMessages = try? self.m_cacheStorage.m_messagesStorage.object(ofType: [Message].self, forKey: roomID) {
                    messages = cachedMessages
                }
                // Contruct codable message to cache
                let message = Message(senderID: senderID, senderName: senderName, text: text ?? "", url: url ?? "")
                messages.append(message)
                
                // Cache messages
                self.m_cacheStorage.cacheMessages(roomID: roomID, messages: messages)
            }
        })
    }
    
    /**
     Stores media in Firebase storage
     Images and videos cached with downloadURL as key
     Passes message data to saveMessage() to be saved in Firebase database
     **/
    
    func saveMedia(image: UIImage?, video: URL?, senderID: String, senderName: String, roomID: String) {
        // Create unique path for media
        let path = "\(NSUUID().uuidString)"
        
        // Check whether media is image or video
        if image != nil {
            // Compress image to data
            let data = UIImageJPEGRepresentation(image!, 0.5)
            
            // Store image in Firebase image storage
            m_dbProvider.imageStorageRef.child(path).putData(data!, metadata: nil) {(metadata, error) in
                guard error == nil else {
                    print("Error occured while saving data")
                    return
                }
                let metadataURL = String(describing: metadata!.downloadURL()!)
                
                // Store message in Firebase database and cache
                self.sendRoomMessage(senderID: senderID, senderName: senderName, text: nil, url: metadataURL, roomID: roomID)
                
                // Cache message image
                self.m_cacheStorage.cacheImage(id: metadataURL, image: image!)
            }
        } else {
            m_dbProvider.videoStorageRef.child(path).putFile(from: video!, metadata: nil) {(metadata, error) in
                guard error == nil else {
                    print("Error occured while saving data")
                    return
                }
                let metadataURL = String(describing: metadata!.downloadURL()!)
                
                // Store message in Firebase database and cache
                self.sendRoomMessage(senderID: senderID, senderName: senderName, text: nil, url: metadataURL, roomID: roomID)
                
                // Cache message video
                self.m_cacheStorage.cacheVideo(id: metadataURL, url: metadataURL)
            }
        }
    }
    
    /**
     Returns new messages added to database
     If new message is not message sent by current user
     message will be cached and media will be downloaded
    **/
    
    func observeRoomMessages() {
        var messages = [Message]()
        var firstObserve = true
        let roomID = m_dbProvider.m_currentRoomID!
        m_dbProvider.roomMessagesRef.queryLimited(toLast: 1).observe(DataEventType.value) { (snapshot: DataSnapshot) in
                if firstObserve {
                    firstObserve = false
                } else {
                    if let cachedMessages = try? self.m_cacheStorage.m_messagesStorage.object(ofType: [Message].self, forKey: roomID) {
                        messages = cachedMessages
                    }
                    for child in snapshot.children.allObjects as! [DataSnapshot] {
                        
                        if let messageData = child.value as? NSDictionary {
                            if let senderID = messageData[Constants.SENDER_ID] as? String {
                                if senderID != AuthProvider.Instance.userID() {
                                    if let senderName = messageData[Constants.SENDER_NAME] as? String {
                                        if let text = messageData[Constants.TEXT] as? String {
                                            if let url = messageData[Constants.URL] as? String {
                                                self.m_dbProvider.getUser(id: senderID, completion: {() in
                                                    if text != "" {
                                                        messages.append(Message(senderID: senderID, senderName: senderName, text: text, url: url))
                                                        let message = JSQMessage(senderId: senderID, displayName: senderName, text: text)
                                                        self.delegate?.messageReceived(message: message!)
                                                        self.m_cacheStorage.cacheMessages(roomID: roomID, messages: messages)
                                                    } else {
                                                        let placeHolderImage = JSQPhotoMediaItem(image: nil)
                                                        if senderID != AuthProvider.Instance.userID() {
                                                            placeHolderImage?.appliesMediaViewMaskAsOutgoing = false
                                                        }
                                                        let message = JSQMessage(senderId: senderID, displayName: senderName, media: placeHolderImage)
                                                        self.delegate?.messageReceived(message: message!)
                                                        messages.append(Message(senderID: senderID, senderName: senderName, text: text, url: url))
                                                        let index = messages.count - 1
                                                        self.loadMessageMedia(senderID: senderID, senderName: senderName, url: url, roomID: self.m_dbProvider.m_currentRoomID!, index: index, completion: {() in
                                                        self.m_cacheStorage.cacheMessages(roomID: roomID, messages: messages)
                                                        })
                                                    }
                                                })
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
        }
    }
    
    func removeRoomObservers() {
        m_dbProvider.roomMessagesRef.removeAllObservers()
    }
    
    /**
     Downloads messages from Firebase database
     Stores messages in messages cache with roomID as key
     Queues download of media from messages
     On completion passes dictionary of users who have posted so their information can be downloaded
    **/
    
    func getRoomMessages(roomID: String, completion: UserIDHandler?) {
        // JSQMessages to be passed to ChatVC to load new messages from Firebase
        var jsqMessages = [JSQMessage]()
        
        // Messages to be cached
        var messages = [Message]()
        
        // Variables to determine if there are new messages in Firebase compared to cache
        var cachedMessageCount = 0
        var newMessageCount = 0
        
        // Load cache to compare with Firebase
        if let cachedMessages = try? m_cacheStorage.m_messagesStorage.object(ofType: [Message].self, forKey: roomID) {
            messages = cachedMessages
            cachedMessageCount = cachedMessages.count
        }
        m_dbProvider.roomMessagesRef.observeSingleEvent(of: DataEventType.value, with: {(snapshot: DataSnapshot) in
            newMessageCount = Int(snapshot.childrenCount) - cachedMessageCount
            
            if newMessageCount > 0 {
                 self.m_dbProvider.roomMessagesRef.queryLimited(toLast: UInt(newMessageCount)).observeSingleEvent(of: .value, with: {(snapshot) in
                    
                    for child in snapshot.children.allObjects as! [DataSnapshot] {
                            if let messageData = child.value as? NSDictionary {
                            if let senderID = messageData[Constants.SENDER_ID] as? String {
                                if let senderName = messageData[Constants.SENDER_NAME] as? String {
                                    if let text = messageData[Constants.TEXT] as? String {
                                        if let url = messageData[Constants.URL] as? String {
                                            if text != "" {
                                                jsqMessages.append(JSQMessage(senderId: senderID, displayName: senderName, text: text))
                                                messages.append(Message(senderID: senderID, senderName: senderName, text: text, url: url))
                                            } else {
                                                let placeHolderImage = JSQPhotoMediaItem.init(image: nil)
                                                if senderID != AuthProvider.Instance.userID() {
                                                    placeHolderImage?.appliesMediaViewMaskAsOutgoing = false
                                                }
                                                jsqMessages.append(JSQMessage(senderId: senderID, displayName: senderName, media: placeHolderImage))
                                                messages.append(Message(senderID: senderID, senderName: senderName, text: text, url: url))
                                                let index = messages.count - 1
                                                DispatchQueue.global().async {
                                                    self.loadMessageMedia(senderID: senderID, senderName: senderName, url: url, roomID: self.m_dbProvider.m_currentRoomID!, index: index, completion: nil)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    completion?(jsqMessages)
                    self.m_cacheStorage.cacheMessages(roomID: roomID, messages: messages)
                })
            }
        })
    }
    
    /**
     Downloads media queued from getRoomMessages and observeRoomMessages
     Stores images in images cache with downloadURL as key
    **/
    
    func loadMessageMedia(senderID: String, senderName: String, url: String, roomID: String, index: Int, completion: DefaultClosure?) {
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
                                    let photo = JSQPhotoMediaItem(image: image)
                                    if senderID != AuthProvider.Instance.userID() {
                                        photo?.appliesMediaViewMaskAsOutgoing = false
                                    }
                                    let message = JSQMessage(senderId: senderID, displayName: senderName, media: photo)
                                    self.delegate?.mediaMessageReceived(message: message!, roomID: roomID, index: index)
                                    print("Image downloaded with url: \(url)")
                                    completion?()
                                }
                            })
                        } else {
                            self.m_cacheStorage.cacheVideo(id: url, url: url)
                            let video = JSQVideoMediaItem(fileURL: mediaURL, isReadyToPlay: true)
                            if senderID != AuthProvider.Instance.userID() {
                                video?.appliesMediaViewMaskAsOutgoing = false
                            }
                            let message = JSQMessage(senderId: senderID, displayName: senderName, media: video)
                            self.delegate?.mediaMessageReceived(message: message!, roomID: roomID, index: index)
                            completion?()
                        }
                    } catch {
                        print("Error downloading Message Media Data")
                    }
                }
            
        }
    }
    
}
