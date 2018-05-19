//
//  LocationManager.swift
//  Helloquent
//
//  Created by Morgan Trudeau on 2018-05-18.
//  Copyright © 2018 Morgan Trudeau. All rights reserved.
//

import Foundation
import NMAKit

class LocationManager {
    
    private var m_currentPosition = NMAGeoCoordinates(latitude: 0, longitude: 0)
    private var m_locationRooms = [NMAAutoSuggestPlace]()
    private var m_placeRequest: NMAAutoSuggestionRequest?
    
    func placesRequest(query: String, completion: @escaping (_ locationRooms: [NMAAutoSuggestPlace]) -> Void) {
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
                completion(requestData.filter { $0.isKind(of: NMAAutoSuggestPlace.self) } as! [NMAAutoSuggestPlace])
            }
        })
    }
    
    func cancelRequest() {
        m_placeRequest?.cancel()
    }
    
}
