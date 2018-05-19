//
//  ColorPicker.swift
//  Helloquent
//
//  Created by Morgan Trudeau on 2018-01-05.
//  Copyright © 2018 Morgan Trudeau. All rights reserved.
//

import Foundation
import UIKit

class ColorHandler {
    private static let _instance = ColorHandler()
    
    static var Instance: ColorHandler {
        return _instance
    }
    
    static let pink = UIColor(red: 1, green: 204/255, blue: 1, alpha: 1)
    static let red = UIColor(red: 1, green: 102/255, blue: 102/255, alpha: 1)
    static let orange = UIColor(red: 1, green: 170/255, blue: 128/255, alpha: 1)
    static let yellow = UIColor(red: 1, green: 1, blue: 153/255, alpha: 1)
    static let green = UIColor(red: 204/255, green: 1, blue: 153/255, alpha: 1)
    static let teal = UIColor(red: 179/255, green: 1, blue: 217/255, alpha: 1)
    static let blue = UIColor(red: 128/255, green: 212/255, blue: 1, alpha: 1)
    static let violet = UIColor(red: 153/255, green: 153/255, blue: 1, alpha: 1)
    static let purple = UIColor(red: 221/255, green: 153/255, blue: 1, alpha: 1)
    static let grey = UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 1)
    static let c11 = UIColor(red: 231/255, green: 0, blue: 89/255, alpha: 1)
    
    let colors: [String] = ["pink", "red", "orange", "yellow", "green", "teal", "blue", "violet", "purple", "grey"]
    let uiColors: [UIColor] = [pink, red, orange, yellow, green, teal, blue, violet, purple, grey]
    
    func userColor() -> String {
        let color = colors[Int(arc4random_uniform(UInt32(colors.count)))]
        return color
    }
    
    func convertToUIColor(colorString: String) -> UIColor {
        var color: UIColor
        
        switch colorString {
        case "pink":
            color = ColorHandler.pink
        case "red":
            color = ColorHandler.red
        case "orange":
            color = ColorHandler.orange
        case "yellow":
            color = ColorHandler.yellow
        case "green":
            color = ColorHandler.green
        case "teal":
            color = ColorHandler.teal
        case "blue":
            color = ColorHandler.blue
        case "violet":
            color = ColorHandler.violet
        case "purple":
            color = ColorHandler.purple
        case "grey":
            color = ColorHandler.grey
        default:
            color = ColorHandler.blue
        }
        
        return color
    }

    
}
