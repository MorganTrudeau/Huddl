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
    
    var m_locationRooms = [NMAMapObject:LocationRoom]()
    var m_mapObjects = [NMAMapObject]()
    var m_tapLocation: CGPoint?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Create geo coordinate
        let geoCoordCenter: NMAGeoCoordinates = (NMAPositioningManager.shared().currentPosition?.coordinates)!
        // Set map view with geo center
        self.mapView?.set(geoCenter: geoCoordCenter, animation: NMAMapAnimation.none)
        // Set zoom level
        self.mapView?.zoomLevel = 13.2
        
        let m_roomTextImage = UIImage(named: "rooms_text")
        let m_roomTextImageView = UIImageView.init(frame: CGRect(x: 0, y: 0, width: 70, height: 30))
        m_roomTextImageView.image = m_roomTextImage
        m_roomTextImageView.center.x = (self.navigationController?.navigationBar.center.x)!
        m_roomTextImageView.center.y = (self.navigationController?.navigationBar.center.y)! - 22
        m_roomTextImageView.image = m_roomTextImageView.image?.withRenderingMode(.alwaysTemplate)
        m_roomTextImageView.tintColor = UIColor.lightText
        
        self.navigationController?.navigationBar.addSubview(m_roomTextImageView)
        
        self.navigationController?.navigationBar.barTintColor = UIColor.init(white: 0.1, alpha: 1)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(MapVC.onMarkerTap))
        tap.cancelsTouchesInView = false
        
        mapView.addGestureRecognizer(tap)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        DBProvider.Instance.getLocationRooms(completion: {(rooms) in
            for room in rooms {
                DispatchQueue.global().async {
                    let coords = NMAGeoCoordinates(latitude: Double(room.latitude)!, longitude: Double(room.longitude)!)
                    let marker = NMAMapMarker(geoCoordinates: coords)
                    self.m_locationRooms[marker] = room
                    marker.anchorOffset = CGPoint(x: 0, y: 18)
                    marker.title = room.name
                    marker.textDescription = room.description
                    if room.activeUsers > 0 {
                        marker.icon = UIImage(named: "green_marker")!
                    } else {
                        marker.icon = UIImage(named: "red_marker")!
                    }
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
        for marker in visibleMarkers {
            marker.showInfoBubble()
            marker.infoBubbleEventBlock = {() in
                self.alertUser(title: "hi", message: "hi")
            }
        }
    }
    
    func alertUser(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }
}
