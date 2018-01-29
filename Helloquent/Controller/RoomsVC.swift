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

class RoomsVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, FetchRoomData {
    
    @IBOutlet weak var m_roomsSearchBar: UISearchBar!
    @IBOutlet weak var m_roomsTableView: UITableView!
    @IBOutlet weak var m_roomsSegControl: UISegmentedControl!
    
    var m_addRoomButton: UIBarButtonItem?
    var m_roomTextImageView: UIImageView?
    let m_roomTextImage = UIImage(named: "rooms_text")
    
    let m_dbProvider = DBProvider.Instance
    
    var m_index: IndexPath?
    var m_userRooms = [Room]()
    var m_filteredUserRooms = [Room]()
    var m_locationRooms = [Room]()
    
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
        m_locationRooms.removeAll()
        m_roomsTableView.reloadData()
        
        m_roomTextImageView = UIImageView.init(frame: CGRect(x: 0, y: 0, width: 70, height: 30))
        m_roomTextImageView?.image = m_roomTextImage
        m_roomTextImageView?.center.x = (self.navigationController?.navigationBar.center.x)!
        m_roomTextImageView?.center.y = (self.navigationController?.navigationBar.center.y)! - 19
        m_roomTextImageView?.image = m_roomTextImageView?.image?.withRenderingMode(.alwaysTemplate)
        m_roomTextImageView?.tintColor = UIColor.lightText
        
        self.navigationController?.navigationBar.addSubview(m_roomTextImageView!)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewDidAppear(animated)
        m_roomsSearchBar.resignFirstResponder()
        m_roomTextImageView?.removeFromSuperview()
    }
    
    func setUpUI() {
        self.view.tintColor = UIColor(red: 133/255, green: 51/255, blue: 1, alpha: 1)
        
        m_roomsTableView.backgroundColor = UIColor.init(white: 0.4, alpha: 1)
        
        m_addRoomButton = UIBarButtonItem(image: UIImage(named: "add"), style: .plain, target: self, action: #selector(RoomsVC.addRoomButtonClicked))
        m_addRoomButton?.tintColor = UIColor(red: 133/255, green: 51/255, blue: 1, alpha: 1)
        self.navigationItem.rightBarButtonItem = m_addRoomButton
    
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
            m_locationRooms.removeAll()
            m_roomsTableView.reloadData()
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        m_roomsSearchBar.resignFirstResponder()
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return m_locationRooms.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell.init(style: UITableViewCellStyle.subtitle, reuseIdentifier: CELL_ID)
        
        cell.contentView.backgroundColor = UIColor.init(white: 0.4, alpha: 1)
        
        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.init(white: 0.2, alpha: 1)
        cell.selectedBackgroundView = backgroundView
        
        let nameTextLabel = UILabel.init(frame: CGRect(x: 10, y: 5, width: cell.frame.size.width, height: 30))
        nameTextLabel.font = UIFont.systemFont(ofSize: 18)
        nameTextLabel.textColor = UIColor.white
        
        let descriptionTextLabel = UILabel.init(frame: CGRect(x: 10, y: 28, width: cell.frame.size.width, height: 30))
        descriptionTextLabel.font = UIFont.systemFont(ofSize: 13)
        descriptionTextLabel.textColor = UIColor.white
        
        let activeUserImage = UIImage.init(named: "user")
        let activeUserImageView = UIImageView.init(frame: CGRect(x: 10, y: 60, width: 20, height: 20))
        activeUserImageView.image = activeUserImage
        
        let activeUserTextView = UILabel.init(frame: CGRect(x: 35, y: 60, width: 80, height: 20))
        activeUserTextView.text = String(m_locationRooms[indexPath.row].activeUsers)
        activeUserTextView.font = UIFont.boldSystemFont(ofSize: 18)
        activeUserTextView.textColor = UIColor.white
        
        cell.contentView.addSubview(activeUserImageView)
        cell.contentView.addSubview(activeUserTextView)
        cell.contentView.addSubview(nameTextLabel)
        cell.contentView.addSubview(descriptionTextLabel)
        
        nameTextLabel.text = m_locationRooms[indexPath.row].name
        descriptionTextLabel.text = m_locationRooms[indexPath.row].description
        
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
            if let vc = segue.destination as? ChatVC {
                
                if m_roomsSegControl.selectedSegmentIndex == 0 {
                    let currentRoomName = m_locationRooms[m_index!.row].name
                    let description = m_locationRooms[m_index!.row].description
                    let currentRoomID = m_locationRooms[m_index!.row].id
                    vc.m_currentRoomName = currentRoomName
                    vc.m_currentRoomID = currentRoomID
                    
                    // Pass selected room ID to dbProvider to use as child ID
                    m_dbProvider.m_currentRoomID = currentRoomID
                    
                    // Create location room in database
                    m_dbProvider.createLocationRoom(id: currentRoomID, name: currentRoomName, description: description, password: "")
                } else {
                    let currentRoomName = m_userRooms[m_index!.row].name
                    let description = m_userRooms[m_index!.row].description
                    let currentRoomID = m_userRooms[m_index!.row].id
                    
                    // Pass selected room ID to dbProvider to use as child ID
                    m_dbProvider.m_currentRoomID = currentRoomID
                    
                    // Create location room in database
                    m_dbProvider.createLocationRoom(id: currentRoomID, name: currentRoomName, description: description, password: "")
                }
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
                self.m_locationRooms.removeAll()
                for item in data as! [NMAAutoSuggest] {
                    if let place = item as? NMAAutoSuggestPlace {
                        
                        var id = "\(place.position?.latitude ?? 1)\(place.position?.longitude ?? 1)"
                        id = id.replacingOccurrences(of: ".", with: "")
                        let htmlString: String? = place.highlightedTitle
                        let description: String? = place.vicinityDescription?.replacingOccurrences(of: "<br/>", with: ", ")
                        do {
                            let name = try NSAttributedString.init(data: (htmlString?.data(using: String.Encoding.unicode))!, options: [NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil)
                            let newRoom = Room(id: id, name: String(describing: name.string), description: description!, password: "", activeUsers: 0)
                            let index = self.m_locationRooms.count
                            self.m_locationRooms.append(newRoom)
                            self.m_dbProvider.hasRoom(roomID: self.m_locationRooms[index].id, index: index, completion: {(activeUsers, index) in
                                self.m_locationRooms[index].activeUsers = activeUsers
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
    
    @objc func addRoomButtonClicked() {
        
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
    
    @IBAction func segIndexChanged(_ sender: Any) {
        
        switch m_roomsSegControl.selectedSegmentIndex {
            
        case 0:
            m_roomsTableView.reloadData()
        case 1:
            m_dbProvider.getRooms()
        default:
            break
        }
        
    }
    
    
    // Delegate Function
    
    func roomDataReceived(room: Room) {}
    
    func allRoomDataReceived(rooms: [Room]) {
        m_userRooms = rooms
        m_roomsTableView.reloadData()
    }
    
    
}
