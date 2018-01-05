//
//  AlertHandler.swift
//  Helloquent
//
//  Created by Morgan Trudeau on 2018-01-04.
//  Copyright © 2018 Morgan Trudeau. All rights reserved.
//

import Foundation

class AlertHandler: UIAlertController {
    private static let _instance = AlertHandler()
    
    static var Instance: AlertHandler {
        return _instance
    }
    
    func alertUser(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }
}
