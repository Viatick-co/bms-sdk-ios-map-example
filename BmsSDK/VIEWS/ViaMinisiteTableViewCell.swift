//
//  ViaMinisiteTableViewCell.swift
//  iOsSDK
//
//  Created by Viatick on 20/8/19.
//  Copyright © 2019 Viatick. All rights reserved.
//

import UIKit

public class ViaMinisiteTableViewCell: UITableViewCell {

    @IBOutlet weak var minisiteCover: UIImageView!
    @IBOutlet weak var minisiteTitle: UILabel!
    @IBOutlet weak var minisiteDescription: UILabel!
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        minisiteTitle.layer.shadowColor = UIColor.white.cgColor;
        minisiteTitle.layer.shadowRadius = 4.0;
        minisiteTitle.layer.shadowOpacity = 100.0;
        minisiteTitle.layer.shadowOffset = CGSize.zero;
        minisiteTitle.layer.masksToBounds = false;
        minisiteDescription.layer.shadowColor = UIColor.white.cgColor;
        minisiteDescription.layer.shadowRadius = 4.0;
        minisiteDescription.layer.shadowOpacity = 100.0;
        minisiteDescription.layer.shadowOffset = CGSize.zero;
        minisiteDescription.layer.masksToBounds = false;
    }
    
    public override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
}
