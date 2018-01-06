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

protocol MessageReceivedDelegate: class {
    func messageReceived(senderID: String, senderName: String, text: String, color: String)
}

class MessagesHandler {
    private static let _instance = MessagesHandler()
    private init() {}
    
    weak var delegate: MessageReceivedDelegate?
    
    static var Instance: MessagesHandler {
        return _instance
    }
    
    func sendChatRoomMessage(senderID: String, senderName: String, text: String, chatRoomName: String, color: String) {
        let data: Dictionary<String, Any> = [Constants.SENDER_ID: senderID, Constants.SENDER_NAME: senderName, Constants.TEXT: text, Constants.COLOR: color]
        DBProvider.Instance.currentRoomName = chatRoomName
    DBProvider.Instance.chatRoomMessagesRef.childByAutoId().setValue(data)
        
    }
    
    func observeChatRoomMessges() {
    DBProvider.Instance.chatRoomMessagesRef.observe(DataEventType.childAdded) { (snapshot: DataSnapshot) in
            if let data = snapshot.value as? NSDictionary {
                if let senderID = data[Constants.SENDER_ID] as? String {
                    if let senderName = data[Constants.SENDER_NAME] as? String {
                        if let text = data[Constants.TEXT] as? String {
                            if let color = data[Constants.COLOR] as? String {
                                self.delegate?.messageReceived(senderID: senderID, senderName:senderName, text: text, color: color)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func removeChatRoomObservers() {
        DBProvider.Instance.chatRoomMessagesRef.removeAllObservers()
    }
    
//    func sendPersonalChatMessage(senderID: String, senderName: String, text: String, selectedContactID: String) {
//        let data: Dictionary<String, Any> = [Constants.SENDER_ID: senderID, Constants.SENDER_NAME: senderName, Constants.TEXT: text]
//        DBProvider.Instance.selectedContactID = selectedContactID
//        DBProvider.Instance.personalChatMessagesRef.childByAutoId().setValue(data)
//        
//    }
    
//    func observePersonalChatMessges() {
//        DBProvider.Instance.personalChatMessagesRef.observe(DataEventType.childAdded) { (snapshot: DataSnapshot) in
//            if let data = snapshot.value as? NSDictionary {
//                if let senderID = data[Constants.SENDER_ID] as? String {
//                    if let senderName = data[Constants.SENDER_NAME] as? String {
//                        if let text = data[Constants.TEXT] as? String {
//                            self.delegate?.messageReceived(senderID: senderID, senderName:senderName, text: text)
//                        }
//                    }
//                }
//            }
//        }
//    }
//
//    func removePersonalChatObservers() {
//        DBProvider.Instance.personalChatMessagesRef.removeAllObservers()
//    }
    
    
    
    
    
    
    
    
}
