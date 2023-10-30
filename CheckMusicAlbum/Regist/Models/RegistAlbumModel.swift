//
//  RegistAlbumModel.swift
//  CheckMusicAlbum
//
//  Created by 田中勇輝 on 2023/10/29.
//

import Foundation
import RealmSwift
import SVProgressHUD

protocol RegistAlbumModelInput {
    func cntArtistAlbum(id: String) -> Int // アーティストのアルバム数
    func existArtistCheck(artistName: String) -> (addArtistFlg: Bool, ArtistId: String) // アーティスト登録チェック
    
    func saveImage(pngImageData: Data?) -> String // 画像を保存する関数
    func createLocalDataFile() -> String // 保存するためのパスを作成
    
    func addAlbum(album: Album) -> Bool // アルバム追加
    func addArtist(artist: Artist) -> Bool // アーティスト追加
    
    func deleteArtist(artistId: String) -> Bool // アーティスト削除
    func deleteFile(imagePath: String) // 画像ファイル削除
    func deleteAlbum(album: Album) -> Bool // アルバム削除
}

final class RegistAlbumModel: RegistAlbumModelInput {
    // ドキュメントディレクトリの「ファイルURL」（URL型）定義
    var documentDirectoryFileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    // ドキュメントディレクトリの「パス」（String型）定義
    let filePath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    
    private var realm: Realm? // Realm インスタンスをプライベートに変更

    init() {
        do {
            self.realm = try Realm() // Realm インスタンスを初期化
        } catch {
            // エラーハンドリングを行うことをおすすめします
            print("Error initializing Realm: \(error)")
        }
    }
    
    /// アーティストのアルバム数
    /// - Parameter id: アーティストID
    /// - Returns: 登録されているアルバム数
    func cntArtistAlbum(id: String) -> Int {
        return self.realm?.objects(Album.self).filter("artistId == %@", id).count ?? 0
    }
    
    /// アーティスト登録チェック
    /// - Parameter artistName: アーティスト名
    /// - Returns: アーティストID
    func existArtistCheck(artistName: String) -> (addArtistFlg: Bool, ArtistId: String) {
        if let existArtist = realm?.objects(Artist.self).filter("name == %@", artistName), existArtist.count != 0 {
             return (false, existArtist.first?.id ?? "")
        } else {
             return (true, NSUUID().uuidString)
        }
    }
    
    /// 画像を保存する関数
    /// - Parameter pngImageData: 画像情報
    /// - Returns: 保存先パス
    func saveImage(pngImageData: Data?) -> String{
        let imageUrl = createLocalDataFile()
        //pngで保存する場合
        do {
            try pngImageData!.write(to: self.documentDirectoryFileURL)
        } catch {
            //エラー処理
            print("エラー")
        }
        return imageUrl
    }
    
    /// 保存するためのパスを作成
    /// - Returns: 登録時のファイル名
    func createLocalDataFile() -> String{
        // 作成するテキストファイルの名前
        let fileName = "\(NSUUID().uuidString).png"

        // DocumentディレクトリのfileURLを取得
        if self.documentDirectoryFileURL != nil {
            // ディレクトリのパスにファイル名をつなげてファイルのフルパスを作る
            let path = self.documentDirectoryFileURL.appendingPathComponent(fileName)
            self.documentDirectoryFileURL = path
        }
        
        return fileName
    }
    
    /// アルバム追加
    /// - Parameter album: 追加するアルバム情報
    /// - Returns: 追加できたかどうか
    func addAlbum(album: Album) -> Bool {
        do {
            try realm?.write {
                self.realm?.add(album, update: .modified)
            }
            return true
        } catch {
            print("errorが発生しました。")
            SVProgressHUD.showError(withStatus: "登録の際にエラーが発生しました。")
            return false
        }
    }
    
    /// アーティスト追加
    /// - Parameter artist: 追加するアーティスト情報
    /// - Returns: 追加できたかどうか
    func addArtist(artist: Artist) -> Bool {
        do {
            try realm?.write {
                self.realm?.add(artist, update: .modified)
            }
            return true
        } catch {
            print("errorが発生しました。")
            SVProgressHUD.showError(withStatus: "登録の際にエラーが発生しました。")
            return false
        }
    }
    
    /// アーティスト削除
    /// - Parameter artistId: 削除するアーティストID
    /// - Returns: 削除できたかどうか
    func deleteArtist(artistId: String) -> Bool {
        do{
            try self.realm?.write{
                self.realm?.delete((self.realm?.objects(Artist.self).filter("id == %@", artistId))!)
            }
            return true
        }catch {
            return false
        }
    }
    
    /// 画像ファイル削除
    /// - Parameter imagePath: 保存先パス
    func deleteFile(imagePath: String){
        //ファイルの削除
        if imagePath != ""{
            try? FileManager.default.removeItem(atPath: imagePath)
        }
    }
    
    /// アルバム削除
    /// - Parameter album: 削除するアルバム
    /// - Returns: 削除できたかどうか
    func deleteAlbum(album: Album) -> Bool {
        do{
            try self.realm?.write{
                self.realm?.delete(album)
            }
            return true
        }catch {
            return false
        }
    }
}
