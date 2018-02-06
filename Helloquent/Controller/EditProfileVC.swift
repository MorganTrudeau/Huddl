//
//  EditProfileVC.swift
//  Helloquent
//
//  Created by Morgan Trudeau on 2018-01-29.
//  Copyright © 2018 Morgan Trudeau. All rights reserved.
//

import Foundation
import UIKit
import CropViewController
import Cache
import Crashlytics

class EditProfileVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPickerViewDelegate, CropViewControllerDelegate {
    
    @IBOutlet weak var m_profileImageView: UIImageView!
    
    @IBOutlet weak var m_changeImageButton: UIButton!
    
    @IBOutlet weak var m_displayNameLabel: UILabel!
    
    @IBOutlet weak var m_displayNameTextField: UITextField!
    
    @IBOutlet weak var m_colorLabel: UILabel!
    
    @IBOutlet weak var m_colorCollectionView: UICollectionView!
    
    @IBOutlet weak var m_logoutButton: UIButton!
    
    let m_picker = UIImagePickerController()
    let m_authProvider = AuthProvider.Instance
    let m_cacheStorage = CacheStorage.Instance
    let m_dbProvider = DBProvider.Instance
    
    let m_uiColors = ColorHandler.Instance.uiColors
    let m_stringColors = ColorHandler.Instance.colors
    var m_selectedCellIndexPath: IndexPath?
    var m_profileImageChanged = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        m_colorCollectionView.delegate = self
        m_colorCollectionView.dataSource = self
        
        m_picker.delegate = self
        
        setUpUI()
        loadUIWithCache()
        
        // Tap screen to dismiss keyboard
        let screenTap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(EditProfileVC.dismissKeyboard))
        screenTap.cancelsTouchesInView = false
        view.addGestureRecognizer(screenTap)
        
        // Tap profile image to change
        let imageTap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(EditProfileVC.choosePicture(_:)))
        m_profileImageView.isUserInteractionEnabled = true
        m_profileImageView.addGestureRecognizer(imageTap)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    
    func loadUIWithCache() {
        if let user = try? m_cacheStorage.m_userStorage.object(ofType: User.self, forKey: AuthProvider.Instance.userID()) {
            self.m_displayNameTextField.text = user.name
            let index = m_uiColors.index(of: ColorHandler.Instance.convertToUIColor(colorString: user.color))
            let indexPath = IndexPath(item: index!, section: 0)
            m_selectedCellIndexPath = indexPath
            let cell = m_colorCollectionView.cellForItem(at: indexPath)
            cell?.layer.borderWidth = 4
            cell?.layer.borderColor = UIColor.black.cgColor
            
            if let image = try? m_cacheStorage.m_mediaStorage.object(ofType: ImageWrapper.self, forKey: user.avatar).image {
                self.m_profileImageView.image = image
            }
        }
    }
    
    func setUpUI() {
        self.navigationController?.navigationBar.barTintColor = UIColor.init(white: 0.1, alpha: 1)
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.lightText]
        
        let cancelButton = UIBarButtonItem(image: UIImage(named: "cancel"), style: .plain, target: self, action: #selector(EditProfileVC.cancelEdit))
        
        let saveButton = UIBarButtonItem(image: UIImage(named: "check"), style: .plain, target: self, action: #selector(EditProfileVC.save))
        
        self.navigationItem.backBarButtonItem?.isEnabled = false
        self.navigationItem.leftBarButtonItem = cancelButton
        self.navigationItem.rightBarButtonItem = saveButton
    
        
        m_profileImageView.layer.borderWidth = 1.0
        m_profileImageView.layer.masksToBounds = false
        m_profileImageView.layer.borderColor = UIColor.black.cgColor
        m_profileImageView.layer.cornerRadius = (m_profileImageView?.frame.size.height)!/2
        m_profileImageView.clipsToBounds = true
        m_profileImageView.center.y = CGFloat(150)
        
        m_changeImageButton.center.y = CGFloat(240)
        
        m_displayNameLabel.center.y = CGFloat(290)
        
        m_displayNameTextField.center.y = CGFloat(320)
        m_displayNameTextField.underlined()
        
        m_colorLabel.center.y = CGFloat(380)
        
        m_colorCollectionView.center.y = CGFloat(480)
        
        m_logoutButton.layer.borderWidth = 2.0
        m_logoutButton.layer.borderColor = UIColor(red: 102/255, green: 0, blue: 1, alpha: 1).cgColor
        m_logoutButton.layer.cornerRadius = 5
        
        
        /////// Crash
        let crashButton = UIButton(frame: CGRect(x: 0, y: view.frame.size.height*0.94, width: 100, height: 30))
        crashButton.center.x = view.center.x
        crashButton.setTitle("Dont Press", for: .normal)
        crashButton.setTitleColor(UIColor.red, for: .normal)
        crashButton.layer.borderWidth = 2
        crashButton.layer.borderColor = UIColor.red.cgColor
        crashButton.addTarget(self, action: #selector(EditProfileVC.crash), for: .touchUpInside)
        view.addSubview(crashButton)
        ///////
    }
    
    ///////
    @objc func crash() {
        Crashlytics.sharedInstance().crash()
    }
    ///////
    
    // Color picker collectionView Functions
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return m_uiColors.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = m_colorCollectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        if indexPath.row == m_selectedCellIndexPath?.row {
            cell.layer.borderWidth = 4
            cell.layer.borderColor = UIColor.black.cgColor
        } else {
            cell.layer.borderWidth = 0
        }
        cell.backgroundColor = m_uiColors[indexPath.row]
        cell.layer.cornerRadius = 5
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath:
        IndexPath) {
        
//        var cell: UICollectionViewCell
//
//        // Remove border from current cell
//        cell = m_colorCollectionView.cellForItem(at: m_selectedCellIndexPath!)!
//        cell.layer.borderWidth = 0
//
//        // Apply border to selected cell
        m_selectedCellIndexPath = indexPath
        m_colorCollectionView.reloadData()
//        cell = m_colorCollectionView.cellForItem(at: indexPath)!
//        cell.layer.borderWidth = 4
//        cell.layer.borderColor = UIColor.black.cgColor
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
        m_profileImageChanged = true
        dismiss(animated: true, completion: nil)
    }
    
    /**
     Button Function
    **/
    
    // Save Profile Settings
    
    @objc func save() {
        if Reachability.isConnectedToNetwork() {
            let displayName: String = m_displayNameTextField.text!
            var color = try? m_cacheStorage.m_userStorage.object(ofType: User.self, forKey: m_authProvider.userID()).color
            var newAvatar: UIImage? = nil
            
            if m_displayNameTextField.text == "" {
                alertUser(title: "Invalid Display Name", message: "Display name cannot be blank")
            } else {
                if m_selectedCellIndexPath != nil {
                    color = m_stringColors[(m_selectedCellIndexPath?.row)!]
                }
                if m_profileImageChanged {
                    let loadingOverlay = LoadingOverlay()
                    loadingOverlay.modalPresentationStyle = .overFullScreen
                    present(loadingOverlay, animated: false, completion: nil)
                    newAvatar = m_profileImageView.image
                }
                // Update Firebase child
                DBProvider.Instance.saveProfile(displayName: displayName, color: color!, avatar: newAvatar, completion:{(savedImage) in
                    if savedImage {
                        self.dismiss(animated: false, completion: nil)
                    }
                    self.m_profileImageChanged = false
                    self.navigationController?.popViewController(animated: true)
                })
            }
        } else {
            self.alertUser(title: "Network Connection Not Available", message: "Connect to update profile")
        }
    }
    
    // Cancel edit and go back
    
    @objc func cancelEdit() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func logout(_ sender: Any) {
        if AuthProvider.Instance.logout() {
            dismiss(animated: true, completion: nil)
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
    
}
