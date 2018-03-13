//
//  DirectMessagesVC.swift
//  Helloquent
//
//  Created by Morgan Trudeau on 2018-02-11.
//  Copyright © 2018 Morgan Trudeau. All rights reserved.
//

import Foundation
import UIKit
import Cache

class PersonalChatsVC: UIViewController, UITableViewDelegate, UITableViewDataSource, NotificationCacheDelegate, ImageCacheDelegate {
    
    @IBOutlet weak var m_personalChatsTableView: UITableView!
    
    let PERSONAL_CHAT_SEGUE = "personal_chat_segue"
    let CELL_ID = "chat_cell"
    
    let m_cacheStorage = CacheStorage.Instance
    var m_chats = [String:String]()
    var m_userIDs = [String]()
    var m_index: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        m_personalChatsTableView.delegate = self
        m_personalChatsTableView.dataSource = self
        m_cacheStorage.notificationCacheDelegate = self
        m_cacheStorage.imageCacheDelegate = self
        loadChats()
        setUpUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadChats()
    }
    
    func loadChats() {
        if let user = try? m_cacheStorage.m_userStorage.object(ofType: User.self, forKey: AuthProvider.Instance.userID()) {
            if m_chats != user.chats {
                m_chats = user.chats
                m_userIDs = Array(m_chats.keys)
            }
            for userID in m_userIDs {
                DBProvider.Instance.getUser(id: userID, completion: nil)
            }
            m_personalChatsTableView.reloadData()
        }
    }
    
    func setUpUI() {
        self.navigationController?.navigationBar.barTintColor = UIColor(white: 0.1, alpha: 1)
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.lightText]
    }
    
    /**
     TableView Functions
    **/
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return m_userIDs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "chat_cell", for: indexPath) as! ChatTableViewCell
        
        var avatar = UIImage(named: "user")
        
        if let user = try? m_cacheStorage.m_userStorage.object(ofType: User.self, forKey: m_userIDs[indexPath.row]) {

            if let cachedAvatar = try? m_cacheStorage.m_mediaStorage.object(ofType: ImageWrapper.self, forKey: user.avatar) {
                avatar = cachedAvatar.image
            }
            
            cell.nameLabel.text = user.name
            cell.avatarImage.layer.masksToBounds = true
            cell.avatarImage.layer.cornerRadius = 25
            cell.avatarImage.image = avatar
            
            if let notifications = try? m_cacheStorage.m_roomStorage.object(ofType: Int.self, forKey: m_chats[user.id]!) {
                let messagesNotification = UILabel.init(frame: CGRect(x: cell.frame.size.width - 40, y: 0, width: 30, height: 30))
                messagesNotification.center.y = 30
                messagesNotification.backgroundColor = UIColor.lightGray
                messagesNotification.textAlignment = .center
                messagesNotification.textColor = UIColor.white
                messagesNotification.layer.masksToBounds = true
                messagesNotification.layer.cornerRadius = 15
                messagesNotification.font = UIFont.boldSystemFont(ofSize: 18)
                messagesNotification.text = String(notifications)
                messagesNotification.tag = 1
                cell.contentView.addSubview(messagesNotification)
            } else if let notification = cell.viewWithTag(1) {
                notification.removeFromSuperview()
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        m_personalChatsTableView.deselectRow(at: indexPath, animated: true)
        m_index = indexPath.row
        performSegue(withIdentifier: PERSONAL_CHAT_SEGUE, sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == PERSONAL_CHAT_SEGUE {
            if let vc = segue.destination as? PersonalChatVC {
                let selectedUserID = m_userIDs[m_index!]
                let selectedChatID = m_chats[selectedUserID]
                
                vc.m_receiverUserID = selectedUserID
                vc.m_currentChatID = selectedChatID!
            }
        }
    }
    
    /**
     Delegate Functions
    **/
    
    func notificationReceived() {
        m_personalChatsTableView.reloadData()
    }
    
    func imageCacheUpdated() {
        m_personalChatsTableView.reloadData()
    }
}
