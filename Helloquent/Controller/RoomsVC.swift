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

class RoomsVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, FetchRoomData, CreateRoom, UserEnteredRoom {
    
    @IBOutlet weak var m_roomsTableView: UITableView!
    @IBOutlet weak var m_roomsSearchBar: UISearchBar!
    
    let m_dbProvider = DBProvider.Instance
    
    var m_rooms = [Room]()
    var m_filteredRooms = [Room]()
    var m_index: Int?
    var m_searchActive = false
    
    let CHAT_SEGUE = "chat_room_segue"
    let CELL_ID = "room_cell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        m_dbProvider.delegateCreateRoom = self
        
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
        m_dbProvider.delegateRooms = self
        m_dbProvider.delegateUserEnteredRoom = self
        m_dbProvider.observeRoomsAdded()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        m_dbProvider.observeRoomsChanged()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        m_dbProvider.removeRoomsObserver(withHandle: Constants.CHILD_ADDED_HANDLE)
        m_dbProvider.removeRoomsObserver(withHandle: Constants.CHILD_CHANGED_HANDLE)
        m_rooms.removeAll()
        m_roomsSearchBar.resignFirstResponder()
        m_roomsSearchBar.text = ""
    }
    
    // SearchBar Functions
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        m_roomsSearchBar.showsCancelButton = true
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText != "" {
            m_searchActive = true
            m_filteredRooms = m_rooms.filter { $0.name.lowercased().contains(searchText.lowercased()) }
            m_roomsTableView.reloadData()
        } else {
            m_searchActive = false
            m_roomsTableView.reloadData()
        }
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        m_roomsSearchBar.showsCancelButton = false
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        m_roomsSearchBar.showsCancelButton = false
        m_dbProvider.getRooms()
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
        if !m_searchActive {
            return m_rooms.count
        } else {
            return m_filteredRooms.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.subtitle,
                                   reuseIdentifier: CELL_ID)
        cell.textLabel?.textColor = UIColor.white
        cell.detailTextLabel?.textColor = UIColor.white
        cell.contentView.backgroundColor = UIColor.init(white: 0.4, alpha: 1)
        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.init(white: 0.2, alpha: 1)
        cell.selectedBackgroundView = backgroundView
        
        let activeUserImage = UIImage.init(named: "user")
        let activeUserImageView = UIImageView.init(frame: CGRect(x: self.view.frame.size.width*0.93, y: cell.contentView.bounds.height/4.3, width: 20, height: 20))
        activeUserImageView.image = activeUserImage
        
        let activeUserTextView = UITextView.init(frame: CGRect(x: self.view.frame.size.width*0.73, y: cell.contentView.bounds.height/5.2, width: 80, height: 20))
        activeUserTextView.textAlignment = NSTextAlignment.right
        activeUserTextView.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        activeUserTextView.isEditable = false
        activeUserTextView.backgroundColor = UIColor.init(white: 0.4, alpha: 1)
        activeUserTextView.text = String(m_rooms[indexPath.row].activeUsers)
        activeUserTextView.textColor = UIColor.white
        activeUserTextView.font = UIFont.boldSystemFont(ofSize: 18)
        
        cell.contentView.addSubview(activeUserImageView)
        cell.contentView.addSubview(activeUserTextView)
        
        if !m_searchActive {
            cell.textLabel?.text = m_rooms[indexPath.row].name
            cell.detailTextLabel?.text = m_rooms[indexPath.row].description
        } else {
            cell.textLabel?.text = m_filteredRooms[indexPath.row].name
            cell.detailTextLabel?.text = m_filteredRooms[indexPath.row].description
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        m_index = indexPath.row
        m_roomsTableView.deselectRow(at: indexPath, animated: false)
        if !m_searchActive {
            let requiredPassword = m_rooms[indexPath.row].password
            if requiredPassword != "" {
                askPassword(requiredPassword: requiredPassword)
            } else {
                performSegue(withIdentifier: CHAT_SEGUE, sender: nil)
            }
        } else {
            let requiredPassword = m_filteredRooms[indexPath.row].password
            if requiredPassword != "" {
                askPassword(requiredPassword: requiredPassword)
            } else {
                performSegue(withIdentifier: CHAT_SEGUE, sender: nil)
            }
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        m_roomsSearchBar.resignFirstResponder()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == CHAT_SEGUE {
            if let vc = segue.destination as? ChatVC {
                if !m_searchActive {
                    vc.m_currentRoomID = m_rooms[m_index!].id
                    vc.m_currentRoomName = m_rooms[m_index!].name
                    m_dbProvider.m_currentRoomID = m_rooms[m_index!].id
                } else {
                    vc.m_currentRoomID = m_filteredRooms[m_index!].id
                    vc.m_currentRoomName = m_filteredRooms[m_index!].name
                    m_dbProvider.m_currentRoomID = m_filteredRooms[m_index!].id
                }
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
                let descriptionTextField: UITextField = alert.textFields![1]
                let passWordTextField: UITextField = alert.textFields![2]
                if nameTextField.text != "" {
                    
                    if descriptionTextField.text != "" {
                    
                        if nameTextField.text!.size(withAttributes: [NSAttributedStringKey.font : UIFont.systemFont(ofSize: 17)]).width < CGFloat(self.view.frame.size.width*0.65) {
                        
                            if descriptionTextField.text!.size(withAttributes: [NSAttributedStringKey.font : UIFont.systemFont(ofSize: 12)]).width < CGFloat(self.view.frame.size.width*0.65) {
                            
                                DBProvider.Instance.createRoom(name: nameTextField.text!, description: descriptionTextField.text,   password: passWordTextField.text)
                            } else {
                                self.alertUser(title: "Invalid Format", message: "Room description too long")
                            }
                        } else {
                            self.alertUser(title: "Invalid Format", message: "Room name too long")
                        }
                    } else {
                        self.alertUser(title: "Invalid Format", message: "Enter a room description")
                    }
                } else {
                    self.alertUser(title: "Invalid Format", message: "Enter a room name.")
                }
            }
        })
        
        let cancel: UIAlertAction = UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(submit)
        alert.addAction(cancel)
        alert.addTextField(configurationHandler: {(nameTextField: UITextField) in
            nameTextField.placeholder = "Room Name"
        })
        alert.addTextField(configurationHandler: {(descriptionTextField: UITextField) in
            descriptionTextField.placeholder = "Description"
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
            m_dbProvider.getRooms()
        }
    }
    
    func roomDataReceived(room: Room) {
        if !m_searchActive {
            m_rooms.append(room)
            m_filteredRooms.append(room)
            m_roomsTableView.reloadData()
        }
    }
    
    func allRoomDataReceived(rooms: [Room]) {
        if !m_searchActive {
            m_rooms = rooms
            m_filteredRooms = m_rooms
            m_roomsTableView.reloadData()
        }
    }
    
    func activeUserDataReceived(activeUsers: Int, index: Int) {
        
    }
    
    func roomCreated(success: Bool) {
        if !success {
            self.alertUser(title: "Room Name Already Exists", message: "Enter another room name")
        }
    }
    
    
    
    
    
    
}
