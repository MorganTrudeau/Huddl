////
////  ContactsVC.swift
////  Helloquent
////
////  Created by Morgan Trudeau on 2017-12-21.
////  Copyright © 2017 Morgan Trudeau. All rights reserved.
////
//
//import UIKit
//
//class ContactsVC: UIViewController, UITableViewDelegate, UITableViewDataSource, FetchContactData {
//    
//    private let CELL_ID = "contact_cell"
//    private let CHAT_SEGUE = "personal_chat_segue"
//    
//    private var contacts = [Contact]()
//    private var index: Int?
//    
//    @IBOutlet weak var contactsTableView: UITableView!
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        DBProvider.Instance.delegateContacts = self
//        DBProvider.Instance.getContacts()
//    }
//    
//    func contactDataReceived(contacts: [Contact]) {
//        self.contacts = contacts
//        
//        contactsTableView.reloadData()
//    }
//
//    func numberOfSections(in tableView: UITableView) -> Int {
//        return 1
//    }
//    
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return contacts.count
//    }
//    
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        
//        let cell = tableView.dequeueReusableCell(withIdentifier: CELL_ID, for: indexPath)
//        cell.textLabel?.text = contacts[indexPath.row].name
//        return cell
//    }
//    
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        index = indexPath.row
//        performSegue(withIdentifier: CHAT_SEGUE, sender: nil)
//    }
//    
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        if segue.identifier == CHAT_SEGUE {
//            if let vc = segue.destination as? PersonalChatVC {
//                vc.selectedContactID = contacts[index!].id
//                vc.selectedContactName = contacts[index!].name
//                DBProvider.Instance.selectedContactID = contacts[index!].id
//            }
//        }
//    }
//    
//    
//    
//    
//    
//    
//    
//    
//    
//    
//    
//    
//    
//    
//    
//    
//    
//    
//    
//    
//
//}

