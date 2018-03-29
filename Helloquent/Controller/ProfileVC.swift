//
//  ProfileVC.swift
//  Helloquent
//
//  Created by Morgan Trudeau on 2018-02-05.
//  Copyright © 2018 Morgan Trudeau. All rights reserved.
//

import Foundation
import UIKit
import Cache

class ProfileVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet weak var m_profileImageView: UIImageView!
    @IBOutlet weak var m_displayNameLabel: UILabel!
    @IBOutlet weak var m_displayNameTextField: UITextField!
    @IBOutlet weak var m_colorLabel: UILabel!
    @IBOutlet weak var m_colorCollectionView: UICollectionView!
    @IBOutlet weak var m_blockListButton: UIButton!
    
    let m_picker = UIImagePickerController()
    let m_cacheStorage = CacheStorage.Instance
    let m_dbProvider = DBProvider.Instance
    
    let m_uiColors = ColorHandler.Instance.uiColors
    var m_selectedCellIndex: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        m_colorCollectionView.delegate = self
        m_colorCollectionView.dataSource = self
        
        setUpUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadUIWithCache()
    }
    
    func setUpUI() {
        self.navigationController?.navigationBar.barTintColor = UIColor.init(white: 0.1, alpha: 1)
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.lightText]
        
        m_profileImageView.layer.borderWidth = 1.0
        m_profileImageView.layer.masksToBounds = false
        m_profileImageView.layer.borderColor = UIColor.black.cgColor
        m_profileImageView.layer.cornerRadius = (m_profileImageView?.frame.size.height)!/2
        m_profileImageView.clipsToBounds = true
        m_profileImageView.center.y = view.frame.size.height*0.25
        
        m_displayNameTextField.isUserInteractionEnabled = false
        m_displayNameTextField.underlined()
        
        m_blockListButton.layer.borderWidth = 2.0
        m_blockListButton.layer.borderColor = UIColor(red: 102/255, green: 0, blue: 1, alpha: 1).cgColor
        m_blockListButton.layer.cornerRadius = 5
    }
    
    func loadUIWithCache() {
        if let user = try? m_cacheStorage.m_userStorage.object(ofType: User.self, forKey: AuthProvider.Instance.userID()) {
            self.m_displayNameTextField.text = user.name
            let index = ColorHandler.Instance.colors.index(of: user.color)
            m_selectedCellIndex = index
            m_colorCollectionView.reloadData()
            
            if let image = try? m_cacheStorage.m_mediaStorage.object(ofType: ImageWrapper.self, forKey: user.avatar).image {
                self.m_profileImageView.image = image
            }
        }
    }
    
    func updateCache() {
        m_dbProvider.getUser(id: AuthProvider.Instance.userID(), completion: nil)
    }
    
    // Color picker collectionView Functions
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return m_uiColors.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = m_colorCollectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        if indexPath.row == m_selectedCellIndex {
            cell.layer.borderWidth = 4
            cell.layer.borderColor = UIColor.black.cgColor
        } else {
            cell.layer.borderWidth = 0
        }
        cell.backgroundColor = m_uiColors[indexPath.row]
        cell.layer.cornerRadius = 5
        return cell
    }
    
    @objc func logout() {
        if AuthProvider.Instance.logout() {
            dismiss(animated: true, completion: nil)
        }
    }
}
