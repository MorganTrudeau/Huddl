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
    
    static let c1 = UIColor(red: 227/255, green: 0, blue: 223/255, alpha: 1)
    static let c2 = UIColor(red: 162/255, green: 0, blue: 227/255, alpha: 1)
    static let c3 = UIColor(red: 101/255, green: 0, blue: 227/255, alpha: 1)
    static let c4 = UIColor(red: 0, green: 0, blue: 227/255, alpha: 1)
    static let c5 = UIColor(red: 0, green: 96/255, blue: 227/255, alpha: 1)
    static let c6 = UIColor(red: 0, green: 173/255, blue: 227/255, alpha: 1)
    static let c7 = UIColor(red: 0, green: 220/255, blue: 145/255, alpha: 1)
    static let c8 = UIColor(red: 0, green: 211/255, blue: 2/255, alpha: 1)
    static let c9 = UIColor(red: 231/255, green: 84/255, blue: 0, alpha: 1)
    static let c10 = UIColor(red: 231/255, green: 0, blue: 0, alpha: 1)
    static let c11 = UIColor(red: 231/255, green: 0, blue: 89/255, alpha: 1)
    
    let colors: [String] = ["pink", "purple", "darkPurple", "darkBlue", "blue", "lightBlue", "lightGreen", "green", "orange", "red"]
    let uiColors: [UIColor] = [c1, c2, c3, c4, c5, c6, c7, c8, c9, c10]
    
    func userColor() -> String {
        let color = colors[Int(arc4random_uniform(UInt32(colors.count)))]
        return color
    }
    
    func convertToUIColor(colorString: String) -> UIColor {
        var color: UIColor
        
        switch colorString {
        case "pink":
            color = ColorHandler.c1
        case "purple":
            color = ColorHandler.c2
        case "darkPurple":
            color = ColorHandler.c3
        case "darkBlue":
            color = ColorHandler.c4
        case "blue":
            color = ColorHandler.c5
        case "lightBlue":
            color = ColorHandler.c6
        case "lightGreen":
            color = ColorHandler.c7
        case "green":
            color = ColorHandler.c8
        case "orange":
            color = ColorHandler.c9
        case "red":
            color = ColorHandler.c10
        default:
            color = ColorHandler.c4
        }
        
        return color
    }

    
}
