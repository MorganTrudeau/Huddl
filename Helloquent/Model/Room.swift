//
//  Room.swift
//  Helloquent
//
//  Created by Morgan Trudeau on 2018-01-03.
//  Copyright © 2018 Morgan Trudeau. All rights reserved.
//

import Foundation

class Room {
    
    private var _name = ""
    private var _description = ""
    private var _id = ""
    private var _password = ""
    private var _activeUsers = 0
    
    init(id: String, name: String, description: String, password: String, activeUsers: Int) {
        _id = id
        _name = name
        _description = description
        _password = password
        _activeUsers = activeUsers
    }
    
    var name: String {
        return _name
    }
    
    var description: String {
        return _description
    }
    
    var id: String {
        return _id
    }
    
    var password: String {
        return _password
    }
    
    var activeUsers: Int {
        get {
            return _activeUsers
        } set {
            _activeUsers = newValue
        }
    }
}
