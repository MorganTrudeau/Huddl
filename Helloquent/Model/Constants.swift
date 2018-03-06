//
//  Constants.swift
//  Helloquent
//
//  Created by Morgan Trudeau on 2017-12-22.
//  Copyright © 2017 Morgan Trudeau. All rights reserved.
//

import Foundation

class Constants {
    
    // DBProvider
    static let USERS = "Users"
    static let ROOMS = "Rooms"
    static let USER_ROOMS = "User_Rooms"
    static let LOCATION_ROOMS = "Location_Rooms"
    static let ROOM_MESSAGES = "Room_Messages"
    static let CHAT_MESSAGES = "Chat_Messages"
    static let MEDIA_MESSAGES = "Media_Messages"
    static let IMAGE_STORAGE = "Image_Storage"
    static let VIDEO_STORAGE = "Video_Storage"
    static let DISPLAY_NAMES = "Display_Names"
    static let LIKED_ROOMS = "Liked_Rooms"
    
    
    // User
    static let EMAIL = "email"
    static let DISPLAY_NAME = "display_name"
    static let PASSWORD = "password"
    static let DATA = "data"
    static let COLOR = "color"
    static let AVATAR = "avatar"
    static let CHATS = "chats"
    static let TOKEN = "token"
    
    // Messages
    static let TEXT = "text"
    static let SENDER_ID = "sender_id"
    static let SENDER_NAME = "sender_name"
    static let URL = "url"
    static let RECEIVER_ID = "receiver_id"
    
    // Room
    static let ROOM_NAME = "room_name"
    static let DESCRIPTION = "description"
    static let ROOM_ID = "room_id"
    static let ACTIVE_USERS = "active_users"
    static let LIKES = "likes"
    static let ROOM_USERS = "room_users"
    static let LATITUDE = "latitude"
    static let LONGITUDE = "longitude"
    
    // DB Handles
    static let CHILD_ADDED_HANDLE = "child_added_handle"
    static let CHILD_CHANGED_HANDLE = "child_changed_handle"
}
