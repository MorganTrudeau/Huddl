//
//  ChatRoomsVC.swift
//  Helloquent
//
//  Created by Morgan Trudeau on 2018-01-03.
//  Copyright © 2018 Morgan Trudeau. All rights reserved.
//

import UIKit

class ChatRoomsVC: UIViewController, UITableViewDelegate, UITableViewDataSource, FetchChatRoomData, SavedChatRoom {
    
    @IBOutlet weak var addRoomButton: UIBarButtonItem!

    @IBOutlet weak var chatRoomTableView: UITableView!
    
    var chatRooms = [ChatRoom]()
    
    var index: Int?
    
    let CHAT_SEGUE = "chat_room_segue"
    let CELL_ID = "chat_room_cell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        DBProvider.Instance.delegateChatRooms = self
        DBProvider.Instance.delegateSaveChatRoom = self
        DBProvider.Instance.getChatRooms()
    }
    
    func chatRoomDataReceived(chatRooms: [ChatRoom]) {
        self.chatRooms = chatRooms
        
        chatRoomTableView.reloadData()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatRooms.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: CELL_ID, for: indexPath)
        cell.textLabel?.text = chatRooms[indexPath.row].name
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        index = indexPath.row
        performSegue(withIdentifier: CHAT_SEGUE, sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == CHAT_SEGUE {
            if let vc = segue.destination as? ChatVC {
                vc.currentChatRoomId = chatRooms[index!].id
                vc.currentChatRoomName = chatRooms[index!].name
                DBProvider.Instance.currentRoomName = chatRooms[index!].name
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
        
        alert.addAction(submit)
        alert.addTextField(configurationHandler: {(nameTextField: UITextField) in
            nameTextField.placeholder = "Room Name"
        })
        alert.addTextField(configurationHandler: {(passwordTextField: UITextField) in
            passwordTextField.placeholder = "Password"
        })
        present(alert, animated: true, completion: nil)
    }
    
    func chatRoomSaved(success: Bool) {
        if success {
            DBProvider.Instance.getChatRooms()
        } else {
            self.alertUser(title: "Room Name Already Exists", message: "Enter another room name")
        }
    }
    
    func alertUser(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }
    
    
    
    
    
    
    

}
