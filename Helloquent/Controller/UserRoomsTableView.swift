//
//  UserRoomsTableView.swift
//  Helloquent
//
//  Created by Morgan Trudeau on 2018-01-25.
//  Copyright © 2018 Morgan Trudeau. All rights reserved.
//

import Foundation
import UIKit

class UserRoomsTableView: UIViewController, UITableViewDelegate, UITableViewDataSource, RoomContainerDelegate {
    
    @IBOutlet weak var m_userRoomsTableView: UITableView!
    
    let m_dbProvider = DBProvider.Instance
    
    var m_userRooms = [Room]()
    var m_filteredRooms = [Room]()
    var m_index: Int?
    var m_query = ""
    var m_queryCounter = 2
    
    lazy var m_refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action:
            #selector(UserRoomsTableView.handleRefresh(_:)),
                                 for: UIControlEvents.valueChanged)
        refreshControl.tintColor = UIColor.red
        
        return refreshControl
    }()
    
    let CHAT_SEGUE = "chat_room_segue"
    let CELL_ID = "cell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        m_userRoomsTableView.delegate = self
        m_userRoomsTableView.dataSource = self
        
        m_dbProvider.getUserRooms(completion: {(rooms) in
            self.m_userRooms = rooms
            self.m_filteredRooms = rooms
            self.m_userRoomsTableView.reloadData()
        })
        
        m_userRoomsTableView.addSubview(m_refreshControl)
        
        setUpUI()
    }
    
    func setUpUI() {
    }
    
    // TableView Functions
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
            return m_filteredRooms.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.subtitle,
                                   reuseIdentifier: CELL_ID)
        
        cell.textLabel?.text = m_filteredRooms[indexPath.row].name
        cell.detailTextLabel?.text = m_filteredRooms[indexPath.row].description
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        m_index = indexPath.row
        m_userRoomsTableView.deselectRow(at: indexPath, animated: false)
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
                vc.m_currentRoomID = m_filteredRooms[m_index!].id
                vc.m_currentRoomName = m_filteredRooms[m_index!].name
                m_dbProvider.m_currentRoomID = m_filteredRooms[m_index!].id
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
        m_dbProvider.getUserRooms(completion: {(rooms) in
            self.m_userRooms = rooms
            if self.m_query != "" {
                self.m_filteredRooms = self.m_userRooms.filter { $0.name.lowercased().contains(self.m_query.lowercased()) }
            }
            self.m_userRoomsTableView.reloadData()
            self.m_refreshControl.endRefreshing()
        })
    }
    
    // Delegate Functions
    
    func textChanged(query: String) {
        let queryLength = query.count
        m_query = query
        
        if queryLength == 0 {
            m_filteredRooms = m_userRooms
            m_queryCounter = 2
        } else if queryLength < m_queryCounter {
            m_filteredRooms = m_userRooms.filter { $0.name.lowercased().contains(query.lowercased()) }
            m_queryCounter = queryLength
        } else {
            m_filteredRooms = m_filteredRooms.filter { $0.name.lowercased().contains(query.lowercased()) }
            m_queryCounter = queryLength
        }
        m_userRoomsTableView.reloadData()
    }
    
    func roomCreated(room: Room) {
        m_userRooms.append(room)
        if m_query != "" {
            if room.name.lowercased().contains(m_query.lowercased()) {
                m_filteredRooms.append(room)
            }
        } else {
            m_filteredRooms.append(room)
        }
        m_userRoomsTableView.reloadData()
    }
} // class
