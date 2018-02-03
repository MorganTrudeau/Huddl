//
//  ProfileVC.swift
//  Helloquent
//
//  Created by Morgan Trudeau on 2018-01-29.
//  Copyright © 2018 Morgan Trudeau. All rights reserved.
//

import Foundation
import UIKit
import CropViewController
import Cache

class ProfileVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPickerViewDelegate, CropViewControllerDelegate, CacheDelegate {
    
    @IBOutlet weak var m_colorColletionView: UICollectionView!
    @IBOutlet weak var m_displayNameTextField: UITextField!
    @IBOutlet weak var m_profileImageView: UIImageView!
    
    let m_picker = UIImagePickerController()
    let m_authProvider = AuthProvider.Instance
    let m_cacheStorage = CacheStorage.Instance
    let m_dbProvider = DBProvider.Instance
    
    let m_uiColors = ColorHandler.Instance.uiColors
    let m_stringColors = ColorHandler.Instance.colors
    var m_selectedCellIndexPath: IndexPath? = nil
    var m_currentUser: User?
    var m_currentUserImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        m_colorColletionView.delegate = self
        m_colorColletionView.dataSource = self
        
        m_picker.delegate = self
        
        m_cacheStorage.delegate = self
        
        setUpUI()
        loadUIWithCache()
        DispatchQueue.global().async {
            self.updateCache()
        }
        
        
        
        // Tap screen to dismiss keyboard
        let screenTap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ProfileVC.dismissKeyboard))
        screenTap.cancelsTouchesInView = false
        view.addGestureRecognizer(screenTap)
        
        // Tap profile image to change
        let imageTap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ProfileVC.choosePicture(_:)))
        m_profileImageView.isUserInteractionEnabled = true
        m_profileImageView.addGestureRecognizer(imageTap)
    }
    
    func loadUIWithCache() {
        
        if let displayName = try? m_cacheStorage.m_userStorage.object(ofType: User.self, forKey: m_authProvider.userID()).name {
            m_displayNameTextField.text = displayName
        }
        if let image = try? m_cacheStorage.m_imageStorage.object(ofType: ImageWrapper.self, forKey: m_authProvider.userID()).image {
            m_profileImageView.image = image
        }
    }
    
    func updateCache() {
        m_dbProvider.getUser(id: m_authProvider.userID())
    }
    
    func setUpUI() {
        
        let topBar = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 64))
        topBar.backgroundColor = UIColor.init(white: 0.23, alpha: 1)
        
        let saveButton = UIButton(frame: CGRect(x: topBar.frame.size.width - 75, y: 20, width: 80, height: 40))
        saveButton.setTitle("Save", for: .normal)
        saveButton.setTitleColor(UIColor(red: 133/255, green: 51/255, blue: 1, alpha: 1), for: .normal)
        saveButton.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        saveButton.addTarget(self, action: #selector(ProfileVC.save), for: .touchUpInside)
        
        let title = UILabel(frame: CGRect(x: 0, y: 20, width: 100, height: 44))
        title.text = "Profile"
        title.textAlignment = .center
        title.font = UIFont.boldSystemFont(ofSize: 17)
        title.center.x = topBar.center.x
        title.textColor = UIColor.lightText
        
        let logoutButton = UIButton(frame: CGRect(x: 0, y: 20, width: 80, height: 40))
        logoutButton.setTitle("Logout", for: .normal)
        logoutButton.setTitleColor(UIColor(red: 133/255, green: 51/255, blue: 1, alpha: 1), for: .normal)
        logoutButton.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        logoutButton.addTarget(self, action: #selector(ProfileVC.logout), for: .touchUpInside)
    
        m_displayNameTextField.underlined()
        
        m_profileImageView.layer.borderWidth = 1.0
        m_profileImageView.layer.masksToBounds = false
        m_profileImageView.layer.borderColor = UIColor.black.cgColor
        m_profileImageView.layer.cornerRadius = (m_profileImageView?.frame.size.height)!/2
        m_profileImageView.clipsToBounds = true
        
        self.view.addSubview(topBar)
        topBar.addSubview(title)
        topBar.addSubview(saveButton)
        topBar.addSubview(logoutButton)
    }
    
    // Color picker collectionView Functions
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return m_uiColors.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = m_colorColletionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        cell.backgroundColor = m_uiColors[indexPath.row]
        cell.layer.cornerRadius = 5
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath:
        IndexPath) {
        
        var cell: UICollectionViewCell
        
        if m_selectedCellIndexPath != nil {
            cell = m_colorColletionView.cellForItem(at: m_selectedCellIndexPath!)!
            cell.layer.borderWidth = 0
        }
        
        m_selectedCellIndexPath = indexPath
        cell = m_colorColletionView.cellForItem(at: indexPath)!
        cell.layer.borderWidth = 4
        cell.layer.borderColor = UIColor.black.cgColor
    }
    
    // Change Profile Picture Functions
    
    @IBAction func choosePicture(_ sender: Any) {
        present(m_picker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            dismiss(animated: false, completion: nil)
            presentCropViewController(image: image)
        }
        dismiss(animated: true, completion: nil)
    }
    
    func presentCropViewController(image: UIImage) {
        
        let cropViewController = CropViewController(croppingStyle: .circular, image: image)
        cropViewController.delegate = self
        present(cropViewController, animated: true, completion: nil)
    }
    
    func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
        m_profileImageView.image = image
        dismiss(animated: true, completion: nil)
    }
    
    
    // Save Profile Settings
    @objc func save(sender: UIButton) {
        let displayName: String = m_displayNameTextField.text!
        var color = try? m_cacheStorage.m_userStorage.object(ofType: User.self, forKey: m_authProvider.userID()).color
        let currentAvatar = try? m_cacheStorage.m_imageStorage.object(ofType: ImageWrapper.self, forKey: m_authProvider.userID()).image
        var newAvatar: UIImage? = nil
        
        if m_displayNameTextField.text == "" {
            alertUser(title: "Invalid Display Name", message: "Display name cannot be blank")
        } else {
            if m_selectedCellIndexPath != nil {
                color = m_stringColors[(m_selectedCellIndexPath?.row)!]
            }
            if m_profileImageView.image != currentAvatar {
                let loadingOverlay = LoadingOverlay()
                loadingOverlay.modalPresentationStyle = .overFullScreen
                present(loadingOverlay, animated: false, completion: nil)
                newAvatar = m_profileImageView.image
            }
            // Update Firebase child
            DispatchQueue.global().async {
                DBProvider.Instance.saveProfile(displayName: displayName, color: color!, avatar: newAvatar, completion: {(savedImage) in
                    if savedImage {
                        self.dismiss(animated: false, completion: nil)
                    }
                    self.alertUser(title: "Success", message: "Profile saved")
                })
            }
        }
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func alertUser(title: String, message: String) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }
    
    @objc func logout() {
        if AuthProvider.Instance.logout() {
            dismiss(animated: true, completion: nil)
        }
    }
    
    func cacheUpdated() {
        loadUIWithCache()
    }
}
