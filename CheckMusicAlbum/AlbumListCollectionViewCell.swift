//
//  AlbumListCollectionViewCell.swift
//  CheckMusicAlbum
//
//  Created by 田中勇輝 on 2022/09/23.
//

import UIKit

class AlbumListCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var jacketImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var releaseDayLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.titleLabel.text = ""
        self.artistLabel.text = ""
        self.releaseDayLabel.text = ""
        self.jacketImage.image = UIImage(named: "noimage.png")
   }

}
