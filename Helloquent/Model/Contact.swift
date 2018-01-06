//
//  Contact.swift
//  Helloquent
//
//  Created by Morgan Trudeau on 2017-12-22.
//  Copyright © 2017 Morgan Trudeau. All rights reserved.
//

import Foundation
import UIKit

class Contact {
    
    private var _name = ""
    private var _id = ""
    private var _color: UIColor?
    
    init(id: String, name: String, color: UIColor?) {
        _id = id
        _name = name
        _color = color
    }
    
    var name: String {
        return _name
    }
    
    var id: String {
        return _id
    }
    
    var color: UIColor? {
        return _color
    }
    
}
















