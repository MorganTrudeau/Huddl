//
//  CacheStorage.swift
//  Helloquent
//
//  Created by Morgan Trudeau on 2018-02-01.
//  Copyright © 2018 Morgan Trudeau. All rights reserved.
//

import Foundation
import Cache

typealias UserHandler = (_ users: [String:User]) -> Void
typealias ImageHandler = (_ image: UIImage) -> Void

class CacheStorage {
    
    private static let _instance = CacheStorage()
    
    static var Instance: CacheStorage {
        return _instance
    }
    
    // User Storage

    lazy var m_userStorage: Storage = {
        let diskConfig = DiskConfig(name: "UserCache")
        let memoryConfig = MemoryConfig(expiry: .never, countLimit: 10, totalCostLimit: 10)
        let storage = try! Storage(diskConfig: diskConfig, memoryConfig: memoryConfig)
        return storage
    }()
    
    func cacheUsers(users: [String:User]) {
        do{
            try m_userStorage.setObject(users, forKey: "users")
        } catch {
            print(error)
        }
    }
    
    func fetchUserData(id: String, completion: UserHandler?) {
        m_userStorage.async.object(ofType: [String:User].self, forKey: id, completion: {(result) in
            switch result {
            case .value(let users):
                print(users)
                completion?(users)
            case .error(let error):
                print(error)
            }
        })
    }
    
    // Image Storage
    
    lazy var m_imageStorage: Storage = {
        let diskConfig = DiskConfig(name: "ImageCache")
        let memoryConfig = MemoryConfig(expiry: .never, countLimit: 10, totalCostLimit: 10)
        let storage = try! Storage(diskConfig: diskConfig, memoryConfig: memoryConfig)
        return storage
    }()
    
    func wrapImage(image: UIImage) -> ImageWrapper {
        let wrappedImage = ImageWrapper(image: image)
        return wrappedImage
    }
    
    func cacheImage(url: String, image: UIImage) {
        let wrappedImage = wrapImage(image: image)
        do{
            try m_imageStorage.setObject(wrappedImage, forKey: url)
        } catch {
            print(error)
        }
    }
    
    func fetchImageData(id: String, completion: ImageHandler?) {
        m_userStorage.async.object(ofType: ImageWrapper.self, forKey: id, completion: {(result) in
            switch result {
            case .value(let wrappedImage):
                print(wrappedImage)
                let image = wrappedImage.image
                completion?(image)
            case .error(let error):
                print(error)
            }
        })
    }

}

