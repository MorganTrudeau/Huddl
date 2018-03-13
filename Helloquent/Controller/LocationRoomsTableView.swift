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
    
    let m_dbProvider = DBProvider.Instance
    
    var m_index: IndexPath?
    var m_currentPosition = NMAGeoCoordinates(latitude: 0, longitude: 0)
    var m_locationRooms = [NMAAutoSuggestPlace]()
    var m_placeRequest: NMAAutoSuggestionRequest?
    
    let CELL_ID = "cell"
    let CHAT_SEGUE = "chat_room_segue"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        m_locationRoomsTableView.delegate = self
        m_locationRoomsTableView.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !NMAPositioningManager.shared().isActive {
            NMAPositioningManager.shared().startPositioning()
        }
        if let currentPosition = NMAPositioningManager.shared().currentPosition?.coordinates {
            m_currentPosition = currentPosition 
        }
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
        
        let place = m_locationRooms[indexPath.row]
        let htmlString: String? = place.highlightedTitle
        let description: String? = place.vicinityDescription?.replacingOccurrences(of: "<br/>", with: ", ").replacingOccurrences(of: "<B>", with: "").replacingOccurrences(of: "</B>", with: "")
        cell.detailTextLabel?.text = description
        do {
            let name = try NSAttributedString.init(data: (htmlString?.data(using: String.Encoding.unicode))!, options: [NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil)
            cell.textLabel?.text = name.string
        } catch _ {
            
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
    
    func placesRequest(query: String) {
        // Cancel any pending requests
        m_placeRequest?.cancel()
        
        if !NMAPositioningManager.shared().isActive {
            NMAPositioningManager.shared().startPositioning()
        }
        if let currentPosition = NMAPositioningManager.shared().currentPosition?.coordinates {
            m_currentPosition = currentPosition
        }
        
        let bounding = NMAGeoBoundingBox.init(center: m_currentPosition, width: 45, height: 45)
        
        m_placeRequest = NMAPlaces.shared().makeAutoSuggestionRequest(location: m_currentPosition, partialTerm: query)
        m_placeRequest?.viewport = bounding
        m_placeRequest?.collectionSize = 10
        m_placeRequest?.start(block: {(request: NMARequest, data: Any?, error: Error?) in
            if error == nil {
                let requestData = data as! [NMAAutoSuggest]
                self.m_locationRooms = requestData.filter { $0.isKind(of: NMAAutoSuggestPlace.self) } as! [NMAAutoSuggestPlace]
                self.m_locationRoomsTableView.reloadData()
            }
        })
    }
    
    func alertUser(title: String, message: String) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }
    
    // Delegate Functions
    
    func textChanged(query: String) {
        if query != "" {
            m_placeRequest?.cancel()
            placesRequest(query: query)
        } else {
            m_placeRequest?.cancel()
            m_locationRooms.removeAll()
            m_locationRoomsTableView.reloadData()
        }
    }
    
    func roomCreated(room: Room) {
    }
    
}

