//
//  File.swift
//  Helloquent
//
//  Created by Morgan Trudeau on 2018-02-01.
//  Copyright © 2018 Morgan Trudeau. All rights reserved.
//

import Foundation
import Cache

struct User: Codable {
    let id: String
    var name: String
    var color: String
    var avatar: ImageWrapper
}
