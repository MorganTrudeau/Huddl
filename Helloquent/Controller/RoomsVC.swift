//
//  RoomsVC.swift
//  Helloquent
//
//  Created by Morgan Trudeau on 2018-01-17.
//  Copyright © 2018 Morgan Trudeau. All rights reserved.
//

import Foundation
import UIKit

class RoomsVC: UIViewController, UITableViewDelegate, UITableViewDataSource, FetchChatRoomData, SavedChatRoom, UserEnteredRoom {
    
    @IBOutlet weak var roomsTableView: UITableView!
    
    @IBOutlet weak var roomSearchBar: UISearchBar!
    
    var chatRooms = [ChatRoom]()
    var index: Int?
    
    let CHAT_SEGUE = "chat_room_segue"
    let CELL_ID = "room_cell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        DBProvider.Instance.delegateChatRooms = self
        DBProvider.Instance.delegateSaveChatRoom = self
        DBProvider.Instance.delegateUserEnteredRoom = self
        
        setUpUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        DBProvider.Instance.getChatRooms()
        DBProvider.Instance.observeChatRoomsAdded()
        DBProvider.Instance.observeChatRoomsChanged()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        DBProvider.Instance.removeChatRoomsObserver(withHandle: Constants.CHILD_ADDED_HANDLE)
        DBProvider.Instance.removeChatRoomsObserver(withHandle: Constants.CHILD_CHANGED_HANDLE)
    }
    
    func setUpUI() {
        self.roomsTableView.backgroundColor = UIColor.init(white: 0.4, alpha: 1)
        self.navigationController?.navigationBar.barTintColor = UIColor.init(white: 0.1, alpha: 1)
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.lightText]
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatRooms.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.subtitle,
                                   reuseIdentifier: CELL_ID)
        cell.textLabel?.text = chatRooms[indexPath.row].name
        cell.detailTextLabel?.text = String(chatRooms[indexPath.row].activeUsers) + " Active Users"
        cell.textLabel?.textColor = UIColor.white
        cell.detailTextLabel?.textColor = UIColor.white
        cell.contentView.backgroundColor = UIColor.init(white: 0.4, alpha: 1)
        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.init(white: 0.2, alpha: 1)
        cell.selectedBackgroundView = backgroundView
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        index = indexPath.row
        let requiredPassword = chatRooms[index!].password
        if requiredPassword != "" {
            askPassword(requiredPassword: requiredPassword)
        } else {
            performSegue(withIdentifier: CHAT_SEGUE, sender: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == CHAT_SEGUE {
            if let vc = segue.destination as? ChatVC {
                vc.currentChatRoomID = chatRooms[index!].id
                vc.currentChatRoomName = chatRooms[index!].name
                DBProvider.Instance.currentRoomID = chatRooms[index!].id
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
                    self.roomsTableView.reloadData()
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
       DBProvider.Instance.getChatRooms()
    }
    
    func chatRoomDataReceived(chatRoom: ChatRoom) {
        self.chatRooms.append(chatRoom)
        roomsTableView.reloadData()
    }
    
    func allChatRoomDataReceived(chatRooms: [ChatRoom]) {
        self.chatRooms = chatRooms
        roomsTableView.reloadData()
    }
    
    func chatRoomSaved(success: Bool) {
        if !success {
            self.alertUser(title: "Room Name Already Exists", message: "Enter another room name")
        }
    }
    
    
    
    
    
    
}
