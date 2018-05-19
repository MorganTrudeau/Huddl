//
//  LocationRoomsTableView.swift
//  Helloquent
//
//  Created by Morgan Trudeau on 2018-01-25.
//  Copyright © 2018 Morgan Trudeau. All rights reserved.
//

import Foundation
import UIKit
import NMAKit

class LocationRoomsTableView: UIViewController, UITableViewDelegate, UITableViewDataSource, RoomContainerDelegate {
    
    @IBOutlet weak var m_locationRoomsTableView: UITableView!
    
    let m_dbProvider = DBProvider()
    let m_locationManager = LocationManager()
    
    var m_index: IndexPath?
    var m_locationRooms = [NMAAutoSuggestPlace]()
    
    let CELL_ID = "cell"
    let CHAT_SEGUE = "chat_room_segue"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        m_locationRoomsTableView.delegate = self
        m_locationRoomsTableView.dataSource = self
    }
    
    // TableView Functions
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return m_locationRooms.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = UITableViewCell.init(style: UITableViewCellStyle.subtitle, reuseIdentifier: CELL_ID)
        
        // format place data
        let place = m_locationRooms[indexPath.row]
        let htmlString: String? = place.highlightedTitle
        let description: String? = place.vicinityDescription?.replacingOccurrences(of: "<br/>", with: ", ").replacingOccurrences(of: "<B>", with: "").replacingOccurrences(of: "</B>", with: "")
        cell.detailTextLabel?.text = description
        do {
            let name = try NSAttributedString.init(data: (htmlString?.data(using: String.Encoding.unicode))!, options: [NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil)
            cell.textLabel?.text = name.string
        } catch _ {
            print("Error formating highlightedTitle")
        }
        return cell;
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        m_locationRoomsTableView.deselectRow(at: indexPath, animated: true)
        // Define selected index to pass to prepare for segue func
        m_index = indexPath
        // Segue into selected room
        performSegue(withIdentifier: CHAT_SEGUE, sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == CHAT_SEGUE {
            if let vc = segue.destination as? ChatVC {
                
                let cell = m_locationRoomsTableView.cellForRow(at: m_index!)
                let place = m_locationRooms[(m_index?.row)!]
                
                let selectedRoomName = cell!.textLabel!.text
                let selectedRoomdescription = cell!.detailTextLabel!.text
                var selectedRoomID = "\(place.position.latitude ?? 1)\(place.position.longitude ?? 1)"
                selectedRoomID = selectedRoomID.replacingOccurrences(of: ".", with: "")
                let selectedRoom = Room(name: selectedRoomName!, description: selectedRoomdescription!, id: selectedRoomID, password: "", likes: 0)
                
                vc.m_currentRoom = selectedRoom
                    
                // Pass selected room ID to dbProvider to use as child ID
                m_dbProvider.m_currentRoom = selectedRoom
                    
                // Create location room in database
                m_dbProvider.createLocationRoom(id: selectedRoomID, name: selectedRoomName!, description: selectedRoomdescription, password: "", lat: String(place.position.latitude), long: String(place.position.longitude))
            }
        }
    }
    
    func alertUser(title: String, message: String) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }
    
    // RoomContainer Delegate Functions
    
    func textChanged(query: String) {
        if query != "" {
            m_locationManager.placesRequest(query: query, completion: {(places) in
                self.m_locationRooms = places
                self.m_locationRoomsTableView.reloadData()
            })
        } else {
            m_locationManager.cancelRequest()
            m_locationRooms.removeAll()
            m_locationRoomsTableView.reloadData()
        }
    }
    
    func roomCreated(room: Room) {
    }
    
}

