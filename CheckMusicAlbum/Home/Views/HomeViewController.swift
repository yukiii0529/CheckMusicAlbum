//
//  HomeViewController.swift
//  CheckMusicAlbum
//
//  Created by 田中勇輝 on 2023/03/05.
//

import UIKit
import RealmSwift

class HomeViewController: UIViewController {

    // MARK: - IBOutlet
    @IBOutlet weak var chooseArtistButton: UIButton!
    @IBOutlet weak var chooseArtistStackView: UIStackView! {
        didSet {
            self.chooseArtistStackView.isHidden = true
        }
    }
    @IBOutlet private weak var chooseArtist: UITextField! {
        didSet {
            self.chooseArtist.layer.borderWidth = 1
            self.chooseArtist.layer.cornerRadius = 5
            self.chooseArtist.layer.borderColor = CGColor(red: 126/255, green: 209/255, blue: 255/255, alpha: 1)
        }
    }
    @IBOutlet private weak var resetButton: UIButton! {
        didSet {
            self.resetButton.layer.cornerRadius = 5
        }
    }
    @IBOutlet weak var displayAlbumNum: UILabel!
    @IBOutlet private weak var albumListcollectionView: UICollectionView! {
        didSet {
            self.albumListcollectionView.delegate = self
            self.albumListcollectionView.dataSource = self
            // カスタムセルの登録
            let nib = UINib(nibName:"AlbumListCollectionViewCell", bundle: nil)
            self.albumListcollectionView.register(nib, forCellWithReuseIdentifier: "AlbumListCell")
        }
    }
    @IBOutlet weak var notAlbumText: UILabel!
    
    
    // MARK: - Private Variables
    var albumArray: Results<Album>?
    var artistArray: Results<Artist>?
    
    var pickerView: UIPickerView = UIPickerView()
    private var presenter: HomeViewPresenterInput!
    
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.presenter = HomeViewPresenter(view: self, model: HomeModel())
        self.presenter.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.presenter.viewDidLoad()
    }
    
    // MARK: - IBAction
    
    /// アルバム追加ボタン押下時
    /// - Parameter sender: UIBarButtonItem
    @IBAction func addButtonTapped(_ sender: UIBarButtonItem) {
        self.presenter.addButtonTapped()
    }
    
    
    /// 「アーティストを選択」を押下時
    /// - Parameter sender: UIButton
    @IBAction func chooseArtistButtonTapped(_ sender: UIButton) {
        self.presenter.chooseArtistButtonTapped()
    }
    
    
    /// リセットボタン押下時
    /// - Parameter sender: UIButton
    @IBAction func resetButtonTapped(_ sender: UIButton) {
        self.presenter.resetButtonTapped()
    }
    
    // MARK: - Private Methods
    // 絞り込み決定押下
    @objc func done() {
        self.presenter.narrowingDown(index: self.pickerView.selectedRow(inComponent: 0))
    }
    
    // キャンセルボタン
    @objc func cancel(){
        self.chooseArtist.endEditing(true)
    }
}

// MARK: - UICollectionViewDelegate,UICollectionViewDataSource
extension HomeViewController: UICollectionViewDelegate,UICollectionViewDataSource {
    
    /// セクション数
    /// - Parameters:
    ///   - collectionView: UICollectionView
    ///   - section: Int
    /// - Returns: セクション数
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.presenter.numberOfAlbums
    }
    
    
    /// セルの中身
    /// - Parameters:
    ///   - collectionView: UICollectionView
    ///   - indexPath: セル
    /// - Returns: セル
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        //CustumCellを宣言する
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AlbumListCell", for: indexPath) as! AlbumListCollectionViewCell
        cell.layer.borderWidth = 1
        cell.layer.borderColor = CGColor(red: 126/255, green: 209/255, blue: 255/255, alpha: 1)
        cell.layer.cornerRadius = 15
        // Cellに値を設定する
        if (self.albumArray?[indexPath.row]) != nil {
            self.presenter.configureCell(cell, at: indexPath)
        }
        return cell
    }
    
    
    /// セル選択時
    /// - Parameters:
    ///   - collectionView: UICollectionView
    ///   - indexPath: 選択したセル
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.presenter?.didSelectAlbum(at: indexPath.row)
    }
}

// MARK: - UIPickerViewDelegate, UIPickerViewDataSource
extension HomeViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    // 絞り込み関連
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    /// 選択数
    /// - Parameters:
    ///   - pickerView: UIPickerView
    ///   - component: Int
    /// - Returns: 選択数
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.artistArray?.count ?? 0
    }
    
    
    /// ピッカーの中身
    /// - Parameters:
    ///   - pickerView: UIPickerView
    ///   - row: Int
    ///   - component: Int
    /// - Returns: 表示タイトル
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return self.artistArray?[row].name
    }
}

// MARK: - HomeViewPresenterOutput
extension HomeViewController: HomeViewPresenterOutput {
    
    // UICollectionViewのレイアウト設定
    func configureCollectionViewLayout() {
        // セルの大きさを設定
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 165, height: 245)
        let inset = (self.view.frame.width - 355) / 2
        layout.sectionInset = UIEdgeInsets(top: 0, left: inset, bottom: 0, right: inset)
        layout.minimumLineSpacing = 15
        self.albumListcollectionView.collectionViewLayout = layout
    }
    
    // UIPickerViewの設定
    func configurePicker() {
        // ピッカー設定
        self.pickerView.delegate = self
        self.pickerView.dataSource = self
        // 決定バーの生成
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 42))
        let spacelItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        let doneItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.done))
        let cancelItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(self.cancel))
        toolbar.setItems([cancelItem, spacelItem, doneItem], animated: true)
        // インプットビュー設定
        self.chooseArtist.inputView = self.pickerView
        self.chooseArtist.inputAccessoryView = toolbar
    }
    
    // UINavigationBarのレイアウト設定
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
    
    // アルバムとアーティスト取得
    func getContents(albums: Results<Album>, artists: Results<Artist>) {
        self.albumArray = albums
        self.artistArray = artists
        
        if let albumNum = self.albumArray?.count , albumNum != 0 {
            self.displayAlbumNum.text = "検索結果：\(albumNum)件"
            self.notAlbumText.isHidden = true
            self.albumListcollectionView.isHidden = false
            self.albumListcollectionView.reloadData()
        } else {
            self.displayAlbumNum.text = "検索結果：0件"
            self.notAlbumText.isHidden = false
            self.albumListcollectionView.isHidden = true
        }
        self.chooseArtistStackView.isHidden = true
    }
    
    // 詳細(編集)画面へ遷移
    func showAlbumDetails(album: Album) {
        let storyboard = UIStoryboard(name: "RegistAlbum", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "RegistAlbum") as? RegistAlbumViewController {
            viewController.artistArray = self.artistArray
            viewController.album = album
            viewController.updateFlg = true
            navigationController?.pushViewController(viewController, animated: true)
        }
    }
    
    // アラート設定
    // 「アーティストを絞る」ボタン押下時にアルバムが登録されていない場合、当アラート表示
    func showNoArtistsAvailableAlert() {
        let alert = UIAlertController(title: "アルバムを追加してください", message: "アルバムが１枚も登録されていないため、選択するアーティストが存在しません。", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { [weak self] (action) in
            self?.dismiss(animated: true, completion: nil)
        }
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }

    // 「アーティストを絞る」押下時に検索欄の表示、非表示の切り替えを行う
    func toggleChooseArtistStackView() {
        self.chooseArtistStackView.isHidden = !chooseArtistStackView.isHidden
    }
    
    // 検索欄でのUIPickerView選択時にLabelにアーティスト固定表示
    func updateSearchArtistLabel(artistName: String) {
        self.chooseArtist.text = artistName
    }
    
    // 検索結果を用いて再描画
    func searchResultAlbumData(albums: Results<Album>) {
        self.chooseArtist.endEditing(true)
        self.albumArray = albums
        self.displayAlbumNum.text = "検索結果：\(self.albumArray?.count ?? 0)件"
        self.albumListcollectionView.reloadData()
    }
    
    // アルバル登録画面へ遷移
    func navigateToRegistView() {
        let storyboard = UIStoryboard(name: "RegistAlbum",bundle: nil)
        let viewController =  storyboard.instantiateViewController(withIdentifier: "RegistAlbum") as! RegistAlbumViewController
        viewController.artistArray = self.artistArray
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    // 検索欄にてリセットボタン押下時にアルバム全表示させる
    func resetAlbumData(albums: Results<Album>) {
        self.chooseArtist.text = ""
        self.albumArray = albums
        self.displayAlbumNum.text = "検索結果：\(self.albumArray?.count ?? 0)件"
        self.albumListcollectionView.reloadData()
    }
}
