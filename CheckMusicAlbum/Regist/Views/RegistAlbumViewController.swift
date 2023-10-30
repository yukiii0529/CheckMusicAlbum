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
            self.titleField.delegate = self
            self.titleField.layer.borderWidth = 1
            self.titleField.layer.cornerRadius = 5
            self.titleField.layer.borderColor = CGColor(red: 126/255, green: 209/255, blue: 255/255, alpha: 1)
        }
    }
    @IBOutlet weak var chooseDatePicker: UIDatePicker!
    @IBOutlet weak private var artistField: UITextField! {
        didSet {
            self.artistField.delegate = self
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
    private var presenter: RegistAlbumViewPresenterInput!
//    var album: Album!
    var artistArray: Results<Artist>?
    // realmに登録するpng名
    var fileName = ""
    // 更新前内容取得
    var album: Album!
    // 更新か登録か判断
    var updateFlg = false
    // 画像保存フラグ
    var saveImageFlg = false
    // 画像のファイルパス
    var imageFilePath = ""
    // 更新前アーティスト名取得
    var beforeArtistId = ""
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.presenter = RegistAlbumViewPresenter(view: self, model: RegistAlbumModel())
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.presenter.viewWillAppear(updateFlg: self.updateFlg, album: self.album)
    }
    
    // MARK: - IBAction
    /// ジャケット写真追加ボタン押下時
    /// - Parameter sender: UIButton
    @IBAction func addJacketButtonTapped(_ sender: UIButton) {
        self.presenter.addJacketButtonTapped()
    }
    
    /// 登録ボタン押下時
    /// - Parameter sender: UIButton
    @IBAction func registButtonTapped(_ sender: UIButton) {
        // タイトルとアーティストに関しては、入力チェックを行っているため、強制アンラップ
        let pngImageData = self.jacketImage.image?.pngData()
        self.presenter.registButtonTapped(alreadyRegistAlbum: self.album, title: self.titleField.text!, artistName: self.artistField.text!, date: self.chooseDatePicker.date, saveImageFlg: self.saveImageFlg, image: pngImageData, note: self.noteTextView.text, updateFlg: self.updateFlg)
    }
    
    /// 削除ボタン押下時（更新時のみ）
    /// - Parameter sender: UIButton
    @IBAction func deleteButtonTapped(_ sender: UIButton) {
        let alert: UIAlertController = UIAlertController(title: "アルバム削除", message: "本当に削除しますか？", preferredStyle:  UIAlertController.Style.alert)
        let okAction = UIAlertAction(title: "削除", style: .destructive) { (action) in
            self.presenter.deleteButtonTapped(album: self.album, imagePath: self.imageFilePath)
        }
        let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel) { (action) in
            self.dismiss(animated: true, completion: nil)
        }
        alert.addAction(cancelAction)
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Private Methods
    /// TextFieldの入力チェックを行うメソッド
    @objc func checkTextField() {
        self.presenter.textFieldDidChange(title: titleField.text, artist: artistField.text)
    }
    
    // キーボード閉じる
    @objc func commitButtonTapped() {
        self.view.endEditing(true)
    }
    
    // キーボード表示
    @objc func keyboardWillShow(notification: NSNotification) {
        if !self.noteTextView.isFirstResponder {
            return
        }
    
        if self.view.frame.origin.y == 0 {
            if let keyboardRect = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
                self.view.frame.origin.y -= keyboardRect.height * 0.62
            }
        }
    }
    
    // キーボード非表示
    @objc func keyboardWillHide(notification: NSNotification) {
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
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
        if let image = info[.originalImage] as? UIImage {
            self.presenter.imageSelected(image)
        }
    }
}

// MARK: - UITextViewDelegate, UITextFieldDelegate
extension RegistAlbumViewController: UITextViewDelegate, UITextFieldDelegate {
    
    ///  Doneボタン押下時
    /// - Parameter textField: UITextField
    /// - Returns: Bool
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - HomeViewPresenterOutput
extension RegistAlbumViewController: RegistAlbumViewPresenterOutput {
    // UITextFieldにトリガー設置
    func configureAddTarget() {
        self.titleField.addTarget(self, action: #selector(checkTextField), for: .editingChanged)
        self.artistField.addTarget(self, action: #selector(checkTextField), for: .editingChanged)
    }
    
    // ツールバーの設定
    func configureToolBar() {
        // TextViewに閉じるボタン追加
        // ツールバー生成
        let toolBar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 320, height: 40))
        // スタイルを設定
        toolBar.barStyle = UIBarStyle.default
        // 画面幅に合わせてサイズを変更
        toolBar.sizeToFit()
        // 閉じるボタンを右に配置するためのスペース?
        let spacer = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: self, action: nil)
        // 閉じるボタン
        let commitButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.done, target: self, action: #selector(self.commitButtonTapped))
        // スペース、閉じるボタンを右側に配置
        toolBar.items = [spacer, commitButton]
        // textViewのキーボードにツールバーを設定
        self.noteTextView.inputAccessoryView = toolBar
        
        let tapGR: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.commitButtonTapped))
        tapGR.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tapGR)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    // UINavigationBarの設定
    func configureNavigationBar() {
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
    
    // 更新の場合、既存登録されている内容を表示
    func setUpAlreadyRegistAlbum(album: Album) {
        self.titleField.text = album.title
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
            guard let fileURL: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(album.imageUrl) else { return }
            //パス型に変換
            self.imageFilePath = fileURL.path
            self.jacketImage.image = UIImage(contentsOfFile: self.imageFilePath)
            self.jacketImage.backgroundColor = UIColor(named: "BackgroundGray")
            self.saveImageFlg = true
        }
        self.noteTextView.text = album.note
    }
    
    // 画像設定の際、カメラかライブラリか選択するアラート設定
    func showImageSourceOptions() {
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
    
    // アルバム登録成功アラート
    func addAlbumSuccessModal() {
        var alert: UIAlertController = UIAlertController(title: "登録成功", message: "アルバムを登録いたしました。", preferredStyle:  UIAlertController.Style.alert)
        if self.updateFlg {
            alert = UIAlertController(title: "更新成功", message: "アルバムの内容を更新いたしました。", preferredStyle:  UIAlertController.Style.alert)
        }
        let okAction = UIAlertAction(title: "OK", style: .default) { (action) in
            self.navigationController?.popToRootViewController(animated: true)
        }
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
        
        // トップ画面(一覧画面)に戻る
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    // 削除後一覧画面へ戻る
    func showDeletionSuccessMessage() {
        // トップ画面(一覧画面)に戻る
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    // 削除失敗時の表示
    func showDeletionFailureMessage() {
        print("errorが発生しました。")
        SVProgressHUD.showError(withStatus: "削除の際にエラーが発生しました。")
    }
    
    // 画像の背景設定
    func displayImage(_ image: UIImage) {
        jacketImage.image = image
        jacketImage.backgroundColor = UIColor(named: "BackgroundGray")
        self.saveImageFlg = true
    }
    
    // 登録ボタンの活性、非活性
    func enableRegistrationButton(_ enabled: Bool) {
        registButton.isEnabled = enabled
        registButton.setTitleColor(enabled ? UIColor.white : UIColor.lightGray, for: .normal)
        registButton.backgroundColor = enabled ? UIColor(red: 126/255, green: 209/255, blue: 255/255, alpha: 1) : UIColor.lightGray
    }
}
