//
//  MessagesHandler.swift
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

protocol MessageReceivedDelegate: class {
    func messageReceived(message: JSQMessage)
    func allMessagesReceived(messages: [JSQMessage], userIDs: [String:Bool])
    func mediaMessageReceived(message: JSQMessage, forIndex: Int)
}

class MessagesHandler {
    private static let _instance = MessagesHandler()
    private init() {}
    
    weak var delegateMessage: MessageReceivedDelegate?
    
    static var Instance: MessagesHandler {
        return _instance
    }
    
    let m_dbProvider = DBProvider.Instance
    let m_cacheStorage = CacheStorage.Instance
    
    func sendRoomMessage(senderID: String, senderName: String, text: String?, url: String?, roomID: String) {
        let data: Dictionary<String, Any> = [Constants.SENDER_ID: senderID, Constants.SENDER_NAME: senderName, Constants.TEXT: text ?? "", Constants.URL: url ?? ""]
        m_dbProvider.m_currentRoomID = roomID
        m_dbProvider.roomMessagesRef.childByAutoId().setValue(data)
    }
    
    func saveMedia(image: Data?, video: URL?, senderID: String, senderName: String, roomID: String) {
        let path = "\(NSUUID().uuidString)"
        if image != nil {
            m_dbProvider.imageStorageRef.child(path).putData(image!, metadata: nil) {(metadata, error) in
                guard error == nil else {
                    print("Error occured while saving data")
                    return
                }
                let metadataURL = String(describing: metadata!.downloadURL()!)
                self.sendRoomMessage(senderID: senderID, senderName: senderName, text: nil, url: metadataURL, roomID: roomID)
            }
        } else {
            m_dbProvider.videoStorageRef.child(path).putFile(from: video!, metadata: nil) {(metadata, error) in
                guard error == nil else {
                    print("Error occured while saving data")
                    return
                }
                let metadataURL = String(describing: metadata!.downloadURL()!)
                self.sendRoomMessage(senderID: senderID, senderName: senderName, text: nil, url: metadataURL, roomID: roomID)
            }
        }
    }
    
    func observeRoomMessages() {
        var firstObserve = true
        m_dbProvider.roomMessagesRef.queryLimited(toLast: 1).observe(DataEventType.value) { (snapshot: DataSnapshot) in
            if firstObserve {
                firstObserve = false
            } else {
                if let data = snapshot.value as? NSDictionary {
                    
                    for (_, value) in data {
                        
                        if let messageData = value as? NSDictionary{
                            
                            if let text = messageData[Constants.TEXT] as? String {
                                
                                guard text != "" else {
                                    return
                                }
                            
                                if let senderID = messageData[Constants.SENDER_ID] as? String {
                               
                                    if let senderName = messageData[Constants.SENDER_NAME] as? String {
                                            
                                        let message = JSQMessage(senderId: senderID, displayName: senderName, text: text)
                                        self.delegateMessage?.messageReceived(message: message!)
                                        
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
    
    func getRoomMessages() {
        var messages = [JSQMessage]()
        var userIDs = [String:Bool]()
        
        m_dbProvider.roomMessagesRef.observeSingleEvent(of: DataEventType.value, with: {(snapshot: DataSnapshot) in
            
            for child in snapshot.children.allObjects as! [DataSnapshot] {
                if let messageData = child.value as? NSDictionary {
                    if let senderID = messageData[Constants.SENDER_ID] as? String {
                        if let senderName = messageData[Constants.SENDER_NAME] as? String {
                            if let text = messageData[Constants.TEXT] as? String {
                                if let url = messageData[Constants.URL] as? String {
                                    if text != "" {
                                        messages.append(JSQMessage(senderId: senderID, displayName: senderName, text: text))
                                        userIDs[senderID] = true
                                    } else {
                                        let placeHolderImage = JSQPhotoMediaItem.init(image: nil)
                                        if senderID != AuthProvider.Instance.userID() {
                                            placeHolderImage?.appliesMediaViewMaskAsOutgoing = false
                                        }
                                        messages.append(JSQMessage(senderId: senderID, displayName: senderName, media: placeHolderImage))
                                        userIDs[senderID] = true
                                        let index = messages.count - 1
                                        DispatchQueue.global().async {
                                            self.loadMessageMedia(senderID: senderID, senderName: senderName, url: url, index: index)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            self.delegateMessage?.allMessagesReceived(messages: messages, userIDs: userIDs)
        })
    }
    
    func loadMessageMedia(senderID: String, senderName: String, url: String, index: Int) {
        if let mediaURL = URL(string: url) {
            do {
                let data = try Data(contentsOf: mediaURL)
                if let _ = UIImage(data: data) {
                    let _ = SDWebImageDownloader.shared().downloadImage(with: mediaURL, options: [], progress: nil, completed: {(image, data, error, finished) in
                        
                            if error != nil {
                                print("Image download error: \(String(describing: error!))")
                            } else {
                                let photo = JSQPhotoMediaItem(image: image)
                                if senderID != AuthProvider.Instance.userID() {
                                    photo?.appliesMediaViewMaskAsOutgoing = false
                                }
                                let message = JSQMessage(senderId: senderID, displayName: senderName, media: photo)
                                DispatchQueue.main.async {
                                    self.delegateMessage?.mediaMessageReceived(message: message!, forIndex: index)
                                }
                            }
                        })
                } else {
                    let video = JSQVideoMediaItem(fileURL: mediaURL, isReadyToPlay: true)
                    if senderID != AuthProvider.Instance.userID() {
                        video?.appliesMediaViewMaskAsOutgoing = false
                    }
                    let message = JSQMessage(senderId: senderID, displayName: senderName, media: video)
                    DispatchQueue.main.async {
                        self.delegateMessage?.mediaMessageReceived(message: message!, forIndex: index)
                    }
                }
            } catch {
                print("Error downloading Data")
            }
        }
    }

    
}
