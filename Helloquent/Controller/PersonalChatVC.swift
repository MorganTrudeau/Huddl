//
//  PersonalChatVC.swift
//  Helloquent
//
//  Created by Morgan Trudeau on 2018-02-12.
//  Copyright © 2018 Morgan Trudeau. All rights reserved.
//

import UIKit
import JSQMessagesViewController
import MobileCoreServices
import AVKit
import Cache
import FirebaseMessaging

class PersonalChatVC: JSQMessagesViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPickerViewDelegate, ImageCacheDelegate, MediaMessageDelegate {
    
    
    let m_messagesProvider = MessagesProvider.Instance
    let m_dbProvider = DBProvider.Instance
    let m_authProvider = AuthProvider.Instance
    let m_cacheStorage = CacheStorage.Instance
    let m_picker = UIImagePickerController()
    
    var m_messages = [JSQMessage]()
    
    var m_currentChatID = ""
    var m_receiverUserID = ""
    var m_receiverUser: User?
    var m_newChat = false
    var m_userMenu: UIView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Load receiver user information from cache
        if let receiver = try? m_cacheStorage.m_userStorage.object(ofType: User.self, forKey: m_receiverUserID) {
            m_receiverUser = receiver
        }
        // Update cache with receiver's information
        m_dbProvider.getUser(id: m_receiverUserID, completion: {(user) in
            self.m_receiverUser = user
        })
        // Update current user cache with this chat
        m_dbProvider.getUser(id: m_authProvider.userID(), completion: nil)
        // Set DBProvider chatID to direct location of DB storage
        m_dbProvider.m_currentChatID = m_currentChatID
        
        // Values set for display JSQMessages
        self.senderId = m_authProvider.userID()
        self.senderDisplayName = try! m_cacheStorage.m_userStorage.object(ofType: User.self, forKey: m_authProvider.userID()).name
        
        m_cacheStorage.imageCacheDelegate = self
        m_messagesProvider.delegate = self
        m_picker.delegate = self
        
        // Workaround for JSQMessageViewController inset bug
        NotificationCenter.default.addObserver(self, selector: #selector(ChatVC.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        
        setUpUI()
        loadCachedMessages()
        handleNotifications()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        loadDatabaseMesages()
        // Observes new messages added to database
        m_messagesProvider.observeChatMessages()
        
        tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        tabBarController?.tabBar.isHidden = false
        m_messagesProvider.removeChatObservers()
    }
    
    func setUpUI() {
        navigationController?.navigationBar.barTintColor = UIColor.init(white: 0.1, alpha: 1)
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.lightText]
        navigationItem.title = m_receiverUser!.name
        
        collectionView.backgroundColor = UIColor.init(white: 0.4, alpha: 1)
        collectionView.collectionViewLayout.incomingAvatarViewSize = CGSize(width: 40, height: 40)
        collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSize(width: 40, height: 40)
    }
    
    func loadCachedMessages() {
        if try! m_cacheStorage.m_messagesStorage.existsObject(ofType: [Message].self, forKey: m_currentChatID) {
            m_cacheStorage.fetchMessages(roomID: m_currentChatID, completion: {(messages) in
                self.m_messages = messages
                self.collectionView.reloadData()
                self.collectionView.layoutIfNeeded()
                self.scrollToBottom(animated: false)
            })
        }
    }
    
    func loadDatabaseMesages() {
        // Update cache with current rooms messages
        self.m_messagesProvider.getChatMessages(chatID: m_currentChatID, completion: {(messages) in
            self.m_messages += messages
            self.collectionView.reloadData()
            self.collectionView.layoutIfNeeded()
            self.scrollToBottom(animated: true)
        })
    }
    
    // Removes notifications for chat if present
    func handleNotifications() {
        if try! m_cacheStorage.m_roomStorage.existsObject(ofType: Int.self, forKey: m_currentChatID) {
            // Remove notification on tableview
            try? m_cacheStorage.m_roomStorage.removeObject(forKey: m_currentChatID)
            // Reduce or remove badge on tab bar
            if var chatNotifications = try? m_cacheStorage.m_roomStorage.object(ofType: [String].self, forKey: "chat") {
                chatNotifications = chatNotifications.filter { $0 != m_currentChatID }
                if chatNotifications.count > 0 {
                    self.tabBarController?.tabBar.items![1].badgeValue = String(chatNotifications.count)
                } else {
                    self.tabBarController?.tabBar.items![1].badgeValue = nil
                }
                m_cacheStorage.cacheTabNotifications(notifications: chatNotifications, type: "chat")
            }
        }
    }
    
    /**
     CollectionView Functions
     **/
    
    // Apply avatar beside message
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        let message = m_messages[indexPath.item]
        var avatar = UIImage(named: "user")
        if let user = try? m_cacheStorage.m_userStorage.object(ofType: User.self, forKey: message.senderId) {
            if let avatarImage = try? m_cacheStorage.m_mediaStorage.object(ofType: ImageWrapper.self, forKey: user.avatar).image {
                avatar = avatarImage
            }
        }
        return JSQMessagesAvatarImageFactory.avatarImage(with: avatar, diameter: 80)
    }
    
    // Apply color and incoming/outgoing mask
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
    
    // Message data for indexPath
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return m_messages[indexPath.item]
    }
    
    // Number of messages in collection view
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return m_messages.count
    }
    
    // Returns a JSQMessagesCollectionViewCell and sets color
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        cell.messageBubbleTopLabel.textColor = UIColor.init(white: 0.9, alpha: 1)
        cell.avatarImageView.isUserInteractionEnabled = true
        cell.textView!.textColor = UIColor.black
        
        if m_messages[indexPath.row].senderId != m_authProvider.userID() {
            let tap = UITapGestureRecognizer(target: self, action: #selector(ChatVC.presentUserMenu))
            tap.numberOfTapsRequired = 1
            cell.avatarImageView.addGestureRecognizer(tap)
        }
        
        return cell
    }
    
    // Applies sender name above message bubble
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
    
    // Sets space above messages
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleTopLabelAt indexPath: IndexPath!) -> CGFloat
    {
        return 17.0
    }
    
    // Handles message tap events
    // Opens image viewer if image
    // Opens video player if video
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
            } else {
                alertUser(title: "Report Content", message: "Would you like to report this message?")
            }
        }
    }
    
    /**
     Sending buttons functions
     **/
    
    
    // Handles message send button press
    // Saves to Firebase and cache
    // Creates instance of chat for receiver and sender if this is a new chat
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
            m_dbProvider.getBlockedList(completion: {(blockedList) in
            if (!blockedList.contains { $0 == self.m_receiverUserID }) {
                // If users do not have an existing chat, creates instance in sender's and receiver's chats
                if self.m_newChat {
                    self.m_dbProvider.createChat(receiverID: self.m_receiverUserID)
                }

                // Save message in Firebase and cache
                self.m_messagesProvider.sendChatMessage(receiverID: self.m_receiverUserID, senderID: senderId, senderName: senderDisplayName, text: text, url: nil, chatID: self.m_currentChatID)
                
                // Add message to collectionview
                self.m_messages.append(JSQMessage(senderId: senderId, displayName: senderDisplayName, text: text))
                self.collectionView.reloadData()
                self.collectionView.layoutIfNeeded()
                self.scrollToBottom(animated: false)
                
                // Clear message input field
                self.finishSendingMessage()
            } else {
                self.alertUser(title: "Cannot send messgage", message: "You are blocked by this user")
            }
        })
    }
    
    func alertUser(title: String, message: String) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }
    
    /**
     Picker view fucntions
     **/
    
    
    // Handles accessory button press
    // Displays menu to choose from image picker or video picker
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
    
    // Presents desired picker view
    private func chooseMedia(type: CFString) {
        m_picker.mediaTypes = [type as String]
        present(m_picker, animated: true, completion: nil)
    }
    
    
    // Handles return with media from picker view
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        // Check whether picker returned with image or video
        if let mediaPick = info[UIImagePickerControllerOriginalImage] as? UIImage {
            // Add media message to local messages variable and reload
            let image = JSQPhotoMediaItem.init(image: mediaPick)
            m_messages.append(JSQMessage(senderId: self.senderId, displayName: self.senderDisplayName, media: image))
            self.collectionView.reloadData()
            
            // Save image message in Firebase and cache
            m_messagesProvider.saveMedia(image: mediaPick, video: nil, senderID: self.senderId, senderName: self.senderDisplayName, room: nil, receiverID: m_receiverUserID)
            
        } else if let mediaPick = info[UIImagePickerControllerMediaURL] as? URL {
            // Add media message to local messages variable and reload
            let video = JSQVideoMediaItem(fileURL: mediaPick, isReadyToPlay: true)
            m_messages.append(JSQMessage(senderId: self.senderId, displayName: self.senderDisplayName, media: video))
            self.collectionView.reloadData()
            
            // Save video message to Firebase database and cache
            m_messagesProvider.saveMedia(image: nil, video: mediaPick, senderID: self.senderId, senderName: self.senderDisplayName, room: nil, receiverID: m_receiverUserID)
        }
        // Dismiss picker
        dismiss(animated: true, completion: nil)
    }
    
    @objc func presentUserMenu(sender: UITapGestureRecognizer) {
        let user = m_receiverUser!
        
        if m_userMenu != nil {
            dismissUserMenu()
        }
        m_userMenu = UIView.init(frame: CGRect(x: 0, y: 0, width: 270, height: 150))
        m_userMenu!.center.y = self.view.center.y
        m_userMenu!.center.x = self.view.center.x
        m_userMenu!.layer.cornerRadius = 8
        m_userMenu!.backgroundColor = UIColor.init(white: 0.2, alpha: 1)
        self.view.addSubview(m_userMenu!)
        
        let avatarView = UIImageView.init(frame: CGRect(x: 110
            , y: 10, width: 50, height: 50))
        avatarView.image = UIImage(named: "user")
        avatarView.layer.masksToBounds = true
        avatarView.layer.cornerRadius = 25
        if let avatar = try? m_cacheStorage.m_mediaStorage.object(ofType: ImageWrapper.self, forKey: user.avatar) {
            avatarView.image = avatar.image
        }
        
        let userNameText = UILabel.init(frame: CGRect(x: 0, y: 70, width: 270, height: 20))
        userNameText.text = user.name
        userNameText.textAlignment = .center
        userNameText.textColor = UIColor.white
        userNameText.font = UIFont.boldSystemFont(ofSize: 19)
        
        let blockButton = UIButton.init(frame: CGRect(x: 75, y: 100, width: 120, height: 40))
        blockButton.setTitle("Block", for: .normal)
        blockButton.setImage(UIImage(named: "block"), for: .normal)
        blockButton.backgroundColor = UIColor(white: 0.18, alpha: 1)
        blockButton.layer.borderWidth = 2
        blockButton.layer.borderColor = UIColor(white: 0.16, alpha: 1).cgColor
        blockButton.layer.cornerRadius = 5
        blockButton.addTarget(self, action: #selector(PersonalChatVC.blockUser), for: .touchUpInside)
        
        let cancelButton = UIButton.init(frame: CGRect(x: 230, y: 0, width: 40, height: 40))
        cancelButton.setImage(UIImage(named: "cancel"), for: .normal)
        cancelButton.addTarget(self, action: #selector(PersonalChatVC.dismissUserMenu), for: .touchUpInside)
        
        m_userMenu!.addSubview(avatarView)
        m_userMenu!.addSubview(userNameText)
        m_userMenu!.addSubview(blockButton)
        m_userMenu!.addSubview(cancelButton)
    }
    
    @objc func dismissUserMenu() {
        m_userMenu!.removeFromSuperview()
        m_userMenu = nil
    }
    
    @objc func blockUser() {
        // blockUser in cache to filter content in public chat rooms
        m_cacheStorage.blockUser(userID: m_receiverUser!.id)
        // blockUser in database to they cannot contact user directly
        m_dbProvider.blockUser(userID: m_receiverUser!.id)
        dismissUserMenu()
    }
    
    /**
     Keyboard Functions
     **/
    
    
    // Workaround for JSQMessageViewController adding inset when keyboard shows
    @objc func keyboardWillShow(notification: NSNotification) {
        self.topContentAdditionalInset = -65
    }
    
    /**
     Delegation functions
     **/
    
    // Called when observeChatMessages receives a message
    // If message is of type media, will display a placeholder image to be updated by mediaMessageReceived delegate func
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
    
    // Called when loadMediaMessage finishes downloading media from getChatMessages/ observeChatMessages
    // Updates the placeholder image in chat
    func mediaMessageReceived(message: JSQMessage, id: String, index: Int) {
        if id == m_currentChatID {
            m_messages[index] = message
            let indexPath = IndexPath(row: index, section: 0)
            collectionView.reloadItems(at: [indexPath])
        }
    }
    
    // Notifies viewcontroller that user image has been downloaded
    // reloads collection view to display updated avatar
    func imageCacheUpdated() {
        collectionView.reloadData()
    }
    
}
