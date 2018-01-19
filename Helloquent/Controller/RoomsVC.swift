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

class RoomsVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, FetchChatRoomData, SavedChatRoom, UserEnteredRoom {
    
    @IBOutlet weak var m_roomsTableView: UITableView!
    @IBOutlet weak var m_roomsSearchBar: UISearchBar!
    
    let m_dbProvider = DBProvider.Instance
    
    var m_chatRooms = [ChatRoom]()
    var m_index: Int?
    var m_searchActive = false
    
    let CHAT_SEGUE = "chat_room_segue"
    let CELL_ID = "room_cell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        m_dbProvider.delegateSaveChatRoom = self
        
        m_roomsTableView.delegate = self
        m_roomsTableView.dataSource = self
        
        m_roomsSearchBar.delegate = self
        
       NMAPositioningManager.sharedInstance().startPositioning()
        
        setUpUI()
    }
    
    func setUpUI() {
        m_roomsTableView.backgroundColor = UIColor.init(white: 0.4, alpha: 1)
        self.navigationController?.navigationBar.barTintColor = UIColor.init(white: 0.1, alpha: 1)
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.lightText]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        m_dbProvider.delegateChatRooms = self
        m_dbProvider.delegateUserEnteredRoom = self
        m_dbProvider.observeChatRoomsAdded()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        m_dbProvider.observeChatRoomsChanged()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        m_dbProvider.removeChatRoomsObserver(withHandle: Constants.CHILD_ADDED_HANDLE)
        m_dbProvider.removeChatRoomsObserver(withHandle: Constants.CHILD_CHANGED_HANDLE)
        m_chatRooms.removeAll()
    }
    
    // SearchBar Functions
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        m_roomsSearchBar.showsCancelButton = true
        m_searchActive = true
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText != "" {
            m_chatRooms = m_chatRooms.filter { $0.name.lowercased().contains(searchText.lowercased()) }
            m_roomsTableView.reloadData()
        } else {
            m_searchActive = false
            m_dbProvider.getChatRooms()
        }
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        if m_roomsSearchBar.text == "" {
            m_searchActive = false
            m_dbProvider.getChatRooms()
        }
        m_roomsSearchBar.showsCancelButton = false
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        m_roomsSearchBar.showsCancelButton = false
        m_dbProvider.getChatRooms()
        m_roomsSearchBar.text = ""
        m_roomsSearchBar.resignFirstResponder()
        m_searchActive = false
    }
    
    // TableView Functions
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return m_chatRooms.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.subtitle,
                                   reuseIdentifier: CELL_ID)
        cell.textLabel?.text = m_chatRooms[indexPath.row].name
        cell.detailTextLabel?.text = String(m_chatRooms[indexPath.row].activeUsers) + " Active Users"
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
        let requiredPassword = m_chatRooms[m_index!].password
        if requiredPassword != "" {
            askPassword(requiredPassword: requiredPassword)
        } else {
            performSegue(withIdentifier: CHAT_SEGUE, sender: nil)
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        m_roomsSearchBar.resignFirstResponder()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == CHAT_SEGUE {
            if let vc = segue.destination as? ChatVC {
                vc.m_currentChatRoomID = m_chatRooms[m_index!].id
                vc.currentChatRoomName = m_chatRooms[m_index!].name
                DBProvider.Instance.currentRoomID = m_chatRooms[m_index!].id
            }
        }
    }
    
    @IBAction func logout(_ sender: Any) {
        
        if AuthProvider.Instance.logout() {
            dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func addRoomButton(_ sender: Any) {
        
        let alert: UIAlertController = UIAlertController.init(title: "Create A Room", message: "Enter room name", preferredStyle: .alert)
        
        let submit: UIAlertAction = UIAlertAction.init(title: "Submit", style: .default, handler: {(action: UIAlertAction) in
            
            if (alert.textFields!.count > 0 ) {
                let nameTextField: UITextField = alert.textFields![0]
                let passWordTextField: UITextField = alert.textFields![1]
                if nameTextField.text != "" {
                    DBProvider.Instance.saveChatRoom(name: nameTextField.text!, password: passWordTextField.text)
                }
            }
        })
        
        let cancel: UIAlertAction = UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(submit)
        alert.addAction(cancel)
        alert.addTextField(configurationHandler: {(nameTextField: UITextField) in
            nameTextField.placeholder = "Room Name"
            nameTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 10))
        })
        alert.addTextField(configurationHandler: {(passwordTextField: UITextField) in
            passwordTextField.placeholder = "Password"
        })
        present(alert, animated: true, completion: nil)
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
                    self.m_roomsTableView.reloadData()
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
    
    // Delegation Functions
    
    func userEnteredRoom() {
        if !m_searchActive {
            DBProvider.Instance.getChatRooms()
        }
    }
    
    func chatRoomDataReceived(chatRoom: ChatRoom) {
        if !m_searchActive {
            m_chatRooms.append(chatRoom)
            m_roomsTableView.reloadData()
        }
    }
    
    func allChatRoomDataReceived(chatRooms: [ChatRoom]) {
        if !m_searchActive {
            m_chatRooms = chatRooms
            m_roomsTableView.reloadData()
        }
    }
    
    func chatRoomSaved(success: Bool) {
        if !success {
            self.alertUser(title: "Room Name Already Exists", message: "Enter another room name")
        }
    }
    
    
    
    
    
    
}
