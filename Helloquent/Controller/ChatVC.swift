//
//  ChatVC.swift
//  Helloquent
//
//  Created by Morgan Trudeau on 2017-12-22.
//  Copyright © 2017 Morgan Trudeau. All rights reserved.
//

import UIKit
import JSQMessagesViewController
import MobileCoreServices
import AVKit

class ChatVC: JSQMessagesViewController, MessageReceivedDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, FetchColorData, ActiveUsersDecreased {
    
    var messages = [JSQMessage]()
    var messageColors = [String]()
    
    var currentChatRoomID: String?
    var currentChatRoomName: String?
    var currentUserColor: String?
    var goingBack = false
    var shouldScrollToLastRow = true
    
    let picker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(ChatVC.handleResignActive), name: NSNotification.Name(rawValue: "ResignActiveNotification"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ChatVC.handleBecomeActive), name: NSNotification.Name(rawValue: "BecomeActiveNotification"), object: nil)
        
        DBProvider.Instance.delegateColor = self
        DBProvider.Instance.delegateActiveUsersDecreased = self
        DBProvider.Instance.currentUserColor()
        
        self.senderId = AuthProvider.Instance.userID()
        self.senderDisplayName = AuthProvider.Instance.currentUserName()

        MessagesHandler.Instance.delegateMessage = self
        MessagesHandler.Instance.observeChatRoomMessges()
        
        setUpUI()
        shouldScrollToLastRow = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        DBProvider.Instance.increaseActiveUsers()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.layoutIfNeeded()
        if (shouldScrollToLastRow)
        {
            shouldScrollToLastRow = false;
            let bottomOffset = CGPoint(x: 0, y: self.collectionView.contentSize.height)
            self.collectionView.setContentOffset(bottomOffset, animated: true)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        if !goingBack {
            DBProvider.Instance.decreaseActiveUsers()
        }
        MessagesHandler.Instance.removeChatRoomObservers()
    }
    
    @objc func handleResignActive() {
        DBProvider.Instance.decreaseActiveUsers()
    }
    
    @objc func handleBecomeActive() {
        DBProvider.Instance.increaseActiveUsers()
    }
    
    func setUpUI() {
        self.collectionView.backgroundColor = UIColor.init(white: 0.4, alpha: 1)
        self.navigationItem.title = currentChatRoomName;
        self.navigationItem.hidesBackButton = true
        let newBackButton = UIBarButtonItem(title: "Back", style: UIBarButtonItemStyle.plain, target: self, action: #selector(ChatVC.back(sender:)))
        self.navigationItem.leftBarButtonItem = newBackButton
    }

    // Collection view functions

    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        return JSQMessagesAvatarImageFactory.avatarImage(with: UIImage(named: "avatar.gif"), diameter: 30)
    }

    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let bubbleFactory = JSQMessagesBubbleImageFactory()
        let message = messages[indexPath.item]
        let messageColor = ColorHandler.Instance.convertToUIColor(colorString: messageColors[indexPath.row])
        if message.senderId == AuthProvider.Instance.userID() {
            return bubbleFactory?.outgoingMessagesBubbleImage(with: messageColor)
        } else {
            return bubbleFactory?.incomingMessagesBubbleImage(with: messageColor)
        }
    }

    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        cell.messageBubbleTopLabel.textColor = UIColor.init(white: 0.9, alpha: 1)
        return cell
        
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForMessageBubbleTopLabelAt indexPath: IndexPath!) -> NSAttributedString!
    {
        let message = messages[indexPath.item]
        
        if message.senderId == senderId {
            return nil
        } else {
            guard let senderDisplayName = message.senderDisplayName else {
                assertionFailure()
                return nil
            }
            return NSAttributedString(string: senderDisplayName)
            
        }
        
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleTopLabelAt indexPath: IndexPath!) -> CGFloat
    {
        return 17.0
    }
    
    // Sending buttons functions
    
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        MessagesHandler.Instance.sendChatRoomMessage(senderID: senderId, senderName: senderDisplayName, text: text, chatRoomID: currentChatRoomID!, color: currentUserColor!)
        
        // Removes text from text field
        finishSendingMessage()
    }
    
    override func didPressAccessoryButton(_ sender: UIButton!) {
        let alert = UIAlertController(title: "Media Messages", message: "Please select a media", preferredStyle: .actionSheet)
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let photos = UIAlertAction(title: "Photos", style: .default, handler: {(alert: UIAlertAction) in
            self.chooseMedia(type: kUTTypeImage)
        })
        let videos = UIAlertAction(title: "Videos", style: .default, handler: {(alert: UIAlertAction) in
            self.chooseMedia(type: kUTTypeMovie)
        })
        alert.popoverPresentationController?.sourceView = sender
        alert.popoverPresentationController?.sourceRect = sender.bounds
        alert.addAction(photos)
        alert.addAction(videos)
        alert.addAction(cancel)
        present(alert, animated: true, completion: nil)
    }
    
    // Picker view fucntions
    
    private func chooseMedia(type: CFString) {
        picker.mediaTypes = [type as String]
        present(picker, animated: true, completion: nil)
    }
    
    // Delegation functions
    
    func messageReceived(senderID: String, senderName: String, text: String, color: String) {
        messages.append(JSQMessage(senderId: senderID, displayName: senderName, text: text))
        messageColors.append(color)
        collectionView.reloadData()
        scrollToBottom(animated: false)
    }
    
    func colorDataReceived(color: String) {
        currentUserColor = color
    }
    
    @objc func back(sender: UIBarButtonItem) {
        goingBack = true
        DBProvider.Instance.decreaseActiveUsersWithCallback()
    }
    
    func activeUsersDecreased() {
        _ = navigationController?.popViewController(animated: true)
    }
    
    
    

    
    
    

    
    
    
    
    
    
    
    
    
    
    
    
    

}
