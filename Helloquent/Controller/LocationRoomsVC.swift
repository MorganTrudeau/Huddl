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

class LocationRooms: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, FetchRoomData {
    
    @IBOutlet weak var m_placesSearchBar: UISearchBar!
    @IBOutlet weak var m_placesTableView: UITableView!
    
    let m_dbProvider = DBProvider.Instance
    
    var m_index: IndexPath?
    var m_rooms = [Room]()
    
    let CELL_ID = "cell"
    let CHAT_SEGUE = "chat_room_segue"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        m_placesTableView.delegate = self
        m_placesTableView.dataSource = self
        m_placesSearchBar.delegate = self
        
        setUpUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        m_dbProvider.delegateRooms = self
        m_placesSearchBar.text = ""
        m_rooms.removeAll()
        m_placesTableView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewDidAppear(animated)
        m_placesSearchBar.resignFirstResponder()
    }
    
    func setUpUI() {
        m_placesTableView.backgroundColor = UIColor.init(white: 0.4, alpha: 1)
        self.navigationController?.navigationBar.barTintColor = UIColor.init(white: 0.1, alpha: 1)
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.lightText]
        
        m_placesSearchBar.delegate = self
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        m_placesSearchBar.showsCancelButton = true
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        m_placesSearchBar.showsCancelButton = false
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        m_placesSearchBar.showsCancelButton = false
        m_placesSearchBar.text = ""
        m_placesSearchBar.resignFirstResponder()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if m_placesSearchBar.text != "" {
            placesRequest(query: m_placesSearchBar.text!)
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText == "" {
            m_rooms.removeAll()
            m_placesTableView.reloadData()
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        m_placesSearchBar.resignFirstResponder()
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return m_rooms.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell.init(style: UITableViewCellStyle.subtitle, reuseIdentifier: CELL_ID)
        cell.textLabel?.textColor = UIColor.white
        cell.detailTextLabel?.textColor = UIColor.white
        cell.contentView.backgroundColor = UIColor.init(white: 0.4, alpha: 1)
        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.init(white: 0.2, alpha: 1)
        cell.selectedBackgroundView = backgroundView
        
        let activeUserImage = UIImage.init(named: "user")
        let activeUserImageView = UIImageView.init(frame: CGRect(x: self.view.frame.size.width*0.93, y: cell.contentView.bounds.height/5.2, width: 20, height: 20))
        activeUserImageView.image = activeUserImage
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
        m_index = indexPath
        performSegue(withIdentifier: CHAT_SEGUE, sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == CHAT_SEGUE {
            if let vc = segue.destination as? ChatVC {
                let currentRoomName = m_rooms[m_index!.row].name
                let description = m_rooms[m_index!.row].description
                let currentRoomID = m_rooms[m_index!.row].id
                vc.m_currentRoomName = currentRoomName
                vc.m_currentRoomID = currentRoomID
                m_dbProvider.m_currentRoomID = currentRoomID
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
                            self.m_dbProvider.hasRoom(roomID: self.m_rooms[index].id, index: index)
                        } catch _ {
                            
                        }
                    }
                }
                self.m_placesTableView.reloadData()
            }
        })
    }
    
    // Delegate Function
    
    func roomDataReceived(room: Room) {
        
    }
    
    func allRoomDataReceived(rooms: [Room]) {
        
    }
    
    func activeUserDataReceived(activeUsers: Int, index: Int) {
        m_rooms[index].activeUsers = activeUsers
        let indexPath = IndexPath(row: index, section: 0)
        m_placesTableView.reloadRows(at: [indexPath], with: .none)
    }
    
    
}
