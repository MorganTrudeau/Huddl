//
//  LoadingOverlay.swift
//  Helloquent
//
//  Created by Morgan Trudeau on 2018-01-23.
//  Copyright © 2018 Morgan Trudeau. All rights reserved.
//

import Foundation
import UIKit

class LoadingOverlay: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor(white: 0, alpha: 0.7)
        self.view.isOpaque = false
        
        let activityIndicator = UIActivityIndicatorView()
        activityIndicator.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        activityIndicator.activityIndicatorViewStyle = .whiteLarge
        activityIndicator.center = self.view.center
        
        self.view.addSubview(activityIndicator)
        activityIndicator.startAnimating()
    }
}
