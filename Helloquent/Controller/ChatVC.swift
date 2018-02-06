
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
import Cache

class ChatVC: JSQMessagesViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPickerViewDelegate, CacheDelegate, MediaMessageDelegate {
    
    var m_saveRoomButton: UIBarButtonItem?
    
    let m_coreDataProvider = CoreDataProvider.Instance
    let m_messagesProvider = MessagesProvider.Instance
    let m_dbProvider = DBProvider.Instance
    let m_authProvider = AuthProvider.Instance
    let m_cacheStorage = CacheStorage.Instance
    let m_picker = UIImagePickerController()
    
    var m_messages = [JSQMessage]()
    
    var m_isRoomSaved = false
    var m_savedRooms = [Room]()
    var m_currentRoom: Room?
    var m_roomUsers = [String]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        m_cacheStorage.delegate = self
        m_messagesProvider.delegate = self
        m_picker.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(ChatVC.handleResignActive), name: NSNotification.Name(rawValue: "ResignActiveNotification"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ChatVC.handleBecomeActive), name: NSNotification.Name(rawValue: "BecomeActiveNotification"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ChatVC.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ChatVC.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        // Values set for display JSQMessages
        self.senderId = m_authProvider.userID()
        self.senderDisplayName = try! m_cacheStorage.m_userStorage.object(ofType: User.self, forKey: m_authProvider.userID()).name
        
        // Check if room is saved
        if let savedRooms = try? m_cacheStorage.m_roomStorage.object(ofType: [Room].self, forKey: "saved") {
            m_savedRooms = savedRooms
        }
        m_isRoomSaved = m_savedRooms.contains(where: { $0.id == m_currentRoom?.id })
        
        
        self.m_dbProvider.getRoomUsers(completion: {(roomUsers) in
            self.m_roomUsers = roomUsers
        })
        
        
        setUpUI()
        loadUIWithCache()
        updateCache()
    }
    
    func setUpUI() {
        self.collectionView.backgroundColor = UIColor.init(white: 0.4, alpha: 1)
        
        // Create Heart button to save room
        m_saveRoomButton = UIBarButtonItem(image: UIImage(named: "heart"), style: .plain, target: self, action: #selector(ChatVC.saveRoomButtonClicked))
        
        // Set color of heart
        if !self.m_isRoomSaved {
            self.m_saveRoomButton?.tintColor = UIColor.gray
        } else {
            self.m_saveRoomButton?.tintColor = UIColor(red: 133/255, green: 51/255, blue: 1, alpha: 1)
        }
        
        self.navigationItem.rightBarButtonItem  = m_saveRoomButton
        self.navigationItem.title = m_currentRoom!.name;
        
        collectionView.collectionViewLayout.incomingAvatarViewSize = CGSize(width: 40, height: 40)
        collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSize(width: 40, height: 40)
    }
    
    func loadUIWithCache() {
        if try! m_cacheStorage.m_messagesStorage.existsObject(ofType: [Message].self, forKey: m_currentRoom!.id) {
            m_cacheStorage.fetchMessages(roomID: m_currentRoom!.id, completion: {(messages) in
                self.m_messages = messages
                self.collectionView.reloadData()
                self.collectionView.layoutIfNeeded()
                self.scrollToBottom(animated: false)
                
            })
        }
    }
    
    func updateCache() {
        // Update cache with current rooms messages and return users who have posted in room
        self.m_messagesProvider.getRoomMessages(roomID: self.m_currentRoom!.id, completion: {(messages) in
            self.m_messages += messages
            self.collectionView.reloadData()
            self.collectionView.layoutIfNeeded()
            self.scrollToBottom(animated: true)
        })
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Observes new messages added to database
        m_messagesProvider.observeRoomMessages()
            
        self.tabBarController?.tabBar.isHidden = true
    }
    
    /**
     Increase active users in Firebase when view appears
    **/
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        m_dbProvider.increaseActiveUsers()
    }
    
    /**
     Decrease active users in Firebase when view disappears
     **/
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        self.tabBarController?.tabBar.isHidden = false
        m_messagesProvider.removeRoomObservers()
        m_dbProvider.decreaseActiveUsers(completion: nil)
    }
    
    /**
     Increase active users in Firebase when app become active
     **/
    
    @objc func handleBecomeActive() {
        m_dbProvider.increaseActiveUsers()
    }
    
    /**
     Decrease active users in Firebase when app becomes inactive
    **/
    
    @objc func handleResignActive() {
        m_dbProvider.decreaseActiveUsers(completion: nil)
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

    /**
     Apply avatar beside message
    **/
 
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        let message = m_messages[indexPath.item]
        var avatar = UIImage(named: "avatar.gif")
        if let user = try? m_cacheStorage.m_userStorage.object(ofType: User.self, forKey: message.senderId) {
            if let avatarImage = try? m_cacheStorage.m_mediaStorage.object(ofType: ImageWrapper.self, forKey: user.avatar).image {
                avatar = avatarImage
            }
        }
        return JSQMessagesAvatarImageFactory.avatarImage(with: avatar, diameter: 80)
    }
    
    /**
     Apply color and incoming/outgoing mask
    **/

    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let bubbleFactory = JSQMessagesBubbleImageFactory()
        let message = m_messages[indexPath.row]
        let messageColor: UIColor
        
        // Attempt to fetch cached user color
        if let userColor = try? m_cacheStorage.m_userStorage.object(ofType: User.self, forKey: message.senderId).color {
            messageColor = ColorHandler.Instance.convertToUIColor(colorString: userColor)
        } else {
            messageColor = ColorHandler.Instance.convertToUIColor(colorString: "blue")
        }
        
        // Contruct message as incoming or outgoing with user color
        if message.senderId == m_authProvider.userID() {
            return bubbleFactory?.outgoingMessagesBubbleImage(with: messageColor)
        } else {
            return bubbleFactory?.incomingMessagesBubbleImage(with: messageColor)
        }
    }
    
    /**
     Message data for indexPath
    **/

    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return m_messages[indexPath.item]
    }
    
    /**
     Number of messages in collection view
    **/
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return m_messages.count
    }
    
    /**
     Returns a JSQMessagesCollectionViewCell and sets color
    **/
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        cell.messageBubbleTopLabel.textColor = UIColor.init(white: 0.9, alpha: 1)
        return cell
    }
    
    /**
     Applies sender name above message bubble
    **/
 
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForMessageBubbleTopLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        
        let message = m_messages[indexPath.row]
        
        if message.senderId == senderId {
            return nil
        } else if let user = try? m_cacheStorage.m_userStorage.object(ofType: User.self, forKey: message.senderId) {
            return NSAttributedString(string: user.name)
        } else {
            return nil
        }
    }
    
    /**
     Sets space above messages
    **/
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleTopLabelAt indexPath: IndexPath!) -> CGFloat
    {
        return 17.0
    }
    
    /**
     Handles message tap events
     Opens image viewer if image
     Opens video player if video
    **/
    
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
                    self.present(imageDisplay, animated: true, completion: nil)
                }
            }
        }
    }
    
    /**
        Sending buttons functions
    **/
    
    /**
     Handles message send button press
     Saves to Firebase and cache
    **/
    
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        
        // Save message in Firebase and cache
        m_messagesProvider.sendRoomMessage(senderID: senderId, senderName: senderDisplayName, text: text, url: nil, roomID: m_currentRoom!.id)
        
        // Add message to collectionview
        m_messages.append(JSQMessage(senderId: senderId, displayName: senderDisplayName, text: text))
        self.collectionView.reloadData()
        self.collectionView.layoutIfNeeded()
        self.scrollToBottom(animated: false)
        
        if !m_roomUsers.contains(senderId) {
            m_dbProvider.updateRoomUsers(roomUser: senderId)
        }
        
        // Clear message input field
        finishSendingMessage()
    }
    
    /**
     Picker view fucntions
     **/
    
    /**
     Handles accessory button press
     Displays menu to choose from image picker or video picker
    **/
    
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
     Presents desired picker view
    **/
    
    private func chooseMedia(type: CFString) {
        m_picker.mediaTypes = [type as String]
        present(m_picker, animated: true, completion: nil)
    }
    
    /**
     Handles return with media from picker view
    **/
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        // Check whether picker returned with image or video
        if let mediaPick = info[UIImagePickerControllerOriginalImage] as? UIImage {
            // Add media message to local messages variable and reload
            let image = JSQPhotoMediaItem.init(image: mediaPick)
            m_messages.append(JSQMessage(senderId: self.senderId, displayName: self.senderDisplayName, media: image))
            self.collectionView.reloadData()
            
            // Save image message in Firebase and cache
            m_messagesProvider.saveMedia(image: mediaPick, video: nil, senderID: self.senderId, senderName: self.senderDisplayName, roomID: m_currentRoom!.id)
            
        } else if let mediaPick = info[UIImagePickerControllerMediaURL] as? URL {
            // Add media message to local messages variable and reload
            let video = JSQVideoMediaItem(fileURL: mediaPick, isReadyToPlay: true)
            m_messages.append(JSQMessage(senderId: self.senderId, displayName: self.senderDisplayName, media: video))
            self.collectionView.reloadData()
            
            // Save video message to Firebase database and cache
            m_messagesProvider.saveMedia(image: nil, video: mediaPick, senderID: self.senderId, senderName: self.senderDisplayName, roomID: m_currentRoom!.id)
        }
        // Dismiss picker
        dismiss(animated: true, completion: nil)
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
        m_savedRooms.append(m_currentRoom!)
        m_cacheStorage.cacheRooms(type: "saved", rooms: m_savedRooms)
    }
    
    func unsaveRoom() {
        let index = m_savedRooms.index(where: { $0.id == m_currentRoom!.id })
        m_savedRooms.remove(at: index!)
        m_cacheStorage.cacheRooms(type: "saved", rooms: m_savedRooms)
    }
    
    /**
        Delegation functions
    **/
    
    func mediaMessageReceived(message: JSQMessage, roomID: String, index: Int) {
        if roomID == m_currentRoom?.id {
            m_messages[index] = message
            let indexPath = IndexPath(row: index, section: 0)
            collectionView.reloadItems(at: [indexPath])
        }
    }
    
    func messageReceived(message: JSQMessage) {
        DispatchQueue.main.sync {
            m_messages.append(message)
            collectionView.reloadData()
            self.collectionView.layoutIfNeeded()
            self.scrollToBottom(animated: true)
        }
    }
    
    func cacheUpdated() {
        collectionView.reloadData()
    }
}
