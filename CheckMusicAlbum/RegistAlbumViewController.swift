//
//  RegistAlbumViewController.swift
//  CheckMusicAlbum
//
//  Created by 田中勇輝 on 2022/09/24.
//

import UIKit
import RealmSwift
import SVProgressHUD

class RegistAlbumViewController: UIViewController {

    // MARK: - IBOutlet
    @IBOutlet weak private var titleField: UITextField! {
        didSet {
            self.titleField.layer.borderWidth = 1
            self.titleField.layer.cornerRadius = 5
            self.titleField.layer.borderColor = CGColor(red: 126/255, green: 209/255, blue: 255/255, alpha: 1)
        }
    }
    @IBOutlet weak var chooseDatePicker: UIDatePicker!
    @IBOutlet weak private var artistField: UITextField! {
        didSet {
            self.artistField.layer.borderWidth = 1
            self.artistField.layer.cornerRadius = 5
            self.artistField.layer.borderColor = CGColor(red: 126/255, green: 209/255, blue: 255/255, alpha: 1)
        }
    }
    @IBOutlet weak private var jacketImage: UIImageView! {
        didSet {
            self.jacketImage.layer.cornerRadius = 10
        }
    }
    @IBOutlet weak private var addJacketButton: UIButton! {
        didSet {
            self.addJacketButton.layer.cornerRadius = 25
        }
    }
    @IBOutlet weak private var noteTextView: UITextView! {
        didSet {
            self.noteTextView.layer.borderWidth = 1
            self.noteTextView.layer.cornerRadius = 5
            self.noteTextView.layer.borderColor = CGColor(red: 126/255, green: 209/255, blue: 255/255, alpha: 1)
        }
    }
    @IBOutlet weak private var registButton: UIButton! {
        didSet {
            self.registButton.layer.cornerRadius = 5
            if self.updateFlg {
                self.registButton.setTitle("更新", for: .normal)
                self.registButton.isEnabled = true
            } else {
                self.registButton.isEnabled = false
                self.registButton.setTitleColor(UIColor.white, for: .normal)
                self.registButton.backgroundColor = UIColor.lightGray
            }
        }
    }
    @IBOutlet weak private var deleteButton: UIButton! {
        didSet {
            self.deleteButton.layer.cornerRadius = 5
            if !self.updateFlg {
                self.deleteButton.isHidden = true
            }
        }
    }
    
    
    // MARK: - Private Variables
    var realm: Realm? // 定義
//    var album: Album!
    var artistArray: Results<Artist>?
    // ドキュメントディレクトリの「ファイルURL」（URL型）定義
    var documentDirectoryFileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    // ドキュメントディレクトリの「パス」（String型）定義
    let filePath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    // realmに登録するpng名
    var fileName = ""
    // 更新前内容取得
    var album: Album!
    // 更新か登録か判断
    var updateFlg = false
    // ID設定するためのアルバム数取得
    var albumCnt = 0
    // 画像保存フラグ
    var saveImageFlg = false
    // 画像のファイルパス
    var imageFilePath = ""
    // アーティストのアルバム件数
    var cntArtistAlbum = 0
    // 更新前アーティスト名取得
    var beforeArtistId = ""
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.titleField.addTarget(self, action: #selector(checkTextField), for: .editingChanged)
        self.artistField.addTarget(self, action: #selector(checkTextField), for: .editingChanged)
        
        if #available(iOS 15.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            // NavigationBarの背景色の設定
            appearance.backgroundColor = UIColor(red: 126/255, green: 209/255, blue: 255/255, alpha: 1)
            appearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
            self.navigationController?.navigationBar.standardAppearance = appearance
            self.navigationController?.navigationBar.scrollEdgeAppearance = appearance
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.realm = try? Realm() // インスタンス化
        
        if self.updateFlg {
            self.titleField.text = self.album.title
            if let artistArray = self.artistArray {
                for artist in artistArray {
                    if artist.id == album.artistId {
                        self.artistField.text = artist.name
                        self.beforeArtistId = album.artistId
                    }
                }
            }
            self.chooseDatePicker.date = self.album.releaseDay
            //URL型にキャスト
            if album.imageUrl != "" {
                guard let fileURL: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(self.album.imageUrl) else { return }
                //パス型に変換
                self.imageFilePath = fileURL.path
                self.jacketImage.image = UIImage(contentsOfFile: self.imageFilePath)
                self.jacketImage.backgroundColor = UIColor(named: "BackgroundGray")
                self.saveImageFlg = true
            }
            self.noteTextView.text = self.album.note
            
            // 記入アーティストのアルバム件数
            self.cntArtistAlbum = self.realm?.objects(Album.self).filter("artistId == %@", self.album.artistId).count ?? 0
        }
    }
    
    // MARK: - IBAction
    @IBAction func addJacketButtonTapped(_ sender: UIButton) {
        // UIAlertControllerの生成
                let alert = UIAlertController(title: "カメラ/フォトライブラリの選択", message: "カメラかフォトライブラリどちらを使用するか選択してください。", preferredStyle: .actionSheet)
                
                // カメラアクション
                let cameraAction = UIAlertAction(title: "カメラ", style: .default) { action in
                    // カメラを指定してピッカーを開く
                    if UIImagePickerController.isSourceTypeAvailable(.camera) { // 利用可能かどうかを確かめるメソッド
                        let pickerController = UIImagePickerController() // インスタンス生成
                        pickerController.delegate = self
                        pickerController.sourceType = .camera // 移動先をカメラに指定
                        self.present(pickerController, animated: true, completion: nil) // 画面遷移
                    }
                }
                // ライブラリアクション
                let libraryAction = UIAlertAction(title: "フォトライブラリ", style: .default) { action in
                    // ライブラリ（カメラロール）を指定してピッカーを開く
                    if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) { // 利用可能かどうかを確かめるメソッド
                        let pickerController = UIImagePickerController() // インスタンス生成
                        pickerController.delegate = self
                        pickerController.sourceType = .photoLibrary // 移動先をフォトライブラリに指定
                        self.present(pickerController, animated: true, completion: nil) // 画面遷移
                    }
                }
                let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel) { action in
                    print("tapped cancel")
                }
                
                // アクションの追加
                alert.addAction(cameraAction)
                alert.addAction(libraryAction)
                alert.addAction(cancelAction)

                // UIAlertControllerの表示
                present(alert, animated: true, completion: nil)
    }
    
    @IBAction func registButtonTapped(_ sender: Any) {
        var addArtistFlg = false
        let artist = Artist()
        do {
            try realm?.write {
                let album = Album()
                if self.updateFlg {
                    album.id = self.album.id
                } else {
                    album.id = NSUUID().uuidString
                }
                // タイトルとアーティストに関しては、入力チェックを行っているため、強制アンラップ
                album.title = self.titleField.text!
                if let existArtist = realm?.objects(Artist.self).filter("name == %@", self.artistField.text!),
                   existArtist.count != 0{
                    album.artistId = existArtist.first?.id ?? ""
                } else {
                    album.artistId = NSUUID().uuidString
                    artist.id = album.artistId
                    addArtistFlg = true
                }
                album.releaseDay = self.chooseDatePicker.date
                // 画像保存
                if self.saveImageFlg {
                    self.saveImage()
                    album.imageUrl = self.fileName
                }
                // 備考
                album.note = self.noteTextView.text
                
                self.realm?.add(album, update: .modified)
                print("IN")
            }
        } catch {
            print("errorが発生しました。")
            SVProgressHUD.showError(withStatus: "登録の際にエラーが発生しました。")
        }
        
        if addArtistFlg {
            do {
                try realm?.write {
                    artist.name = self.artistField.text!
                    self.realm?.add(artist, update: .modified)
                }
            } catch {
                print("errorが発生しました。")
                SVProgressHUD.showError(withStatus: "登録の際にエラーが発生しました。")
            }
        }
        
        if self.updateFlg {
            if realm?.objects(Album.self).filter("artistId == %@", self.beforeArtistId).count == 0 {
                do{
                    try self.realm?.write{
                        self.realm?.delete(((self.realm?.objects(Artist.self).filter("id == %@", self.beforeArtistId))!))
                    }
                }catch {
                    print("errorが発生しました。")
                    SVProgressHUD.showError(withStatus: "削除の際にエラーが発生しました。")
                }
                print("IN2")
            }
        }
        
        // トップ画面(一覧画面)に戻る
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    @IBAction func deleteButtonTapped(_ sender: UIButton) {
        // ① UIAlertControllerクラスのインスタンスを生成
        // タイトル, メッセージ, Alertのスタイルを指定する
        // 第3引数のpreferredStyleでアラートの表示スタイルを指定する
        let alert: UIAlertController = UIAlertController(title: "アルバム削除", message: "本当に削除しますか？", preferredStyle:  UIAlertController.Style.alert)
        // ② Actionの設定
        // Action初期化時にタイトル, スタイル, 押された時に実行されるハンドラを指定する
        // 第3引数のUIAlertActionStyleでボタンのスタイルを指定する
        // OKボタン
        //ここから追加
        let okAction = UIAlertAction(title: "削除", style: .destructive) { (action) in
            // アーティスト削除
            if self.cntArtistAlbum == 1 {
                do{
                    try self.realm?.write{
                        self.realm?.delete(((self.realm?.objects(Artist.self).filter("id == %@", self.album.artistId))!))
                        // トップ画面(一覧画面)に戻る
                        self.navigationController?.popToRootViewController(animated: true)
                    }
                }catch {
                    print("errorが発生しました。")
                    SVProgressHUD.showError(withStatus: "削除の際にエラーが発生しました。")
                }
            }
            
            //ファイルの削除
            if self.imageFilePath != ""{
                try? FileManager.default.removeItem(atPath: self.imageFilePath)
            }
            do{
                try self.realm?.write{
                    self.realm?.delete(self.album)
                }
            }catch {
                print("errorが発生しました。")
                SVProgressHUD.showError(withStatus: "削除の際にエラーが発生しました。")
            }
        }
        let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel) { (action) in
            self.dismiss(animated: true, completion: nil)
        }
        // ③ UIAlertControllerにActionを追加
        alert.addAction(cancelAction)
        alert.addAction(okAction)
        // ④ Alertを表示
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Private Methods
    /// TextFieldの入力チェックを行うメソッド
    @objc func checkTextField() {
        // アカウント作成の入力チェック
        if let title = self.titleField.text, !title.isEmpty,
           let artist = self.artistField.text, !artist.isEmpty {
            self.registButton.isEnabled = true
            self.registButton.setTitleColor(UIColor.white, for: .normal)
            self.registButton.backgroundColor = UIColor(red: 126/255, green: 209/255, blue: 255/255, alpha: 1)
        } else {
            self.registButton.isEnabled = false
            self.registButton.setTitleColor(UIColor.white, for: .normal)
            self.registButton.backgroundColor = UIColor.lightGray
        }
    }
    
    //画像を保存する関数の部分
    private func saveImage() {
        createLocalDataFile()
        //pngで保存する場合
        let pngImageData = self.jacketImage.image?.pngData()
        do {
            try pngImageData!.write(to: self.documentDirectoryFileURL)
            print("OK")
        } catch {
            //エラー処理
            print("エラー")
        }
    }
    
    //保存するためのパスを作成する
    private func createLocalDataFile() {
        // 作成するテキストファイルの名前
        self.fileName = "\(NSUUID().uuidString).png"

        // DocumentディレクトリのfileURLを取得
        if self.documentDirectoryFileURL != nil {
            // ディレクトリのパスにファイル名をつなげてファイルのフルパスを作る
            let path = self.documentDirectoryFileURL.appendingPathComponent(self.fileName)
            self.documentDirectoryFileURL = path
        }
    }
}

// MARK: - UIImagePickerControllerDelegate, UINavigationControllerDelegate
extension RegistAlbumViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    /// 写真を撮影/選択したときに呼ばれるメソッド
    ///
    /// - Parameters:
    ///   - picker: UIImagePickerController
    ///   - info: [UIImagePickerController.InfoKey : Any]
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // UIImagePickerController画面を閉じる
        picker.dismiss(animated: true, completion: nil)
        // 画像加工処理(info[.originalImage]に撮影/選択した画像が入っている)
        // 省略せず書くと、info[UIImagePickerController.InfoKey.originalImage]に入っている
        if info[.originalImage] != nil {
            // 撮影/選択された画像を取得する
            let image = info[.originalImage] as! UIImage
            self.jacketImage.image = image
            self.jacketImage.backgroundColor = UIColor(named: "BackgroundGray")
            self.saveImageFlg = true
        }
    }
}
