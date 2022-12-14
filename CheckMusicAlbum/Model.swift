//
//  Model.swift
//  CheckMusicAlbum
//
//  Created by 田中勇輝 on 2022/09/24.
//

import UIKit
import RealmSwift

class Album: Object {
    @objc dynamic var id = NSUUID().uuidString
    @objc dynamic var title = ""
    @objc dynamic var artistId = NSUUID().uuidString
    @objc dynamic var releaseDay = Date()
    @objc dynamic var imageUrl = ""
    @objc dynamic var note = ""

    override static func primaryKey() -> String? {
        return "id"
    }
}

class Artist: Object {
    @objc dynamic var id = NSUUID().uuidString
    @objc dynamic var name = ""

    override static func primaryKey() -> String? {
        return "id"
    }
}
