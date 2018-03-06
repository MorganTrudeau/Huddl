//
//  TabBarVC.swift
//  Helloquent
//
//  Created by Morgan Trudeau on 2018-01-16.
//  Copyright © 2018 Morgan Trudeau. All rights reserved.
//

import UIKit

class TabBarVC: UITabBarController {
    
    let m_cacheStorage = CacheStorage.Instance

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.tintColor = UIColor(red: 133/255, green: 51/255, blue: 1, alpha: 1)
        tabBar.barTintColor = UIColor.init(white: 0.2, alpha: 1)
        
        if let roomNotifications = try? m_cacheStorage.m_roomStorage.object(ofType: [String].self, forKey: "room") {
            if roomNotifications.count > 0 {
                self.tabBar.items![0].badgeValue = String(roomNotifications.count)
            } else {
                self.tabBar.items![0].badgeValue = nil
            }
        }
        if let chatNotifications = try? m_cacheStorage.m_roomStorage.object(ofType: [String].self, forKey: "chat") {
            if chatNotifications.count > 0 {
                self.tabBar.items![1].badgeValue = String(chatNotifications.count)
            } else {
                self.tabBar.items![1].badgeValue = nil
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(TabBarVC.setBadge), name: NSNotification.Name(rawValue: "SetBadge"), object: nil)
    }
    
    @objc func setBadge(_ notification: NSNotification) {
        if let roomID = notification.userInfo!["room_id"] as? String {
            if var roomNotifications = try? m_cacheStorage.m_roomStorage.object(ofType: [String].self, forKey: "room") {
                if !roomNotifications.contains(roomID) {
                    roomNotifications.append(roomID)
                    self.tabBar.items![0].badgeValue = String(roomNotifications.count)
                    m_cacheStorage.cacheTabNotifications(notifications: roomNotifications, type: "room")
                }
            } else {
                let roomNotifications = [roomID]
                self.tabBar.items![0].badgeValue = "1"
                m_cacheStorage.cacheTabNotifications(notifications: roomNotifications, type: "room")
            }
        } else if let chatID = notification.userInfo!["chat_id"] as? String {
            if var chatNotifications = try? m_cacheStorage.m_roomStorage.object(ofType: [String].self, forKey: "chat") {
                if !chatNotifications.contains(chatID) {
                    chatNotifications.append(chatID)
                    self.tabBar.items![1].badgeValue = String(chatNotifications.count)
                    m_cacheStorage.cacheTabNotifications(notifications: chatNotifications, type: "chat")
                }
            } else {
                let chatNotifications = [chatID]
                self.tabBar.items![1].badgeValue = "1"
                m_cacheStorage.cacheTabNotifications(notifications: chatNotifications, type: "chat")
            }
        }
    }

}
