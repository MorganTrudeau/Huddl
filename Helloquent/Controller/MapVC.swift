//
//  MapVC.swift
//  Helloquent
//
//  Created by Morgan Trudeau on 2018-02-05.
//  Copyright © 2018 Morgan Trudeau. All rights reserved.
//

import Foundation
import UIKit
import NMAKit

class MapVC : UIViewController {
    
    @IBOutlet weak var mapView: NMAMapView!
    
    var m_locationRooms = [NMAMapMarker:LocationRoom]()
    var m_mapObjects = [NMAMapObject]()
    var m_tapLocation: CGPoint?
    var m_roomMenu = UIView()
    var m_selectedRoom: LocationRoom?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Create geo coordinate
        let geoCoordCenter: NMAGeoCoordinates = (NMAPositioningManager.shared().currentPosition?.coordinates)!
        // Set map view with geo center
        self.mapView?.set(geoCenter: geoCoordCenter, animation: NMAMapAnimation.none)
        // Set zoom level
        self.mapView?.zoomLevel = 9
        
        let m_roomTextImage = UIImage(named: "rooms_text")
        let m_roomTextImageView = UIImageView.init(frame: CGRect(x: 0, y: 0, width: 70, height: 30))
        m_roomTextImageView.image = m_roomTextImage
        m_roomTextImageView.center.x = (self.navigationController?.navigationBar.center.x)!
        m_roomTextImageView.center.y = (self.navigationController?.navigationBar.center.y)! - 22
        m_roomTextImageView.image = m_roomTextImageView.image?.withRenderingMode(.alwaysTemplate)
        m_roomTextImageView.tintColor = UIColor.lightText
        
        self.navigationController?.navigationBar.barTintColor = UIColor.init(white: 0.1, alpha: 1)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(MapVC.onMarkerTap))
        tap.cancelsTouchesInView = false
        
        mapView.addGestureRecognizer(tap)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        DBProvider.Instance.getLocationRooms(completion: {(rooms) in
            DispatchQueue.global().async {
                for room in rooms {
                        let coords = NMAGeoCoordinates(latitude: Double(room.latitude)!, longitude: Double(room.longitude)!)
                        let marker = NMAMapMarker(geoCoordinates: coords)
                        self.m_locationRooms[marker] = room
                        marker.anchorOffset = CGPoint(x: 0, y: 18)
                        marker.title = room.name
                        marker.textDescription = room.description
                        marker.icon = UIImage(named: "red_marker")!
                        self.m_mapObjects.append(marker)
                        DispatchQueue.main.async {
                            self.mapView.add(marker)
                        }
                }
            }
        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.mapView.remove(objects: self.m_mapObjects)
        self.m_mapObjects.removeAll()
    }
    
    @objc func onMarkerTap(recognizer: UITapGestureRecognizer) {
        let location = recognizer.location(in: mapView)
        let visibleMarkers: [NMAMapMarker] = mapView.visibleObjects(at: location) as! [NMAMapMarker]
        if visibleMarkers.count > 0 {
            let selectedRoom = m_locationRooms[visibleMarkers[0]]
            print(visibleMarkers)
            print(m_locationRooms)
            m_selectedRoom = selectedRoom
            presentRoomMenu(room: selectedRoom!)
        }
    }
    
    func presentRoomMenu(room: LocationRoom) {
        
        m_roomMenu = UIView.init(frame: CGRect(x: 0, y: 0, width: 250, height: 150))
        m_roomMenu.center.y = self.view.center.y
        m_roomMenu.center.x = self.view.center.x
        m_roomMenu.layer.cornerRadius = 8
        m_roomMenu.backgroundColor = UIColor.init(white: 0.2, alpha: 1)
        self.view.addSubview(m_roomMenu)
        
        let roomNameText = UILabel.init(frame: CGRect(x: 0, y: 10, width: 250, height: 20))
        roomNameText.text = room.name
        roomNameText.textAlignment = .center
        roomNameText.textColor = UIColor.white
        roomNameText.font = UIFont.boldSystemFont(ofSize: 20)
        
        let roomDescriptionText = UILabel.init(frame: CGRect(x: 0, y: 40, width: 250, height: 40))
        roomDescriptionText.text = room.description
        roomDescriptionText.textAlignment = .center
        roomDescriptionText.textColor = UIColor.white
        roomDescriptionText.font = UIFont.systemFont(ofSize: 18)
        roomDescriptionText.lineBreakMode = .byWordWrapping
        roomDescriptionText.numberOfLines = 0
        
        let enterButton = UIButton.init(frame: CGRect(x: 80, y: 90, width: 40, height: 40))
        enterButton.setImage(UIImage(named: "door"), for: .normal)
        enterButton.backgroundColor = UIColor(white: 0.18, alpha: 1)
        enterButton.layer.borderWidth = 2
        enterButton.layer.borderColor = UIColor(white: 0.16, alpha: 1).cgColor
        enterButton.layer.cornerRadius = 5
        enterButton.addTarget(self, action: #selector(MapVC.enterRoom), for: .touchUpInside)
        
        let cancelButton = UIButton.init(frame: CGRect(x: 130, y: 90, width: 40, height: 40))
        cancelButton.setImage(UIImage(named: "run"), for: .normal)
        cancelButton.backgroundColor = UIColor(white: 0.18, alpha: 1)
        cancelButton.layer.borderWidth = 2
        cancelButton.layer.borderColor = UIColor(white: 0.16, alpha: 1).cgColor
        cancelButton.layer.cornerRadius = 5
        cancelButton.addTarget(self, action: #selector(MapVC.dismissRoomMenu), for: .touchUpInside)
        
        m_roomMenu.addSubview(roomNameText)
        m_roomMenu.addSubview(enterButton)
        m_roomMenu.addSubview(cancelButton)
    }
    
    @objc func dismissRoomMenu() {
        m_roomMenu.removeFromSuperview()
    }
    
    @objc func enterRoom() {
        performSegue(withIdentifier: "room_segue", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        m_roomMenu.removeFromSuperview()
        let vc = segue.destination as! ChatVC
        let room = Room(name: m_selectedRoom!.name, description: m_selectedRoom!.description, id: m_selectedRoom!.id, password: "", likes: 0)
        vc.m_currentRoom = room
        DBProvider.Instance.m_currentRoom = room
    }
    
    func alertUser(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }
}
