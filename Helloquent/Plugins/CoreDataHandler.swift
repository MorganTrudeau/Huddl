//
//  CoreDataHandler.swift
//  Helloquent
//
//  Created by Morgan Trudeau on 2018-01-18.
//  Copyright © 2018 Morgan Trudeau. All rights reserved.
//

import Foundation
import UIKit
import CoreData

protocol FetchRoomCoreData: class {
    func coreRoomDataReceived(savedRoomIDs: [String])
}

class CoreDataHandler {
    
    private static let m_instance = CoreDataHandler()
    
    static var Instance: CoreDataHandler {
        return m_instance
    }
    
    weak var delegate: FetchRoomCoreData?
    
    private var m_roomIDs = [String]()
    
    func saveRoomCoreData(id: String) {
        
        if !m_roomIDs.contains(id) {
            guard let appDelegate =
                UIApplication.shared.delegate as? AppDelegate else {
                    return
            }
            
            // 1
            let managedContext =
                appDelegate.persistentContainer.viewContext
            
            // 2
            let entity =
                NSEntityDescription.entity(forEntityName: "Room",
                                           in: managedContext)!
            
            let room = NSManagedObject(entity: entity,
                                       insertInto: managedContext)
            
            // 3
            room.setValue(id, forKeyPath: "id")
            
            // 4
            do {
                try managedContext.save()
            } catch let error as NSError {
                print("Could not save. \(error), \(error.userInfo)")
            }
        }
    }
    
    func fetchRoomCoreData() {
        
        //1
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        
        let managedContext =
            appDelegate.persistentContainer.viewContext
        
        //2
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Room")
        
        //3
        do {
            let coreData = try managedContext.fetch(fetchRequest)
            m_roomIDs.removeAll()
            for room in coreData {
                m_roomIDs.append(room.value(forKey: "id") as! String)
            }
            self.delegate?.coreRoomDataReceived(savedRoomIDs: m_roomIDs)
            
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }
}
