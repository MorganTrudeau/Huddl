//
//  ContactsVC.swift
//  Helloquent
//
//  Created by Morgan Trudeau on 2017-12-21.
//  Copyright © 2017 Morgan Trudeau. All rights reserved.
//

import UIKit

class ContactsVC: UIViewController {
    
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func logout(_ sender: Any) {
        
        if AuthProvider.Instance.logout() {
            dismiss(animated: true, completion: nil)
        }
        
    
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    

}
