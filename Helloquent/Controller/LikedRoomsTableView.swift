//
//  RoomsVC.swift
//  Helloquent
//
//  Created by Morgan Trudeau on 2018-01-17.
//  Copyright © 2018 Morgan Trudeau. All rights reserved.
//

import Foundation
import UIKit
import NMAKit

class LikedRoomsTableView: UIViewController, UITableViewDelegate, UITableViewDataSource, RoomContainerDelegate {
    
    @IBOutlet weak var m_likedRoomsTableView: UITableView!
    
    let m_dbProvider = DBProvider.Instance
    
    var m_likedRooms = [Room]()
    var m_filteredRooms = [Room]()
    var m_index: Int?
    var m_query = ""
    var m_queryCounter = 2
    
    lazy var m_refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action:
            #selector(LikedRoomsTableView.handleRefresh(_:)),
                                 for: UIControlEvents.valueChanged)
        refreshControl.tintColor = UIColor(red: 102/255, green: 0, blue: 1, alpha: 1)
        return refreshControl
    }()
    
    let CHAT_SEGUE = "chat_room_segue"
    let CELL_ID = "cell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        m_likedRoomsTableView.addSubview(m_refreshControl)
        
        m_likedRoomsTableView.delegate = self
        m_likedRoomsTableView.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        m_dbProvider.getLikedRooms(completion: {(rooms) in
            self.m_likedRooms = rooms
            self.m_filteredRooms = rooms
            self.m_likedRoomsTableView.reloadData()
        })
    }
    
    // TableView Functions
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return m_filteredRooms.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.subtitle,
                                   reuseIdentifier: CELL_ID)
        
        let nameTextLabel = UILabel.init(frame: CGRect(x: 10, y: 5, width: cell.frame.size.width, height: 30))
        nameTextLabel.font = UIFont.systemFont(ofSize: 18)
        
        let descriptionTextLabel = UILabel.init(frame: CGRect(x: 10, y: 28, width: cell.frame.size.width, height: 30))
        descriptionTextLabel.font = UIFont.systemFont(ofSize: 13)
        
        let likesImage = UIImage.init(named: "heart")
        let likesImageView = UIImageView.init(frame: CGRect(x: 10, y: 60, width: 20, height: 20))
        likesImageView.image = likesImage
        
        let likesTextView = UILabel.init(frame: CGRect(x: 35, y: 60, width: 80, height: 20))
        likesTextView.text = String(m_filteredRooms[indexPath.row].likes)
        likesTextView.font = UIFont.boldSystemFont(ofSize: 18)
        
        cell.contentView.addSubview(likesImageView)
        cell.contentView.addSubview(likesTextView)
        cell.contentView.addSubview(nameTextLabel)
        cell.contentView.addSubview(descriptionTextLabel)
        
        nameTextLabel.text = m_filteredRooms[indexPath.row].name
        descriptionTextLabel.text = m_filteredRooms[indexPath.row].description
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        m_index = indexPath.row
        m_likedRoomsTableView.deselectRow(at: indexPath, animated: false)
        let requiredPassword = m_filteredRooms[indexPath.row].password
        if requiredPassword != "" {
            askPassword(requiredPassword: requiredPassword)
        } else {
            performSegue(withIdentifier: CHAT_SEGUE, sender: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == CHAT_SEGUE {
            if let vc = segue.destination as? ChatVC {
                let selectedRoom = m_filteredRooms[m_index!]
                
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
    
    @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
        m_dbProvider.getLikedRooms(completion: {(rooms) in
            self.m_likedRooms = rooms
            if self.m_query != "" {
                self.m_filteredRooms = self.m_likedRooms.filter { $0.name.lowercased().contains(self.m_query.lowercased()) }
            } else {
                self.m_filteredRooms = rooms
            }
            self.m_likedRoomsTableView.reloadData()
            self.m_refreshControl.endRefreshing()
        })
    }
    
    // Delegate Functions
    
    func textChanged(query: String) {
        let queryLength = query.count
        m_query = query
        
        if queryLength == 0 {
            m_filteredRooms = m_likedRooms
            m_queryCounter = 2
        } else if queryLength < m_queryCounter {
            m_filteredRooms = m_likedRooms.filter { $0.name.lowercased().contains(query.lowercased()) }
            m_queryCounter = queryLength
        } else {
            m_filteredRooms = m_filteredRooms.filter { $0.name.lowercased().contains(query.lowercased()) }
            m_queryCounter = queryLength
        }
        m_likedRoomsTableView.reloadData()
    }
    
    func roomCreated(room: Room) {}
    
    
    
    
}
