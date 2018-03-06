//
//  RoomsContainerVC.swift
//  Helloquent
//
//  Created by Morgan Trudeau on 2018-01-25.
//  Copyright © 2018 Morgan Trudeau. All rights reserved.
//

import Foundation
import UIKit
import NMAKit
import Crashlytics

protocol RoomContainerDelegate: class {
    func textChanged(query: String)
    func roomCreated(room: Room)
}

class RoomsContainerVC: UIViewController, UISearchBarDelegate {
    
    private static let _instance = RoomsContainerVC()
    
    static var Instance: RoomsContainerVC {
        return _instance
    }
    
    weak var delegate: RoomContainerDelegate?
    
    @IBOutlet weak var m_tableContainer: UIView!
    @IBOutlet weak var m_roomsSegControl: UISegmentedControl!
    @IBOutlet weak var m_roomsSearchBar: UISearchBar!
    
    var m_currentTableView: UIViewController?
    var m_addRoomButton: UIBarButtonItem?
    var m_roomTextImageView: UIImageView?
    let m_roomTextImage = UIImage(named: "rooms_text")
    
    /**
     Child Table View
    **/
    
    lazy var m_likedRoomsTableView: LikedRoomsTableView = {
        let viewController: UIViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LikedRoomsTableView") as! LikedRoomsTableView
        self.addChildViewController(viewController)
        self.view.addSubview(viewController.view)
        viewController.view.frame = m_tableContainer.frame
        return viewController as! LikedRoomsTableView
    }()
    
    lazy var m_locationRoomsTableView: LocationRoomsTableView = {
        let viewController:UIViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LocationRoomsTableView") as! LocationRoomsTableView
        self.addChildViewController(viewController)
        self.view.addSubview(viewController.view)
        viewController.view.frame = m_tableContainer.frame
        return viewController as! LocationRoomsTableView
    }()
    
    lazy var m_userRoomsTableView: UserRoomsTableView = {
        let viewController: UIViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "UserRoomsTableView") as! UserRoomsTableView
        self.addChildViewController(viewController)
        self.view.addSubview(viewController.view)
        viewController.view.frame = m_tableContainer.frame
        return viewController as! UserRoomsTableView
    }()
    
    lazy var m_savedRoomsTableView: SavedRoomsTableView = {
        let viewController: UIViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SavedRoomsTableView") as! SavedRoomsTableView
        self.addChildViewController(viewController)
        self.view.addSubview(viewController.view)
        viewController.view.frame = m_tableContainer.frame
        return viewController as! SavedRoomsTableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        m_roomsSearchBar.delegate = self
        
        NMAPositioningManager.shared().startPositioning()
        
        AuthProvider.Instance.setNotificationToken()
        
        DBProvider.Instance.getUser(id: AuthProvider.Instance.userID(), completion: nil)
        
        setUpUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        m_roomTextImageView = UIImageView.init(frame: CGRect(x: 0, y: 0, width: 70, height: 30))
        m_roomTextImageView?.image = m_roomTextImage
        m_roomTextImageView?.center.x = (self.navigationController?.navigationBar.center.x)!
        m_roomTextImageView?.center.y = (self.navigationController?.navigationBar.center.y)! - 22
        m_roomTextImageView?.image = m_roomTextImageView?.image?.withRenderingMode(.alwaysTemplate)
        m_roomTextImageView?.tintColor = UIColor.lightText
        
        if m_roomsSegControl.selectedSegmentIndex == 0 {
            m_likedRoomsTableView.didMove(toParentViewController: self)
            m_currentTableView = m_likedRoomsTableView
            delegate = m_likedRoomsTableView.self
        } else if m_roomsSegControl.selectedSegmentIndex == 1 {
            m_locationRoomsTableView.didMove(toParentViewController: self)
            m_currentTableView = m_locationRoomsTableView
            delegate = m_locationRoomsTableView.self
        } else if m_roomsSegControl.selectedSegmentIndex == 2 {
            m_userRoomsTableView.didMove(toParentViewController: self)
            m_currentTableView = m_userRoomsTableView
            delegate = m_userRoomsTableView.self
        } else {
            m_savedRoomsTableView.didMove(toParentViewController: self)
            m_currentTableView = m_savedRoomsTableView
            delegate = m_savedRoomsTableView.self
        }
        
        self.navigationController?.navigationBar.addSubview(m_roomTextImageView!)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if m_roomsSearchBar != nil {
            m_roomsSearchBar.resignFirstResponder()
            m_roomsSearchBar.text = ""
            m_roomTextImageView?.removeFromSuperview()
        }
    }
    
    func setUpUI() {
        self.view.tintColor = UIColor(red: 133/255, green: 51/255, blue: 1, alpha: 1)
        
        self.m_roomsSearchBar.placeholder = "Search Place"
        
        m_addRoomButton = UIBarButtonItem(image: UIImage(named: "add"), style: .plain, target: self, action: #selector(RoomsContainerVC.addRoomButtonClicked))
        m_addRoomButton?.tintColor = UIColor(red: 133/255, green: 51/255, blue: 1, alpha: 1)
        
        self.navigationController?.navigationBar.barTintColor = UIColor.init(white: 0.1, alpha: 1)
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.lightText]
    }
    
    func switchTableView(tableView: UIViewController) {
        m_currentTableView!.willMove(toParentViewController: nil)
        self.addChildViewController(tableView)
        self.transition(from: m_currentTableView!, to: tableView, duration: 0.2, options: .curveLinear, animations: nil, completion: {(finished) in
            self.m_currentTableView!.removeFromParentViewController()
            tableView.didMove(toParentViewController: self)
            self.m_currentTableView = tableView
            self.delegate?.textChanged(query: self.m_roomsSearchBar.text!)
        })
    }

    @IBAction func segIndexChanged(_ sender: Any) {
        switch m_roomsSegControl.selectedSegmentIndex {
        case 0:
            switchTableView(tableView: m_likedRoomsTableView)
            self.m_roomsSearchBar.placeholder = "Filter"
            self.navigationItem.rightBarButtonItem = nil
            delegate = m_likedRoomsTableView.self
        case 1:
            switchTableView(tableView: m_locationRoomsTableView)
            self.m_roomsSearchBar.placeholder = "Search Place"
            self.navigationItem.rightBarButtonItem = nil
            delegate = m_locationRoomsTableView.self
        case 2:
            switchTableView(tableView: m_userRoomsTableView)
            self.m_roomsSearchBar.placeholder = "Filter"
            self.navigationItem.rightBarButtonItem = m_addRoomButton
            delegate = m_userRoomsTableView.self
        case 3:
            switchTableView(tableView: m_savedRoomsTableView)
            self.m_roomsSearchBar.placeholder = "Filter"
            self.navigationItem.rightBarButtonItem = nil
            delegate = m_savedRoomsTableView.self
        default:
            break
        }
    }
    
    // SearchBar Functions
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        m_roomsSearchBar.showsCancelButton = true
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        m_roomsSearchBar.resignFirstResponder()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.delegate?.textChanged(query: searchText)
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        m_roomsSearchBar.showsCancelButton = false
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        m_roomsSearchBar.showsCancelButton = false
        m_roomsSearchBar.resignFirstResponder()
    }
    
    @objc func addRoomButtonClicked() {
        let alert: UIAlertController = UIAlertController.init(title: "Create A Room", message: "Enter room name", preferredStyle: .alert)
        
        let submit: UIAlertAction = UIAlertAction.init(title: "Submit", style: .default, handler: {(action: UIAlertAction) in
            
            if (alert.textFields!.count > 0 ) {
                let nameTextField: UITextField = alert.textFields![0]
                let descriptionTextField: UITextField = alert.textFields![1]
                let passWordTextField: UITextField = alert.textFields![2]
                if nameTextField.text != "" {
                    
                    if descriptionTextField.text != "" {
                        
                        if nameTextField.text!.size(withAttributes: [NSAttributedStringKey.font : UIFont.systemFont(ofSize: 17)]).width < CGFloat(self.view.frame.size.width*0.65) {
                            
                            if descriptionTextField.text!.size(withAttributes: [NSAttributedStringKey.font : UIFont.systemFont(ofSize: 12)]).width < CGFloat(self.view.frame.size.width*0.65) {
                                
                                DBProvider.Instance.createRoom(name: nameTextField.text!, description: descriptionTextField.text,   password: passWordTextField.text, roomCreated: {(room, success) in
                                    if success{
                                        self.delegate?.roomCreated(room: room!)
                                    } else {
                                        self.alertUser(title: "Room Name Already Exists", message: "Enter another room name")
                                    }
                                })
                            } else {
                                self.alertUser(title: "Invalid Format", message: "Room description too long")
                            }
                        } else {
                            self.alertUser(title: "Invalid Format", message: "Room name too long")
                        }
                    } else {
                        self.alertUser(title: "Invalid Format", message: "Enter a room description")
                    }
                } else {
                    self.alertUser(title: "Invalid Format", message: "Enter a room name.")
                }
            }
        })
        
        let cancel: UIAlertAction = UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(submit)
        alert.addAction(cancel)
        alert.addTextField(configurationHandler: {(nameTextField: UITextField) in
            nameTextField.placeholder = "Room Name"
        })
        alert.addTextField(configurationHandler: {(descriptionTextField: UITextField) in
            descriptionTextField.placeholder = "Description"
        })
        alert.addTextField(configurationHandler: {(passwordTextField: UITextField) in
            passwordTextField.placeholder = "Password"
        })
        present(alert, animated: true, completion: nil)
    }
    
    func alertUser(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }
    
}
