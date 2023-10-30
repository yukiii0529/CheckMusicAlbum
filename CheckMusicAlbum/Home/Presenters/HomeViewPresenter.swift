//
//  HomeViewPresenter.swift
//  CheckMusicAlbum
//
//  Created by 田中勇輝 on 2023/03/05.
//

import Foundation
import RealmSwift

// InputにはViewControllerからどんなイベントを受け取るかを書きます
// 今回のサンプルではボタンをタップされたときに値を受け取って、Modelに渡したい
// Inputの命名はViewでどんなイベントが起こったかを関数名にすると分かりやすくなります
// 例)画面が読み込まれた時に何かの処理が必要ならViewDidLoadというメソッドを作るといいでしょう
protocol HomeViewPresenterInput: AnyObject {
    var numberOfAlbums: Int { get } // アルバム数
    func configureCell(_ cell: AlbumListView, at indexPath: IndexPath) // 各セルの設定
    func didSelectAlbum(at index: Int) // 選択したセルの取得、詳細(更新)画面へ遷移
    
    func viewDidLoad() // 初期設定
    func addButtonTapped() // アルバム追加ボタン押下時
    func chooseArtistButtonTapped() // アーティストを絞るボタン押下時
    func resetButtonTapped() // リセットボタン押下時
    func narrowingDown(index: Int) // アーティスト選択時（検索）
}

// OutputにはModelから処理の結果を受け取ったのち、何を表示してほしいかを書きます
// 今回は計算結果を表示するメソッド、割る数が0でエラーを表示するメソッドを実装しています
protocol HomeViewPresenterOutput: AnyObject {
    func configureCollectionViewLayout() // UICollectionViewのレイアウト設定
    func configurePicker() // UIPickerViewの設定
    func configureNavigationBar() // UINavigationBarのレイアウト設定
    
    func getContents(albums: Results<Album>, artists: Results<Artist>) // アルバムとアーティスト取得
    func showAlbumDetails(album: Album) // 詳細(編集)画面へ遷移
    
    func showNoArtistsAvailableAlert() //「アーティストを絞る」ボタン押下時にアルバムが登録されていない場合、当アラート表示
    func toggleChooseArtistStackView() // 「アーティストを絞る」押下時に検索欄の表示、非表示の切り替えを行う
    func updateSearchArtistLabel(artistName: String) // 検索欄でのUIPickerView選択時にLabelにアーティスト固定表示
    func searchResultAlbumData(albums: Results<Album>) // 検索結果を用いて再描画
    
    func navigateToRegistView() // アルバル登録画面へ遷移
    func resetAlbumData(albums: Results<Album>) // 検索欄にてリセットボタン押下時にアルバム全表示させる
}

final class HomeViewPresenter {

    weak var view: HomeViewPresenterOutput?
    private let model: HomeModelInput
    var albumArray: Results<Album>?
    var artistArray: Results<Artist>?

    //　このへん何をしているんだろうという人は「依存性注入(DI)」を調べてみてください。
    init(view: HomeViewPresenterOutput, model: HomeModelInput) {
        self.view = view
        self.model = model
    }
}

extension HomeViewPresenter: HomeViewPresenterInput {
    // 初期設定
    func viewDidLoad() {
        // ビューの初期設定を行うロジック
        view?.configureCollectionViewLayout()
        view?.configurePicker()
        view?.configureNavigationBar()
        
        self.albumArray = model.fetchAlbums()
        self.artistArray = model.fetchArtists()
        if let albums = self.albumArray , let artists = self.artistArray {
            view?.getContents(albums: albums, artists: artists)
        }
    }
    
    
    /// アルバム数
    var numberOfAlbums: Int {
        return self.albumArray?.count ?? 0
    }
    
    
    /// 各セルの設定
    /// - Parameters:
    ///   - cell: AlbumListView
    ///   - indexPath: 各セル
    func configureCell(_ cell: AlbumListView, at indexPath: IndexPath) {
        if let album = self.albumArray?[indexPath.row] {
            cell.setAlbumTitle(album.title) // タイトル
            if let artistArray = self.artistArray { // アーティスト
                for artist in artistArray {
                    if artist.id == album.artistId {
                        cell.setAlbumArtist(artist.name)
                    }
                }
            }
            cell.setAlbumReleaseDate(album.releaseDay) // リリース日
            cell.setAlbumImage(album.imageUrl) // 画像
        }
    }
    
    
    /// 選択したセルの取得、詳細(更新)画面へ遷移
    /// - Parameter index: 選択したセル番号
    func didSelectAlbum(at index: Int) {
        guard let album = albumArray?[index] else {
            return // インデックスが無効な場合のエラーハンドリング
        }
        view?.showAlbumDetails(album: album)
    }
    
    
    /// アルバム追加ボタン押下時
    func addButtonTapped() {
        self.view?.navigateToRegistView()
    }
    
    /// アーティストを絞るボタン押下時
    func chooseArtistButtonTapped(){
        if self.artistArray?.count == 0 {
            self.view?.showNoArtistsAvailableAlert()
        } else {
            self.view?.toggleChooseArtistStackView()
        }
    }
    
    /// リセットボタン押下時
    func resetButtonTapped(){
        let albums = model.fetchAlbums()
        self.albumArray = albums
        self.view?.resetAlbumData(albums: albums)
    }
    
    /// アーティスト選択時（検索）
    /// - Parameter index: 選択したアーティストの添字
    func narrowingDown(index: Int){
        if self.artistArray?.count != 0 {
            if let artistName = self.artistArray?[index].name {
                self.view?.updateSearchArtistLabel(artistName: artistName)
            }
            if let id = self.artistArray?[index].id {
                let albums = model.searchAlbums(id: id)
                self.albumArray = albums
                self.view?.searchResultAlbumData(albums: albums)
            }
        }
    }
}
