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
    private init() {}
    
    static var Instance: ColorHandler {
        return _instance
    }
    
//    static let purple = UIColor.init(red: 128, green: 0, blue: 255, alpha: 1)
//    static let red = UIColor.init(red: 255, green: 26, blue: 26, alpha: 1)
//    static let blue = UIColor.init(red: 0, green: 102, blue: 255, alpha: 1)
//    static let green = UIColor.init(red: 0, green: 230, blue: 77, alpha: 1)
//    static let orange = UIColor.init(red: 255, green: 153, blue: 0, alpha: 1)
    
    static let purple = "purple"
    static let red = "red"
    static let blue = "blue"
    static let green = "green"
    
    var colors: [String] = [purple, red, blue, green]
    
    func userColor() -> String {
        let color = colors[Int(arc4random_uniform(UInt32(colors.count)))]
        return color
    }
    
    func convertToUIColor(colorString: String) -> UIColor {
        var color: UIColor
        
        switch colorString {
        case "purple":
            color = UIColor.magenta
        case "red":
            color = UIColor.red
        case "blue":
            color = UIColor.blue
        case "green":
            color = UIColor.green
        default:
            color = UIColor.blue
        }
        
        return color
    }

    
}
