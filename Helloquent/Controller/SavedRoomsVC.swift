//
//  SavedRoomsVC.swift
//  Helloquent
//
//  Created by Morgan Trudeau on 2018-01-03.
//  Copyright © 2018 Morgan Trudeau. All rights reserved.
//

import Foundation
import UIKit

class SavedRoomsVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UserEnteredRoom, FetchRoomData, FetchRoomCoreData {
    
    @IBOutlet weak var m_savedRoomsTableView: UITableView!
    
    let m_dbProvider = DBProvider.Instance
    
    var m_savedRoomIDs = [String]()
    var m_savedRooms = [Room]()
    var m_index: Int?
    
    let CHAT_SEGUE = "chat_room_segue"
    let CELL_ID = "room_cell"
    
    override func viewDidLoad() {
        setUpUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        m_dbProvider.delegateRooms = self
        m_dbProvider.delegateUserEnteredRoom = self
        m_dbProvider.getRooms()
        
        CoreDataHandler.Instance.delegate = self
        CoreDataHandler.Instance.fetchRoomCoreData()
        
        m_savedRoomsTableView.delegate = self
        m_savedRoomsTableView.dataSource = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        m_dbProvider.observeRoomsChanged()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        m_dbProvider.removeRoomsObserver(withHandle: Constants.CHILD_CHANGED_HANDLE)
        m_savedRooms.removeAll()
    }
    
    func setUpUI() {
        m_savedRoomsTableView.backgroundColor = UIColor.init(white: 0.4, alpha: 1)
        self.navigationController?.navigationBar.barTintColor = UIColor.init(white: 0.1, alpha: 1)
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.lightText]
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return m_savedRooms.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.subtitle,
                                   reuseIdentifier: CELL_ID)
        cell.textLabel?.text = m_savedRooms[indexPath.row].name
        cell.detailTextLabel?.text = String(m_savedRooms[indexPath.row].activeUsers) + " Active Users"
        cell.textLabel?.textColor = UIColor.white
        cell.detailTextLabel?.textColor = UIColor.white
        cell.contentView.backgroundColor = UIColor.init(white: 0.4, alpha: 1)
        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.init(white: 0.2, alpha: 1)
        cell.selectedBackgroundView = backgroundView
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        m_index = indexPath.row
        let requiredPassword = m_savedRooms[m_index!].password
        if requiredPassword != "" {
            askPassword(requiredPassword: requiredPassword)
        } else {
            performSegue(withIdentifier: CHAT_SEGUE, sender: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == CHAT_SEGUE {
            if let vc = segue.destination as? ChatVC {
                vc.m_currentRoomID = m_savedRooms[m_index!].id
                vc.m_currentRoomName = m_savedRooms[m_index!].name
                m_dbProvider.m_currentRoomID = m_savedRooms[m_index!].id
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
    
    // Delegation functions
    
    func userEnteredRoom() {
        m_dbProvider.getRooms()
    }
    
    func roomDataReceived(room: Room) {
        
    }
    
    func allRoomDataReceived(rooms: [Room]) {
        if m_savedRoomIDs.count > 0 {
            for id in m_savedRoomIDs {
                let index = rooms.index { $0.id == id }
                m_savedRooms.append(rooms[index!])
            }
            m_savedRoomsTableView.reloadData()
        }
    }
    
    func coreRoomDataReceived(savedRoomIDs: [String]) {
        m_savedRoomIDs = savedRoomIDs
        m_savedRoomsTableView.reloadData()
    }
    
    
    
    
    

}
