//
//  ChatTableViewCell.swift
//  Helloquent
//
//  Created by Morgan Trudeau on 2018-02-14.
//  Copyright © 2018 Morgan Trudeau. All rights reserved.
//

import UIKit

class ChatTableViewCell: UITableViewCell {

    //MARK: Properties
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var avatarImage: UIImageView!
    @IBOutlet weak var notificationLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
