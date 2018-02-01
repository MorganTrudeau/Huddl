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

class ChatVC: JSQMessagesViewController, MessageReceivedDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPickerViewDelegate {
    
    var m_saveRoomButton: UIBarButtonItem?
    
    let m_coreDataProvider = CoreDataProvider.Instance
    let m_messagesHandler = MessagesHandler.Instance
    let m_dbProvider = DBProvider.Instance
    let m_authProvider = AuthProvider.Instance
    
    var m_messages = [JSQMessage]()
    var m_messageColors = [String]()
    
    var m_isRoomSaved = false
    var m_currentRoomID: String?
    var m_currentRoomName: String?
    var m_currentUserColor: String?
    var m_currentUserAvatar: UIImage?
    
    let m_picker = UIImagePickerController()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        m_messagesHandler.delegateMessage = self
        m_messagesHandler.getRoomMessages()
        
        NotificationCenter.default.addObserver(self, selector: #selector(ChatVC.handleResignActive), name: NSNotification.Name(rawValue: "ResignActiveNotification"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ChatVC.handleBecomeActive), name: NSNotification.Name(rawValue: "BecomeActiveNotification"), object: nil)
        
        m_currentUserColor = m_authProvider.currentUser?.color
        m_currentUserAvatar = m_authProvider.currentUser?.avatar
        
        self.senderId = m_authProvider.userID()
        self.senderDisplayName = m_authProvider.currentUserName()
        
        m_picker.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(ChatVC.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ChatVC.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        setUpUI()
    }
    
    func setUpUI() {
        self.collectionView.backgroundColor = UIColor.init(white: 0.4, alpha: 1)
        
        // Create Heart button to save room
        m_saveRoomButton = UIBarButtonItem(image: UIImage(named: "heart"), style: .plain, target: self, action: #selector(ChatVC.saveRoomButtonClicked))
        
        self.navigationItem.rightBarButtonItem  = m_saveRoomButton
        self.navigationItem.title = m_currentRoomName;
        
        self.view.layoutIfNeeded()
        self.collectionView.layoutIfNeeded()
        if self.collectionView.contentSize.height > self.collectionView.frame.size.height {
            scrollToBottom(animated: false)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Receives new messages add to database
        m_messagesHandler.observeRoomMessages()
        
        // Fetch core data to check if current room is saved
        m_coreDataProvider.fetchRoomCoreData(coreRoomDataReceived: {(_) in
            self.m_isRoomSaved = self.m_coreDataProvider.isCurrentRoomSaved(currentRoomID: self.m_currentRoomID!)
            if !self.m_isRoomSaved {
                self.m_saveRoomButton?.tintColor = UIColor.gray
            } else {
                self.m_saveRoomButton?.tintColor = UIColor(red: 133/255, green: 51/255, blue: 1, alpha: 1)
            }
        })
            
        self.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        m_dbProvider.increaseActiveUsers()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        m_messagesHandler.removeRoomObservers()
        self.tabBarController?.tabBar.isHidden = false
        m_messagesHandler.delegateMessage = nil
    }
    
    @objc func handleResignActive() {
        m_dbProvider.decreaseActiveUsers(completion: nil)
    }
    
    @objc func handleBecomeActive() {
        m_dbProvider.increaseActiveUsers()
    }
    
    /**
        Keyboard Functions
    **/
    
    @objc func keyboardWillShow(notification: NSNotification) {
        self.topContentAdditionalInset = -65
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
    }

    /**
        CollectionView Functions
    **/

    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        return JSQMessagesAvatarImageFactory.avatarImage(with: m_currentUserAvatar, diameter: 30)
    }

    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let bubbleFactory = JSQMessagesBubbleImageFactory()
        let message = m_messages[indexPath.item]
        let messageColor = ColorHandler.Instance.convertToUIColor(colorString: m_messageColors[indexPath.row])
        if message.senderId == m_authProvider.currentUser?.id {
            return bubbleFactory?.outgoingMessagesBubbleImage(with: messageColor)
        } else {
            return bubbleFactory?.incomingMessagesBubbleImage(with: messageColor)
        }
    }

    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return m_messages[indexPath.item]
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return m_messages.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        cell.messageBubbleTopLabel.textColor = UIColor.init(white: 0.9, alpha: 1)
        return cell
        
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForMessageBubbleTopLabelAt indexPath: IndexPath!) -> NSAttributedString!
    {
        let message = m_messages[indexPath.item]
        
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
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapMessageBubbleAt indexPath: IndexPath!) {
        
        if m_messages[indexPath.row].isMediaMessage {
            
            if let media = m_messages[indexPath.row].media as? JSQVideoMediaItem {
                
                let videoURL = media.fileURL
                
                let player = AVPlayer.init(url: videoURL!)
                let playerViewController = AVPlayerViewController.init()
                playerViewController.player = player
                self.present(playerViewController, animated: true, completion: nil)
                
            } else if let media = m_messages[indexPath.row].media as? JSQPhotoMediaItem {
                
                let image: UIImage? = media.image
                if image != nil {
                    let imageDisplay = ImageDisplayVC.Instance
                    imageDisplay.setImage(image: image!)
                    imageDisplay.setView(frame: self.view.frame)
                    present(imageDisplay, animated: true, completion: nil)
                }
            }
        }
    }
    
    /**
        Sending buttons functions
    **/
    
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        m_messagesHandler.sendRoomMessage(senderID: senderId, senderName: senderDisplayName, text: text, url: nil, roomID: m_currentRoomID!, color: m_currentUserColor!)
        
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
    
    /**
        Save/Heart Button Fuctions
    **/
    
    @objc func saveRoomButtonClicked() {
        if !m_isRoomSaved {
            m_saveRoomButton?.tintColor = UIColor(red: 133/255, green: 51/255, blue: 1, alpha: 1)
            m_isRoomSaved = true
            saveRoom()
        } else {
            m_saveRoomButton?.tintColor = UIColor.gray
            m_isRoomSaved = false
            unsaveRoom()
        }
    }
    
    func saveRoom() {
        m_coreDataProvider.saveRoomCoreData(currentRoomID: m_currentRoomID!)
    }
    
    func unsaveRoom() {
        m_coreDataProvider.deleteRoomCoreData(currentRoomID: m_currentRoomID!)
    }
    
    /**
        Picker view fucntions
    **/
    
    private func chooseMedia(type: CFString) {
        m_picker.mediaTypes = [type as String]
        present(m_picker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let mediaPick = info[UIImagePickerControllerOriginalImage] as? UIImage {
            let image = JSQPhotoMediaItem.init(image: mediaPick)
            m_messages.append(JSQMessage(senderId: self.senderId, displayName: self.senderDisplayName, media: image))
            m_messageColors.append("blue")
            self.collectionView.reloadData()
            let data = UIImageJPEGRepresentation(mediaPick, 0.5)
            m_messagesHandler.saveMedia(image: data!, video: nil, senderID: self.senderId, senderName: self.senderDisplayName, roomID: m_currentRoomID!, color: m_currentUserColor!)
            dismiss(animated: true, completion: nil)
            
        } else if let mediaPick = info[UIImagePickerControllerMediaURL] as? URL {
            let video = JSQVideoMediaItem.init(fileURL: mediaPick, isReadyToPlay: true)
            m_messages.append(JSQMessage(senderId: self.senderId, displayName: self.senderDisplayName, media: video))
            m_messageColors.append("blue")
            self.collectionView.reloadData()
            m_messagesHandler.saveMedia(image: nil, video: mediaPick, senderID: self.senderId, senderName: self.senderDisplayName, roomID: m_currentRoomID!, color: m_currentUserColor!)
            dismiss(animated: true, completion: nil)
        }
    }
    
    /**
        Delegation functions
    **/
    
    func messageReceived(message: JSQMessage, color: String) {
        m_messages.append(message)
        m_messageColors.append(color)
        self.collectionView.reloadData()
        self.collectionView.layoutIfNeeded()
        scrollToBottom(animated: false)
    }
    
    func allMessagesReceived(messages: [JSQMessage], messageColors: [String]) {
        m_messages = messages
        m_messageColors = messageColors
        self.collectionView.reloadData()
        self.collectionView.layoutIfNeeded()
        scrollToBottom(animated: false)
    }
    
    func mediaMessageReceived(message: JSQMessage, forIndex: Int) {
        if forIndex <= m_messages.count {
            m_messages[forIndex] = message
            let indexPath = IndexPath(row: forIndex, section: 0)
            self.collectionView.reloadItems(at: [indexPath])
        }
    }
    
}
