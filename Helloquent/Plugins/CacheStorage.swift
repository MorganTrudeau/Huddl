//
//  CacheStorage.swift
//  Helloquent
//
//  Created by Morgan Trudeau on 2018-02-01.
//  Copyright © 2018 Morgan Trudeau. All rights reserved.
//

import Foundation
import Cache

typealias UserHandler = (_ user: User) -> Void

class CacheStorage {
    
    private static let _instance = CacheStorage()
    
    static var Instance: CacheStorage {
        return _instance
    }

    lazy var m_userStorage: Storage = {
        let diskConfig = DiskConfig(name: "UserCache")
        let memoryConfig = MemoryConfig(expiry: .never, countLimit: 10, totalCostLimit: 10)
        let storage = try! Storage(diskConfig: diskConfig, memoryConfig: memoryConfig)
        return storage
    }()
    
    func cacheUser(user: User) {
        do{
            try m_userStorage.setObject(user, forKey: user.id)
        } catch {
            print(error)
        }
    }
    
    func fetchUserData(id: String, completion: UserHandler?) {
        m_userStorage.async.object(ofType: User.self, forKey: id, completion: {(result) in
            switch result {
            case .value(let user):
                print(user)
                completion?(user)
            case .error(let error):
                print(error)
            }
        })
    }
    
    func wrapImage(image: UIImage) -> ImageWrapper {
        let wrappedImage = ImageWrapper(image: image)
        return wrappedImage
    }

}

