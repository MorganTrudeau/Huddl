//
//  BlockListVC.swift
//  Helloquent
//
//  Created by Morgan Trudeau on 2018-03-22.
//  Copyright © 2018 Morgan Trudeau. All rights reserved.
//

import UIKit
import Cache

class BlockListVC: UIViewController, UITableViewDataSource, UITableViewDelegate, ImageCacheDelegate {

    @IBOutlet weak var m_blockedListTableView: UITableView!
    let m_cacheStorage = CacheStorage.Instance
    var m_blockedUsers = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        m_cacheStorage.imageCacheDelegate = self
        setUpUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadChats()
    }
    
    func loadChats() {
        if let blockedUsers = try? m_cacheStorage.m_userStorage.object(ofType: [String].self, forKey: "blockedUsers") {
            for userID in blockedUsers {
                m_blockedUsers = blockedUsers
                print(userID)
                DBProvider.Instance.getUser(id: userID, completion: nil)
            }
        }
        m_blockedListTableView.reloadData()
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
        return m_blockedUsers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "chat_cell", for: indexPath) as! ChatTableViewCell
        
        var avatar = UIImage(named: "user")
        
        if let user = try? m_cacheStorage.m_userStorage.object(ofType: User.self, forKey: m_blockedUsers[indexPath.row]) {
            
            if let cachedAvatar = try? m_cacheStorage.m_mediaStorage.object(ofType: ImageWrapper.self, forKey: user.avatar) {
                avatar = cachedAvatar.image
            }
            
            cell.nameLabel.text = user.name
            cell.avatarImage.layer.masksToBounds = true
            cell.avatarImage.layer.cornerRadius = 25
            cell.avatarImage.image = avatar
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        m_blockedListTableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]?
    {
        let delete = UITableViewRowAction(style: UITableViewRowActionStyle.default, title: "DELETE"){(UITableViewRowAction,IndexPath) -> Void in
            let blockedUser = self.m_blockedUsers[indexPath.row]
            self.m_cacheStorage.unblockUser(userID: blockedUser)
            DBProvider.Instance.unblockUser(userID: blockedUser)
            self.m_blockedUsers = self.m_blockedUsers.filter { $0 != blockedUser }
            self.m_blockedListTableView.reloadData()
        }
        delete.backgroundColor = UIColor.red
        return [delete]
    }
    
    
    
    /**
     Delegate Functions
     **/
    
    func imageCacheUpdated() {
        m_blockedListTableView.reloadData()
    }
}
