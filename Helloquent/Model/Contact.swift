//
//  Contact.swift
//  Helloquent
//
//  Created by Morgan Trudeau on 2017-12-22.
//  Copyright © 2017 Morgan Trudeau. All rights reserved.
//

import Foundation

class Contact {
    
    private var _name = ""
    private var _id = ""
    
    init(id: String, name: String) {
        _id = id
        _name = name
    }
    
    var name: String {
        return _name
    }
    
    var id: String {
        return _id
    }
    
}
















