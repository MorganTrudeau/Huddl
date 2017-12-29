//
//  ContactsVC.swift
//  Helloquent
//
//  Created by Morgan Trudeau on 2017-12-21.
//  Copyright © 2017 Morgan Trudeau. All rights reserved.
//

import UIKit

class ContactsVC: UIViewController, UITableViewDelegate, UITableViewDataSource, FetchData {
    
    private let CELL_ID = "Cell"
    private let CHAT_SEGUE = "ChatSegue"
    
    private var contacts = [Contact]()
    
    @IBOutlet weak var contactsTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        DBProvider.Instance.delegate = self
        DBProvider.Instance.getContacts()
    }
    
    func dataReceived(contacts: [Contact]) {
        self.contacts = contacts
        contactsTableView.reloadData()
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contacts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: CELL_ID, for: indexPath)
        cell.textLabel?.text = contacts[indexPath.row].name
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: CHAT_SEGUE, sender: nil)
    }
    
    @IBAction func logout(_ sender: Any) {
        
        if AuthProvider.Instance.logout() {
            dismiss(animated: true, completion: nil)
        }
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    

}
