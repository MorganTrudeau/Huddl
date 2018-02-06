//
//  CodableStructs.swift
//  Helloquent
//
//  Created by Morgan Trudeau on 2018-02-01.
//  Copyright © 2018 Morgan Trudeau. All rights reserved.
//

import Foundation

struct User: Codable {
    let id: String
    var name: String
    var color: String
    var avatar: String
}

struct Room: Codable {
    var name: String
    var description: String
    let id: String
    var password: String
    var activeUsers: Int
}

struct LocationRoom: Codable {
    var name: String
    var description: String
    let id: String
    var password: String
    var activeUsers: Int
    var latitude: String
    var longitude: String
}

struct Message: Codable {
    let senderID: String
    let senderName: String
    let text: String
    let url: String
}
