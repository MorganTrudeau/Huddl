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

class LocationRooms: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    
    @IBOutlet weak var placesSearchBar: UISearchBar!
    
    @IBOutlet weak var placesTableView: UITableView!
    
    var searchActive : Bool = false
    var autoSuggestions = [NMAAutoSuggestPlace]()
    
    let CELL_ID = "cell"
    let CHAT_SEGUE = "chat_room_segue"
    
    var index: IndexPath?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        placesTableView.delegate = self
        placesTableView.dataSource = self
        placesSearchBar.delegate = self
        
        setUpUI()
    }
    
    func setUpUI() {
        placesTableView.backgroundColor = UIColor.init(white: 0.4, alpha: 1)
        self.navigationController?.navigationBar.barTintColor = UIColor.init(white: 0.1, alpha: 1)
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.lightText]
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchActive = true
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchActive = false
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchActive = false
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchActive = false
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText != "" {
            self.searchActive = true
            placesRequest(query: searchText)
        } else {
            self.searchActive = false
            self.autoSuggestions.removeAll()
            placesTableView.reloadData()
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print(autoSuggestions.count)
        for place in autoSuggestions {
            print(place.highlightedTitle!)
        }
        return autoSuggestions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell.init(style: UITableViewCellStyle.subtitle, reuseIdentifier: CELL_ID)
        cell.textLabel?.textColor = UIColor.white
        cell.detailTextLabel?.textColor = UIColor.white
        cell.contentView.backgroundColor = UIColor.init(white: 0.4, alpha: 1)
        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.init(white: 0.2, alpha: 1)
        cell.selectedBackgroundView = backgroundView
        
        if autoSuggestions[0].isKind(of: NMAAutoSuggest.self) {
            let autoSuggestionPlace = autoSuggestions[indexPath.row]
            let htmlString: String? = autoSuggestionPlace.highlightedTitle
            let detailText: String? = autoSuggestionPlace.vicinityDescription?.replacingOccurrences(of: "<br/>", with: ", ")
                cell.detailTextLabel?.text = detailText
            
            do {
                let attrString = try NSAttributedString.init(data: (htmlString?.data(using: String.Encoding.unicode))!, options: [NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil)
                    cell.textLabel?.text = attrString.string
            } catch _ {

            }
            
            
        }
        
        return cell;
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        index = indexPath
        performSegue(withIdentifier: CHAT_SEGUE, sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == CHAT_SEGUE {
            if let vc = segue.destination as? ChatVC {
                let currentChatRoomName = placesTableView.cellForRow(at: index!)?.textLabel?.text
                vc.currentChatRoomName = currentChatRoomName
                let autoSuggestionItem = autoSuggestions[index!.row]
                var currentChatRoomID =
                    "\(autoSuggestionItem.position?.latitude ?? 1)\(autoSuggestionItem.position?.longitude ?? 1)"
                currentChatRoomID = currentChatRoomID.replacingOccurrences(of: ".", with: "")
                DBProvider.Instance.currentRoomID = currentChatRoomID
                vc.currentChatRoomID = currentChatRoomID
                DBProvider.Instance.saveLocationChatRoom(id: currentChatRoomID, name: currentChatRoomName!, password: "")
                
            }
        }
    }
    
    func placesRequest(query: String) {
        let vancouver: NMAGeoCoordinates = NMAGeoCoordinates.init(latitude: 48.263392, longitude: -123.12203)
        let boudingTopLeftCoords: NMAGeoCoordinates = NMAGeoCoordinates.init(latitude: 49.277484, longitude: -123.133693)
        let boundingBottomRightCoords: NMAGeoCoordinates = NMAGeoCoordinates.init(latitude: 49.257209, longitude: -123.11275)
        let bounding: NMAGeoBoundingBox = NMAGeoBoundingBox.init(topLeft: boudingTopLeftCoords, bottomRight: boundingBottomRightCoords)!
        
        let request: NMAAutoSuggestionRequest = (NMAPlaces.sharedInstance()?.createAutoSuggestionRequest(location: vancouver, partialTerm: query))!
//        request.viewport = bounding
        request.collectionSize = 10
        request.viewport = bounding
        request.start({(request: NMARequest, data: Any?, error: Error?) in
            if error == nil && self.searchActive {
                self.autoSuggestions.removeAll()
                for item in data as! [NMAAutoSuggest] {
                    if let place = item as? NMAAutoSuggestPlace {
                        self.autoSuggestions.append(place)
                    }
                }
                self.placesTableView.reloadData()
            }
        })
    }
    
    
    
}
