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
    
    var m_locationRooms = [LocationRoom]()
    var m_mapObjects = [NMAMapObject]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Create geo coordinate
        let geoCoordCenter: NMAGeoCoordinates = NMAGeoCoordinates(latitude: 49.260327, longitude: -123.115025)
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
        
        let tap = UITapGestureRecognizer(target: self, action: #selector (MapVC.markerTap))
        tap.poin
        
        let recognizer = UITap
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        DBProvider.Instance.getLocationRooms(completion: {(rooms) in
            self.m_locationRooms = rooms
            
            for room in self.m_locationRooms {
                DispatchQueue.global().async {
                    let coords = NMAGeoCoordinates(latitude: Double(room.latitude)!, longitude: Double(room.longitude)!)
                    let marker = NMAMapMarker(geoCoordinates: coords, image: UIImage(named: "marker")!)
                    marker.anchorOffset = CGPoint(x: 0, y: 18)
                    marker.title = room.name
                    marker.textDescription = room.description
                    self.m_mapObjects.append(marker)
                    DispatchQueue.main.async {
                        self.mapView.add(objects: self.m_mapObjects)
                    }
                }
            }
        })
    }
    
    @objc func markerTap() {
        mapView.visibleObjects(at: <#T##CGPoint#>)
    }
    
    func alertUser(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }
}
