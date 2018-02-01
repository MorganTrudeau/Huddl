//
//  SavedRoomsVC.swift
//  Helloquent
//
//  Created by Morgan Trudeau on 2018-01-03.
//  Copyright © 2018 Morgan Trudeau. All rights reserved.
//

import Foundation
import UIKit

class SavedRoomsVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var m_savedRoomsTableView: UITableView!
    
    let m_dbProvider = DBProvider.Instance
    
    var m_savedRoomIDs = [String]()
    var m_savedRooms = [Room]()
    var m_index: Int?
    
    let CHAT_SEGUE = "chat_room_segue"
    let CELL_ID = "cell"
    
    override func viewDidLoad() {
        m_savedRoomsTableView.delegate = self
        m_savedRoomsTableView.dataSource = self
        setUpUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        m_savedRoomsTableView.reloadData()
        CoreDataProvider.Instance.fetchRoomCoreData(coreRoomDataReceived: {(savedRoomIDs) in
            if self.m_savedRoomIDs.count != savedRoomIDs.count {
                self.m_savedRoomIDs = savedRoomIDs
                self.m_dbProvider.getSavedRooms(savedIDs: self.m_savedRoomIDs, completion: {(rooms) in
                    self.m_savedRooms = rooms
                    self.m_savedRoomsTableView.reloadData()
                })
            }
        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    func setUpUI() {
        self.navigationController?.navigationBar.barTintColor = UIColor.init(white: 0.1, alpha: 1)
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.lightText]
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
                                   reuseIdentifier: CELL_ID)
        
        let nameTextLabel = UILabel.init(frame: CGRect(x: 10, y: 5, width: cell.frame.size.width, height: 30))
        nameTextLabel.font = UIFont.systemFont(ofSize: 18)
        
        let descriptionTextLabel = UILabel.init(frame: CGRect(x: 10, y: 28, width: cell.frame.size.width, height: 30))
        descriptionTextLabel.font = UIFont.systemFont(ofSize: 13)
        
        let activeUserImage = UIImage.init(named: "user")
        let activeUserImageView = UIImageView.init(frame: CGRect(x: 10, y: 60, width: 20, height: 20))
        activeUserImageView.image = activeUserImage
        
        let activeUserTextView = UILabel.init(frame: CGRect(x: 35, y: 60, width: 80, height: 20))
        activeUserTextView.text = String(m_savedRooms[indexPath.row].activeUsers)
        activeUserTextView.font = UIFont.boldSystemFont(ofSize: 18)
        
        cell.contentView.addSubview(activeUserImageView)
        cell.contentView.addSubview(activeUserTextView)
        cell.contentView.addSubview(nameTextLabel)
        cell.contentView.addSubview(descriptionTextLabel)
        
        nameTextLabel.text = m_savedRooms[indexPath.row].name
        descriptionTextLabel.text = m_savedRooms[indexPath.row].description
        
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        m_savedRoomsTableView.deselectRow(at: indexPath, animated: true)
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
} // class
