//
//  HomeModel.swift
//  CheckMusicAlbum
//
//  Created by 田中勇輝 on 2023/03/05.
//

import Foundation
import RealmSwift

protocol HomeModelInput {
    func fetchAlbums() -> Results<Album> // アルバム取得
    func fetchArtists() -> Results<Artist> // アーティスト取得
    func searchAlbums(id: String) -> Results<Album> // アーティストでアルバム検索
}

final class HomeModel: HomeModelInput {
    private var realm: Realm? // Realm インスタンスをプライベートに変更

    init() {
        do {
            self.realm = try Realm() // Realm インスタンスを初期化
        } catch {
            // エラーハンドリングを行うことをおすすめします
            print("Error initializing Realm: \(error)")
        }
    }
    
    
    /// アルバム取得
    /// - Returns: アルバム
    func fetchAlbums() -> Results<Album> {
        return (self.realm?.objects(Album.self))!
    }
    
    
    /// アーティスト取得
    /// - Returns: アーティスト
    func fetchArtists() -> Results<Artist> {
        return (self.realm?.objects(Artist.self))!
    }
    
    
    /// アーティストでアルバム検索
    /// - Parameter id: 選択したアーティストID
    /// - Returns: アーティストに基づいたアルバム
    func searchAlbums(id: String) -> Results<Album> {
        return (self.realm?.objects(Album.self).filter("artistId == %@", id))!
    }
    
}
