//
//  LocationRoomsVC.swift
//  Helloquent
//
//  Created by Morgan Trudeau on 2018-01-09.
//  Copyright © 2018 Morgan Trudeau. All rights reserved.
//

import Foundation
import UIKit
import NMAKit

class Rooms: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, FetchRoomData {
    
    @IBOutlet weak var m_roomsSearchBar: UISearchBar!
    @IBOutlet weak var m_roomsTableView: UITableView!
    
    let m_dbProvider = DBProvider.Instance
    
    var m_index: IndexPath?
    var m_rooms = [Room]()
    
    let CELL_ID = "cell"
    let CHAT_SEGUE = "chat_room_segue"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        m_roomsTableView.delegate = self
        m_roomsTableView.dataSource = self
        m_roomsSearchBar.delegate = self
        
        NMAPositioningManager.sharedInstance().startPositioning()
        
        setUpUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        m_dbProvider.delegateRooms = self
        m_roomsSearchBar.text = ""
        m_rooms.removeAll()
        m_roomsTableView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewDidAppear(animated)
        m_roomsSearchBar.resignFirstResponder()
    }
    
    func setUpUI() {
        m_roomsTableView.backgroundColor = UIColor.init(white: 0.4, alpha: 1)
        
        self.navigationController?.navigationBar.barTintColor = UIColor.init(white: 0.1, alpha: 1)
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.lightText]
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        m_roomsSearchBar.showsCancelButton = true
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        m_roomsSearchBar.showsCancelButton = false
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        m_roomsSearchBar.showsCancelButton = false
        m_roomsSearchBar.text = ""
        m_roomsSearchBar.resignFirstResponder()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if m_roomsSearchBar.text != "" {
            placesRequest(query: m_roomsSearchBar.text!)
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText == "" {
            m_rooms.removeAll()
            m_roomsTableView.reloadData()
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        m_roomsSearchBar.resignFirstResponder()
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return m_rooms.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell.init(style: UITableViewCellStyle.subtitle, reuseIdentifier: CELL_ID)
        
        // Define cell colors
        cell.textLabel?.textColor = UIColor.white
        cell.detailTextLabel?.textColor = UIColor.white
        cell.contentView.backgroundColor = UIColor.init(white: 0.4, alpha: 1)
        
        // Define cell color when selected
        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.init(white: 0.2, alpha: 1)
        cell.selectedBackgroundView = backgroundView
        
        // Create active user image view
        let activeUserImage = UIImage.init(named: "user")
        let activeUserImageView = UIImageView.init(frame: CGRect(x: self.view.frame.size.width*0.93, y: cell.contentView.bounds.height/5.2, width: 20, height: 20))
        activeUserImageView.image = activeUserImage
        
        // Create active user text view
        let activeUserTextView = UITextView.init(frame: CGRect(x: self.view.frame.size.width*0.71, y: cell.contentView.bounds.height/5.5, width: 80, height: 20))
        activeUserTextView.textAlignment = NSTextAlignment.right
        activeUserTextView.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        activeUserTextView.isEditable = false
        activeUserTextView.backgroundColor = UIColor.init(white: 0.4, alpha: 1)
        activeUserTextView.text = String(m_rooms[indexPath.row].activeUsers)
        activeUserTextView.textColor = UIColor.white
        activeUserTextView.font = UIFont.boldSystemFont(ofSize: 18)
        
        cell.contentView.addSubview(activeUserImageView)
        cell.contentView.addSubview(activeUserTextView)
        
        cell.textLabel?.text = m_rooms[indexPath.row].name
        cell.detailTextLabel?.text = m_rooms[indexPath.row].description
        
        return cell;
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Define selected index to pass to prepare for segue func
        m_index = indexPath
        
        // Segue into selected room
        performSegue(withIdentifier: CHAT_SEGUE, sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == CHAT_SEGUE {
            if let vc = segue.destination as? ChatVC {let currentRoomName = m_rooms[m_index!.row].name
                let description = m_rooms[m_index!.row].description
                let currentRoomID = m_rooms[m_index!.row].id
                vc.m_currentRoomName = currentRoomName
                vc.m_currentRoomID = currentRoomID
                
                // Pass selected room ID to dbProvider to use as child ID
                m_dbProvider.m_currentRoomID = currentRoomID
                
                // Create location room in database
                m_dbProvider.createLocationRoom(id: currentRoomID, name: currentRoomName, description: description, password: "")
            }
        }
    }
    
    func placesRequest(query: String) {
        let currentPosition = NMAPositioningManager.sharedInstance().currentPosition?.coordinates
        let bounding = NMAGeoBoundingBox.init(center: currentPosition!, width: 45, height: 45)
        
        let request: NMAAutoSuggestionRequest = (NMAPlaces.sharedInstance()?.createAutoSuggestionRequest(location: currentPosition, partialTerm: query))!
        request.viewport = bounding!
        request.collectionSize = 10
        request.start({(request: NMARequest, data: Any?, error: Error?) in
            if error == nil {
                self.m_rooms.removeAll()
                for item in data as! [NMAAutoSuggest] {
                    if let place = item as? NMAAutoSuggestPlace {
                        
                        var id = "\(place.position?.latitude ?? 1)\(place.position?.longitude ?? 1)"
                        id = id.replacingOccurrences(of: ".", with: "")
                        let htmlString: String? = place.highlightedTitle
                        let description: String? = place.vicinityDescription?.replacingOccurrences(of: "<br/>", with: ", ")
                        do {
                            let name = try NSAttributedString.init(data: (htmlString?.data(using: String.Encoding.unicode))!, options: [NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil)
                            let newRoom = Room(id: id, name: String(describing: name.string), description: description!, password: "", activeUsers: 0)
                            let index = self.m_rooms.count
                            self.m_rooms.append(newRoom)
                            self.m_dbProvider.hasRoom(roomID: self.m_rooms[index].id, index: index, completion: {(activeUsers, index) in
                                self.m_rooms[index].activeUsers = activeUsers
                                let indexPath = IndexPath(row: index, section: 0)
                                self.m_roomsTableView.reloadRows(at: [indexPath], with: .none)
                            })
                        } catch _ {
                            
                        }
                    }
                }
                self.m_roomsTableView.reloadData()
            }
        })
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
                                
                                DBProvider.Instance.createRoom(name: nameTextField.text!, description: descriptionTextField.text,   password: passWordTextField.text, roomCreated: nil)
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
    
    // Delegate Function
    
    func roomDataReceived(room: Room) {}
    
    func allRoomDataReceived(rooms: [Room]) {}
    
    
}
