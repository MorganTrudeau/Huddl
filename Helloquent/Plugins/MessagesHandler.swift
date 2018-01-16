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

protocol MessageReceivedDelegate: class {
    func messageReceived(senderID: String, senderName: String, text: String, color: String)
    func allMessagesReceived(messages: [JSQMessage], messageColors: [String])
}

class MessagesHandler {
    private static let _instance = MessagesHandler()
    private init() {}
    
    weak var delegateMessage: MessageReceivedDelegate?
    
    static var Instance: MessagesHandler {
        return _instance
    }
    
    func sendChatRoomMessage(senderID: String, senderName: String, text: String, chatRoomID: String, color: String) {
        let data: Dictionary<String, Any> = [Constants.SENDER_ID: senderID, Constants.SENDER_NAME: senderName, Constants.TEXT: text, Constants.COLOR: color]
        DBProvider.Instance.currentRoomID = chatRoomID
    DBProvider.Instance.chatRoomMessagesRef.childByAutoId().setValue(data)
    }
    
    func observeChatRoomMessges() {
        var firstObserve = true
        DBProvider.Instance.chatRoomMessagesRef.queryLimited(toLast: 1).observe(DataEventType.value) { (snapshot: DataSnapshot) in
            if firstObserve {
                firstObserve = false
            } else {
                if let message = snapshot.value as? NSDictionary {
                    for (_, value) in message {
                        if let messageData = value as? NSDictionary{
                            if let senderID = messageData[Constants.SENDER_ID] as? String {
                                if let senderName = messageData[Constants.SENDER_NAME] as? String {
                                    if let text = messageData[Constants.TEXT] as? String {
                                        if let color = messageData[Constants.COLOR] as? String {
                                            self.delegateMessage?.messageReceived(senderID: senderID, senderName:senderName, text: text, color: color)
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
    
    func removeChatRoomObservers() {
        DBProvider.Instance.chatRoomMessagesRef.removeAllObservers()
    }
    
    func getChatRoomMessages() {
        var messages = [JSQMessage]()
        var messageColors = [String]()
        
        DBProvider.Instance.chatRoomMessagesRef.observeSingleEvent(of: DataEventType.value, with: {(snapshot: DataSnapshot) in
            
            for child in snapshot.children.allObjects as! [DataSnapshot] {
                if let messageData = child.value as? NSDictionary {
                    if let senderID = messageData[Constants.SENDER_ID] as? String {
                        if let senderName = messageData[Constants.SENDER_NAME] as? String {
                            if let text = messageData[Constants.TEXT] as? String {
                                if let color = messageData[Constants.COLOR] as? String {
                                    messages.append(JSQMessage(senderId: senderID, displayName: senderName, text: text))
                                    messageColors.append(color)
                                }
                            }
                        }
                    }
                }
            }
            self.delegateMessage?.allMessagesReceived(messages: messages, messageColors: messageColors)
        })
    }

    
}
