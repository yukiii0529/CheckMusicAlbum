//
//  RegistAlbumViewPresenter.swift
//  CheckMusicAlbum
//
//  Created by 田中勇輝 on 2023/10/29.
//

import Foundation
import RealmSwift

protocol RegistAlbumViewPresenterInput: AnyObject {
    func viewWillAppear(updateFlg: Bool, album: Album?)
    func addJacketButtonTapped() // 画像追加ボタン押下時
    func registButtonTapped(alreadyRegistAlbum: Album?, title: String, artistName: String, date: Date, saveImageFlg: Bool, image: Data?, note: String, updateFlg: Bool) // アルバム登録
    func deleteButtonTapped(album: Album, imagePath: String) // アルバム削除
    
    func textFieldDidChange(title: String?, artist: String?) // UITextFIeldの入力チェック
    func imageSelected(_ image: UIImage) // 選択、撮影画像表示
}

protocol RegistAlbumViewPresenterOutput: AnyObject {
    func configureAddTarget() // UITextFieldにトリガー設置
    func configureToolBar() // ツールバーの設定
    func configureNavigationBar() // UINavigationBarの設定
    func setUpAlreadyRegistAlbum(album: Album) // 更新の場合、既存登録されている内容を表示
    
    func showImageSourceOptions() // 画像設定の際、カメラかライブラリか選択するアラート設定
    func addAlbumSuccessModal() // アルバム登録成功アラート
    
    func showDeletionSuccessMessage() // 削除後一覧画面へ戻る
    func showDeletionFailureMessage() // 削除失敗時の表示
    
    func displayImage(_ image: UIImage) // 画像の背景設定
    
    func enableRegistrationButton(_ enabled: Bool) // 登録ボタンの活性、非活性
}

final class RegistAlbumViewPresenter {
    weak var view: RegistAlbumViewPresenterOutput?
    private let model: RegistAlbumModelInput
    var albumArray: Results<Album>?
    var artistArray: Results<Artist>?

    //　このへん何をしているんだろうという人は「依存性注入(DI)」を調べてみてください。
    init(view: RegistAlbumViewPresenterOutput, model: RegistAlbumModelInput) {
        self.view = view
        self.model = model
    }
}

extension RegistAlbumViewPresenter: RegistAlbumViewPresenterInput {
    func viewWillAppear(updateFlg: Bool, album: Album?) {
        // ビューの初期設定を行うロジック
        self.view?.configureAddTarget()
        self.view?.configureToolBar()
        self.view?.configureNavigationBar()
        
        if updateFlg {
            self.view?.setUpAlreadyRegistAlbum(album: album!)
        }
    }
    
    
    /// 画像追加ボタン押下時
    func addJacketButtonTapped() {
        self.view?.showImageSourceOptions()
    }
    
    
    /// アルバム登録
    /// - Parameters:
    ///   - alreadyRegistAlbum: 既存登録されているアルバム内容
    ///   - title: タイトル
    ///   - artistName: アーティスト名
    ///   - date: 発売日
    ///   - saveImageFlg: 画像登録するかどうか
    ///   - image: 画像
    ///   - note: 鼻腔
    ///   - updateFlg: 更新か登録か
    func registButtonTapped(alreadyRegistAlbum: Album?, title: String, artistName: String, date: Date, saveImageFlg: Bool, image: Data?, note: String, updateFlg: Bool) {
        let artist = Artist()
        let album = Album()
        var addArtistFlg = false
        if updateFlg {
            album.id = alreadyRegistAlbum!.id
        } else {
            album.id = NSUUID().uuidString
        }
        album.title = title
        let artistResult = self.model.existArtistCheck(artistName: artistName)
        album.artistId = artistResult.ArtistId
        addArtistFlg = artistResult.addArtistFlg
        album.releaseDay = date
        // 画像保存
        if saveImageFlg {
            let imageUrl = self.model.saveImage(pngImageData: image)
            album.imageUrl = imageUrl
        }
        // 備考
        album.note = note
        
        let addAlbumSuccessFlg = self.model.addAlbum(album: album)
        
        var addArtistSuccessFlg = true
        if addArtistFlg {
            artist.id = artistResult.ArtistId
            artist.name = artistName
            addArtistSuccessFlg = self.model.addArtist(artist: artist)
        }
        
        if addAlbumSuccessFlg, addArtistSuccessFlg {
            self.view?.addAlbumSuccessModal()
        }
    }
    
    
    /// アルバム削除
    /// - Parameters:
    ///   - album: 削除するアルバム
    ///   - imagePath: 画像保存先URL
    func deleteButtonTapped(album: Album, imagePath: String) {
        let cntArtistAlbum = self.model.cntArtistAlbum(id: album.artistId)
        var deleteArtistSuccessFlg = true
        if cntArtistAlbum == 1 {
            deleteArtistSuccessFlg = self.model.deleteArtist(artistId: album.artistId)
        }
        self.model.deleteFile(imagePath: imagePath)
        let deleteAlbumSuccessFlg = self.model.deleteAlbum(album: album)
        
        if deleteArtistSuccessFlg, deleteAlbumSuccessFlg {
            self.view?.showDeletionSuccessMessage()
        } else {
            self.view?.showDeletionFailureMessage()
        }
    }
    
    
    /// UITextFIeldの入力チェック
    /// - Parameters:
    ///   - title: タイトル
    ///   - artist: アーティスト名
    func textFieldDidChange(title: String?, artist: String?) {
        if let title = title, !title.isEmpty, let artist = artist, !artist.isEmpty {
            view?.enableRegistrationButton(true)
        } else {
            view?.enableRegistrationButton(false)
        }
    }
    
    
    /// 選択、撮影画像表示
    /// - Parameter image: 選択、撮影された画像
    func imageSelected(_ image: UIImage) {
        // 画像が選択されたら、Viewに画像を表示させる
        self.view?.displayImage(image)
    }
    
}
