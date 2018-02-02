//
//  SplashScreenVC.swift
//  Helloquent
//
//  Created by Morgan Trudeau on 2018-01-31.
//  Copyright © 2018 Morgan Trudeau. All rights reserved.
//

import Foundation
import UIKit

class SplashScreenVC: UIViewController {
    
    let SIGN_IN_SEGUE = "sign_in_segue"
    let MAIN_SEGUE = "main_segue"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let roomTextImage = UIImage(named: "rooms_text")
        let roomTextImageView = UIImageView(image: roomTextImage)
        roomTextImageView.center.x = self.view.center.x
        roomTextImageView.center.y = self.view.center.y
        self.view.addSubview(roomTextImageView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if AuthProvider.Instance.isLoggedIn() {
            self.performSegue(withIdentifier: MAIN_SEGUE, sender: nil)
        } else {
            self.performSegue(withIdentifier: SIGN_IN_SEGUE, sender: nil)
        }
    }
}
