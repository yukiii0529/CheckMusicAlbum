//
//  AlbumListCollectionViewCell.swift
//  CheckMusicAlbum
//
//  Created by 田中勇輝 on 2022/09/23.
//

import UIKit

protocol AlbumListView: AnyObject {
    func setAlbumTitle(_ title: String)
    func setAlbumArtist(_ artist: String)
    func setAlbumReleaseDate(_ releaseDate: Date)
    func setAlbumImage(_ imageUrl: String)
}

class AlbumListCollectionViewCell: UICollectionViewCell, AlbumListView {

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
    
    func setAlbumTitle(_ title: String) {
        titleLabel.text = title
    }

    func setAlbumArtist(_ artist: String) {
        artistLabel.text = artist
    }

    func setAlbumReleaseDate(_ releaseDate: Date) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        let dateString:String = formatter.string(from: releaseDate)
        releaseDayLabel.text = dateString
    }

    func setAlbumImage(_ imageUrl: String) {
        if imageUrl != "" {
            guard let fileURL: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(imageUrl) else { return }
            //パス型に変換
            let filePath = fileURL.path
            jacketImage.image = UIImage(contentsOfFile: filePath)
        }
    }

}
