//
//  SavedRoomsVC.swift
//  Helloquent
//
//  Created by Morgan Trudeau on 2018-01-03.
//  Copyright © 2018 Morgan Trudeau. All rights reserved.
//

import Foundation
import UIKit

class SavedRoomsTableView: UIViewController, UITableViewDelegate, UITableViewDataSource, RoomContainerDelegate, LikesDelegate, NotificationCacheDelegate {
    
    @IBOutlet weak var m_savedRoomsTableView: UITableView!
    
    let m_dbProvider = DBProvider.Instance
    let m_cacheStorage = CacheStorage.Instance
    
    var m_savedRooms = [Room]()
    var m_filteredRooms = [Room]()
    var m_index: Int?
    var m_query = ""
    var m_queryCounter = 2
    
    let CHAT_SEGUE = "chat_room_segue"
    
    override func viewDidLoad() {
        m_savedRoomsTableView.delegate = self
        m_savedRoomsTableView.dataSource = self
        m_cacheStorage.notificationCacheDelegate = self
        m_dbProvider.delegateLikes = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let savedRooms = try? m_cacheStorage.m_roomStorage.object(ofType: [Room].self, forKey: "saved") {
            m_savedRooms = savedRooms
            m_savedRoomsTableView.reloadData()
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return m_savedRooms.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.subtitle,
                                   reuseIdentifier: "cell")
        
        let nameTextLabel = UILabel.init(frame: CGRect(x: 10, y: 5, width: cell.frame.size.width, height: 30))
        nameTextLabel.font = UIFont.systemFont(ofSize: 18)
        
        let descriptionTextLabel = UILabel.init(frame: CGRect(x: 10, y: 28, width: cell.frame.size.width, height: 30))
        descriptionTextLabel.font = UIFont.systemFont(ofSize: 13)
        
        let likesImage = UIImage.init(named: "heart")
        let likesImageView = UIImageView.init(frame: CGRect(x: 10, y: 60, width: 20, height: 20))
        likesImageView.image = likesImage
        
        let likesTextView = UILabel.init(frame: CGRect(x: 35, y: 60, width: 80, height: 20))
        likesTextView.text = "0"
        likesTextView.font = UIFont.boldSystemFont(ofSize: 18)
        likesTextView.tag = 1
        DispatchQueue.global().async {
            self.m_dbProvider.getLikes(id: self.m_savedRooms[indexPath.row].id, indexPath: indexPath)
        }
        
        if let notifications = try? m_cacheStorage.m_roomStorage.object(ofType: Int.self, forKey: m_savedRooms[indexPath.row].id) {
            let messagesNotification = UILabel.init(frame: CGRect(x: cell.frame.size.width, y: 0, width: 30, height: 30))
            messagesNotification.center.y = 45
            messagesNotification.backgroundColor = UIColor.lightGray
            messagesNotification.textAlignment = .center
            messagesNotification.textColor = UIColor.white
            messagesNotification.layer.masksToBounds = true
            messagesNotification.layer.cornerRadius = 15
            messagesNotification.font = UIFont.boldSystemFont(ofSize: 18)
            messagesNotification.text = String(notifications)
            cell.contentView.addSubview(messagesNotification)
        }
        
        cell.contentView.addSubview(likesImageView)
        cell.contentView.addSubview(likesTextView)
        cell.contentView.addSubview(nameTextLabel)
        cell.contentView.addSubview(descriptionTextLabel)
        
        nameTextLabel.text = m_savedRooms[indexPath.row].name
        descriptionTextLabel.text = m_savedRooms[indexPath.row].description
        
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        m_savedRoomsTableView.deselectRow(at: indexPath, animated: true)
        m_index = indexPath.row
        performSegue(withIdentifier: CHAT_SEGUE, sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == CHAT_SEGUE {
            if let vc = segue.destination as? ChatVC {
                let selectedRoom = m_savedRooms[m_index!]
                
                let room = Room(name: selectedRoom.name, description: selectedRoom.description, id: selectedRoom.id, password: selectedRoom.password, likes: selectedRoom.likes)
                
                vc.m_currentRoom = room
                
                // Pass selected Room to DBProvider so it knows where to save
                m_dbProvider.m_currentRoom = room
            }
        }
    }
    
    func alertUser(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }
    
    func askPassword(requiredPassword: String) {
        let alert = UIAlertController(title: "Room Password", message: "Please enter password", preferredStyle: .alert)
        let submit = UIAlertAction(title: "Submit", style: .default, handler: {(action: UIAlertAction) in
            
            if alert.textFields!.count > 0 {
                let passwordTextField =  alert.textFields![0]
                if passwordTextField.text == requiredPassword {
                    self.performSegue(withIdentifier: self.CHAT_SEGUE, sender: nil)
                } else {
                    self.alertUser(title: "Incorrect Password", message: "Please try again")
                    self.m_savedRoomsTableView.reloadData()
                }
            }
        })
        let cancel: UIAlertAction = UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(cancel)
        alert.addAction(submit)
        alert.addTextField(configurationHandler: {(passwordTextField: UITextField) in
            passwordTextField.placeholder = "Password"
        })
        present(alert, animated: true, completion: nil)
    }
    
    // Delegate Functions
    
    func textChanged(query: String) {
        let queryLength = query.count
        m_query = query
        
        if queryLength == 0 {
            m_filteredRooms = m_savedRooms
            m_queryCounter = 2
        } else if queryLength < m_queryCounter {
            m_filteredRooms = m_savedRooms.filter { $0.name.lowercased().contains(query.lowercased()) }
            m_queryCounter = queryLength
        } else {
            m_filteredRooms = m_filteredRooms.filter { $0.name.lowercased().contains(query.lowercased()) }
            m_queryCounter = queryLength
        }
        m_savedRoomsTableView.reloadData()
    }
    
    func roomCreated(room: Room) {}
    
    func likesReceived(likes: Int, indexPath: IndexPath) {
        let cell = m_savedRoomsTableView.cellForRow(at: indexPath)
        let likesTextView = cell?.viewWithTag(1) as! UILabel
        likesTextView.text = String(likes)
    }
    
    func notificationReceived() {
        m_savedRoomsTableView.reloadData()
    }
    
} // class
