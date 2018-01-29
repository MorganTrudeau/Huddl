//
//  ImageDisplayVC.swift
//  Helloquent
//
//  Created by Morgan Trudeau on 2018-01-29.
//  Copyright © 2018 Morgan Trudeau. All rights reserved.
//

import UIKit

class ImageDisplayVC: UIViewController {
    
    private static var _instance = ImageDisplayVC()
    
    static var Instance: ImageDisplayVC {
        return _instance
    }
    
    var m_image: UIImage?
    var m_imageView: UIImageView?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.black
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(ImageDisplayVC.tapToClose))
        self.view.addGestureRecognizer(tap)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let heightRatio = (m_image?.size.height)! / (m_image?.size.width)!
        let imageWidth = self.view.frame.size.width
        let imageHeight = imageWidth * heightRatio
        m_imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: imageWidth, height: imageHeight))
        m_imageView?.center.y = self.view.center.y
        m_imageView?.image = m_image
        self.view.addSubview(m_imageView!)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        m_imageView?.removeFromSuperview()
    }
    
    func setImage(image: UIImage) {
        m_image = image
    }
    
    func setView(frame: CGRect) {
        self.view.frame = frame
    }
    
    @objc func tapToClose() {
        self.dismiss(animated: true, completion: nil)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }

}
