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

class ProfileVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPickerViewDelegate, CropViewControllerDelegate {
    
    @IBOutlet weak var m_colorColletionView: UICollectionView!
    @IBOutlet weak var m_displayNameTextField: UITextField!
    @IBOutlet weak var m_profileImageView: UIImageView!
    
    let m_uiColors = ColorHandler.Instance.uiColors
    let m_stringColors = ColorHandler.Instance.colors
    var m_selectedCellIndexPath: IndexPath? = nil
    
    let m_picker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ProfileVC.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        m_colorColletionView.delegate = self
        m_colorColletionView.dataSource = self
        
        m_picker.delegate = self
        
        setUpUI()
    }
    
    func setUpUI() {
        m_displayNameTextField.underlined()
        
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
        
        m_displayNameTextField.text = AuthProvider.Instance.currentUser?.name
        
        m_profileImageView.image = AuthProvider.Instance.currentUser?.avatar
        m_profileImageView.layer.borderWidth=1.0
        m_profileImageView.layer.masksToBounds = false
        m_profileImageView.layer.borderColor = UIColor.black.cgColor
        m_profileImageView.layer.cornerRadius = (m_profileImageView?.frame.size.height)!/2
        m_profileImageView.clipsToBounds = true
        
        self.view.addSubview(topBar)
        topBar.addSubview(title)
        topBar.addSubview(saveButton)
        topBar.addSubview(logoutButton)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
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
    
    // Image Set Functions
    
    
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
    
    @objc func save(sender: UIButton) {
        let newDisplayName: String = m_displayNameTextField.text!
        var newColor: String? = AuthProvider.Instance.currentUser?.color
        let newAvatar: UIImage = m_profileImageView.image!
        
        if m_selectedCellIndexPath != nil {
            newColor = m_stringColors[(m_selectedCellIndexPath?.row)!]
        }
        if m_displayNameTextField.text == "" {
            alertUser(title: "Invalid Display Name", message: "Display name cannot be blank")
        } else {
            DBProvider.Instance.saveProfile(newDisplayName: newDisplayName, newColor: newColor, newAvatar: newAvatar)
            alertUser(title: "Success", message: "Profile saved")
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
}
