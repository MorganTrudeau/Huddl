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
    
    @IBOutlet weak var m_placesSearchBar: UISearchBar!
    @IBOutlet weak var m_placesTableView: UITableView!
    
    
    var m_index: IndexPath?
    var m_autoSuggestions = [NMAAutoSuggestPlace]()
    
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
        m_placesSearchBar.text = ""
        m_autoSuggestions.removeAll()
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
            self.m_autoSuggestions.removeAll()
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
        return m_autoSuggestions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell.init(style: UITableViewCellStyle.subtitle, reuseIdentifier: CELL_ID)
        cell.textLabel?.textColor = UIColor.white
        cell.detailTextLabel?.textColor = UIColor.white
        cell.contentView.backgroundColor = UIColor.init(white: 0.4, alpha: 1)
        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.init(white: 0.2, alpha: 1)
        cell.selectedBackgroundView = backgroundView
        
        if m_autoSuggestions[0].isKind(of: NMAAutoSuggest.self) {
            let autoSuggestionPlace = m_autoSuggestions[indexPath.row]
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
        m_index = indexPath
        performSegue(withIdentifier: CHAT_SEGUE, sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == CHAT_SEGUE {
            if let vc = segue.destination as? ChatVC {
                let currentChatRoomName = m_placesTableView.cellForRow(at: m_index!)?.textLabel?.text
                vc.currentChatRoomName = currentChatRoomName
                let autoSuggestionItem = m_autoSuggestions[m_index!.row]
                var currentChatRoomID =
                    "\(autoSuggestionItem.position?.latitude ?? 1)\(autoSuggestionItem.position?.longitude ?? 1)"
                currentChatRoomID = currentChatRoomID.replacingOccurrences(of: ".", with: "")
                DBProvider.Instance.currentRoomID = currentChatRoomID
                vc.m_currentChatRoomID = currentChatRoomID
                DBProvider.Instance.saveLocationChatRoom(id: currentChatRoomID, name: currentChatRoomName!, password: "")
                
            }
        }
    }
    
    func placesRequest(query: String) {
        let currentPosition = NMAPositioningManager.sharedInstance().currentPosition?.coordinates
        print(currentPosition)
        let bounding = NMAGeoBoundingBox.init(center: currentPosition!, width: 45, height: 45)
        print(bounding)
        
        let request: NMAAutoSuggestionRequest = (NMAPlaces.sharedInstance()?.createAutoSuggestionRequest(location: currentPosition, partialTerm: query))!
        request.viewport = bounding!
        request.collectionSize = 10
        request.start({(request: NMARequest, data: Any?, error: Error?) in
            if error == nil {
                self.m_autoSuggestions.removeAll()
                for item in data as! [NMAAutoSuggest] {
                    if let place = item as? NMAAutoSuggestPlace {
                        self.m_autoSuggestions.append(place)
                    }
                }
                self.m_placesTableView.reloadData()
            }
        })
    }
    
    
    
}
