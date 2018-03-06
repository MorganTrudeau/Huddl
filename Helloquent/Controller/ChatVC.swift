
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
import FirebaseMessaging

class ChatVC: JSQMessagesViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPickerViewDelegate, ImageCacheDelegate, MediaMessageDelegate {
    
    var m_saveRoomButton: UIBarButtonItem?
    
    let m_messagesProvider = MessagesProvider.Instance
    let m_dbProvider = DBProvider.Instance
    let m_authProvider = AuthProvider.Instance
    let m_cacheStorage = CacheStorage.Instance
    let m_picker = UIImagePickerController()
    
    var m_messages = [JSQMessage]()
    
    // Room variables
    var m_userMenu = UIView()
    var m_isRoomSaved = false
    var m_savedRooms = [Room]()
    var m_currentRoom: Room?
    var m_roomUsers = [String]()
    
    // Chat variables
    var m_receiver: User?

    override func viewDidLoad() {
        super.viewDidLoad()
        m_currentRoom = m_dbProvider.m_currentRoom!
        
        m_cacheStorage.imageCacheDelegate = self
        m_messagesProvider.delegate = self
        m_picker.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(ChatVC.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        
        // Values set for display JSQMessages
        self.senderId = m_authProvider.userID()
        self.senderDisplayName = try! m_cacheStorage.m_userStorage.object(ofType: User.self, forKey: m_authProvider.userID()).name
        
        // Check if room is saved
        if let savedRooms = try? m_cacheStorage.m_roomStorage.object(ofType: [Room].self, forKey: "saved") {
            m_savedRooms = savedRooms
        }
        
        m_isRoomSaved = m_savedRooms.contains(where: { $0.id == m_currentRoom?.id })
        
        // Get User information for users that have posted in room
        self.m_dbProvider.getRoomUsers(completion: {(roomUsers) in
            self.m_roomUsers = roomUsers
        })
        
        setUpUI()
        loadCachedMessages()
        handleNotifications()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // If any new messages from database
        loadDatabaseMessages()
        // Observes new messages added to database
        m_messagesProvider.observeRoomMessages()
        self.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        m_messagesProvider.removeRoomObservers()
        self.tabBarController?.tabBar.isHidden = false
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    func setUpUI() {
        self.navigationController?.navigationBar.barTintColor = UIColor.init(white: 0.1, alpha: 1)
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.lightText]
        
        self.collectionView.backgroundColor = UIColor.init(white: 0.4, alpha: 1)
        
        // Create Heart button to save room
        m_saveRoomButton = UIBarButtonItem(image: UIImage(named: "heart"), style: .plain, target: self, action: #selector(ChatVC.saveRoomButtonClicked))
        
        self.navigationItem.rightBarButtonItem  = m_saveRoomButton
        self.navigationItem.title = m_currentRoom!.name;
        
        // Set color of heart
        if !self.m_isRoomSaved {
            self.m_saveRoomButton?.tintColor = UIColor.gray
        } else {
            self.m_saveRoomButton?.tintColor = UIColor(red: 133/255, green: 51/255, blue: 1, alpha: 1)
        }
        collectionView.collectionViewLayout.incomingAvatarViewSize = CGSize(width: 40, height: 40)
        collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSize(width: 40, height: 40)
    }
    
    func loadCachedMessages() {
        if try! m_cacheStorage.m_messagesStorage.existsObject(ofType: [Message].self, forKey: m_currentRoom!.id) {
            m_cacheStorage.fetchMessages(roomID: m_currentRoom!.id, completion: {(messages) in
                self.m_messages = messages
                self.collectionView.reloadData()
                self.collectionView.layoutIfNeeded()
                self.scrollToBottom(animated: false)
            })
        }
    }
    
    func loadDatabaseMessages() {
        self.m_messagesProvider.getRoomMessages(roomID: self.m_currentRoom!.id, completion: {(messages) in
            self.m_messages += messages
            self.collectionView.reloadData()
            self.collectionView.layoutIfNeeded()
            self.scrollToBottom(animated: true)
        })
    }
    
    // Removes notifications for room if present
    func handleNotifications() {
        if try! m_cacheStorage.m_roomStorage.existsObject(ofType: Int.self, forKey: m_currentRoom!.id) {
            // Remove notification on tableview
            try? m_cacheStorage.m_roomStorage.removeObject(forKey: m_currentRoom!.id)
            // Reduce or remove badge on tab bar
            if var roomNotifications = try? m_cacheStorage.m_roomStorage.object(ofType: [String].self, forKey: "room") {
                roomNotifications = roomNotifications.filter { $0 != m_currentRoom!.id }
                if roomNotifications.count > 0 {
                    self.tabBarController?.tabBar.items![0].badgeValue = String(roomNotifications.count)
                } else {
                    self.tabBarController?.tabBar.items![0].badgeValue = nil
                }
                m_cacheStorage.cacheTabNotifications(notifications: roomNotifications, type: "room")
            }
        }
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
        cell.avatarImageView.isUserInteractionEnabled = true
        
        if m_messages[indexPath.row].senderId != m_authProvider.userID() {
            let tap = UITapGestureRecognizer(target: self, action: #selector(ChatVC.presentUserMenu))
            tap.numberOfTapsRequired = 1
            cell.avatarImageView.addGestureRecognizer(tap)
        }

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
        m_messagesProvider.sendRoomMessage(senderID: senderId, senderName: senderDisplayName, text: text, url: nil, room: m_currentRoom!)
        
        // Add message to collectionview
        m_messages.append(JSQMessage(senderId: senderId, displayName: senderDisplayName, text: text))
        self.collectionView.reloadData()
        self.collectionView.layoutIfNeeded()
        self.scrollToBottom(animated: false)
        
        if !m_roomUsers.contains(senderId) {
            m_roomUsers.append(senderId)
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
            m_messagesProvider.saveMedia(image: mediaPick, video: nil, senderID: self.senderId, senderName: self.senderDisplayName, room: m_currentRoom!, receiverID: nil)
            
        } else if let mediaPick = info[UIImagePickerControllerMediaURL] as? URL {
            // Add media message to local messages variable and reload
            let video = JSQVideoMediaItem(fileURL: mediaPick, isReadyToPlay: true)
            m_messages.append(JSQMessage(senderId: self.senderId, displayName: self.senderDisplayName, media: video))
            self.collectionView.reloadData()
            
            // Save video message to Firebase database and cache
            m_messagesProvider.saveMedia(image: nil, video: mediaPick, senderID: self.senderId, senderName: self.senderDisplayName, room: m_currentRoom!, receiverID: nil)
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
        m_dbProvider.increaseLikes()
        m_savedRooms.append(m_currentRoom!)
        m_cacheStorage.cacheRooms(type: "saved", rooms: m_savedRooms)
        Messaging.messaging().subscribe(toTopic: m_currentRoom!.id)
        print("Subscribed to \(m_currentRoom!.id)")
    }
    
    func unsaveRoom() {
        m_dbProvider.decreaseLikes()
        let index = m_savedRooms.index(where: { $0.id == m_currentRoom!.id })
        m_savedRooms.remove(at: index!)
        m_cacheStorage.cacheRooms(type: "saved", rooms: m_savedRooms)
        Messaging.messaging().unsubscribe(fromTopic: m_currentRoom!.id)
        print("Unsubscribed to \(m_currentRoom!.id)")
    }
    
    /**
     Keyboard Functions
     **/
    
    @objc func keyboardWillShow(notification: NSNotification) {
        self.topContentAdditionalInset = -65
    }
    
    /**
        Delegation functions
    **/
    
    func mediaMessageReceived(message: JSQMessage, id: String, index: Int) {
        if id == m_currentRoom?.id {
            m_messages[index] = message
            let indexPath = IndexPath(row: index, section: 0)
            collectionView.reloadItems(at: [indexPath])
        }
    }
    
    func messageReceived(message: JSQMessage) {
        DispatchQueue.main.async {
            self.m_messages.append(message)
            self.collectionView.reloadData()
            if (self.collectionView.contentOffset.y >= self.collectionView.contentSize.height - self.collectionView.frame.size.height + (self.navigationController?.navigationBar.frame.size.height)!) {
                self.collectionView.layoutIfNeeded()
                self.scrollToBottom(animated: true)
            }
        }
    }
    
    func imageCacheUpdated() {
        collectionView.reloadData()
    }
    
    @objc func presentUserMenu(sender: UITapGestureRecognizer) {
        let tapLocation = sender.location(in: self.collectionView)
        let indexPath: IndexPath = self.collectionView.indexPathForItem(at: tapLocation)!
        let messageAtIndex = m_messages[indexPath.row]
        let userID = messageAtIndex.senderId
        let user = try? m_cacheStorage.m_userStorage.object(ofType: User.self, forKey: userID!)
        m_receiver = user
        
        m_userMenu = UIView.init(frame: CGRect(x: 0, y: 0, width: 250, height: 150))
        m_userMenu.center.y = self.view.center.y
        m_userMenu.center.x = self.view.center.x
        m_userMenu.layer.cornerRadius = 8
        m_userMenu.backgroundColor = UIColor.init(white: 0.2, alpha: 1)
        self.view.addSubview(m_userMenu)
        
        let avatarView = UIImageView.init(frame: CGRect(x: 100, y: 10, width: 50, height: 50))
        avatarView.image = UIImage(named: "avatar.gif")
        avatarView.layer.masksToBounds = true
        avatarView.layer.cornerRadius = 25
        
        let userNameText = UILabel.init(frame: CGRect(x: 0, y: 70, width: 250, height: 20))
        userNameText.text = user?.name
        userNameText.textAlignment = .center
        userNameText.textColor = UIColor.white
        userNameText.font = UIFont.boldSystemFont(ofSize: 19)
        
        let messageButton = UIButton.init(frame: CGRect(x: 80, y: 100, width: 40, height: 40))
        messageButton.setImage(UIImage(named: "chats_white"), for: .normal)
        messageButton.backgroundColor = UIColor(white: 0.18, alpha: 1)
        messageButton.layer.borderWidth = 2
        messageButton.layer.borderColor = UIColor(white: 0.16, alpha: 1).cgColor
        messageButton.layer.cornerRadius = 5
        messageButton.addTarget(self, action: #selector(ChatVC.displayPersonalChat), for: .touchUpInside)
        
        let cancelButton = UIButton.init(frame: CGRect(x: 130, y: 100, width: 40, height: 40))
        cancelButton.setImage(UIImage(named: "cancel"), for: .normal)
        cancelButton.backgroundColor = UIColor(white: 0.18, alpha: 1)
        cancelButton.layer.borderWidth = 2
        cancelButton.layer.borderColor = UIColor(white: 0.16, alpha: 1).cgColor
        cancelButton.layer.cornerRadius = 5
        cancelButton.addTarget(self, action: #selector(ChatVC.dismissUserMenu), for: .touchUpInside)
    
        m_userMenu.addSubview(avatarView)
        m_userMenu.addSubview(userNameText)
        m_userMenu.addSubview(messageButton)
        m_userMenu.addSubview(cancelButton)
    }
    
    @objc func dismissUserMenu() {
        m_userMenu.removeFromSuperview()
    }
    
    @objc func displayPersonalChat() {
        performSegue(withIdentifier: "personal_chat_segue", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        m_userMenu.removeFromSuperview()
        // Check whether chat exists between users
        let user = try? m_cacheStorage.m_userStorage.object(ofType: User.self, forKey: m_authProvider.userID())
        let chats = user!.chats
        let personalChatVC = segue.destination as! PersonalChatVC
        let chatID = chats[m_receiver!.id]
        
        if chatID != nil {
            personalChatVC.m_currentChatID = chatID!
            personalChatVC.m_receiverUserID = m_receiver!.id
        } else {
            personalChatVC.m_currentChatID = "\(m_authProvider.userID())\(m_receiver!.id)"
            personalChatVC.m_receiverUserID = m_receiver!.id
            personalChatVC.m_newChat = true
        }
        
    }
    
}
