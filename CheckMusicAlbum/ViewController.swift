//
//  ViewController.swift
//  CheckMusicAlbum
//
//  Created by 田中勇輝 on 2022/09/23.
//

import UIKit
import RealmSwift

class ViewController: UIViewController {

    // MARK: - IBOutlet
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
    var realm: Realm? // 定義
    var album: Album!
    var albumArray: Results<Album>?
    var artist: Artist!
    var artistArray: Results<Artist>?
    
    var pickerView: UIPickerView = UIPickerView()
    
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // セルの大きさを設定
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 165, height: 245)
        print(self.view.frame.width)
        let inset = (self.view.frame.width - 355) / 2
        layout.sectionInset = UIEdgeInsets(top: 0, left: inset, bottom: 0, right: inset)
        layout.minimumLineSpacing = 15
        self.albumListcollectionView.collectionViewLayout = layout
        
        // ピッカー設定
        self.pickerView.delegate = self
        self.pickerView.dataSource = self
        // 決定バーの生成
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 35))
        let spacelItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        let doneItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.done))
        toolbar.setItems([spacelItem, doneItem], animated: true)
        // インプットビュー設定
        self.chooseArtist.inputView = self.pickerView
        self.chooseArtist.inputAccessoryView = toolbar
        
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
        self.artistArray = self.realm?.objects(Artist.self)
        self.albumArray = self.realm?.objects(Album.self)
        if let albumNum = self.albumArray?.count , albumNum != 0 {
            self.displayAlbumNum.text = "検索結果：\(albumNum)件"
            self.notAlbumText.isHidden = true
            self.albumListcollectionView.isHidden = false
            self.albumListcollectionView.reloadData()
        } else {
            self.notAlbumText.isHidden = false
            self.albumListcollectionView.isHidden = true
        }
    }
    
    // MARK: - IBAction
    @IBAction func addButtonTapped(_ sender: UIBarButtonItem) {
        let storyboard = UIStoryboard(name: "RegistAlbum",bundle: nil)
        let viewController =  storyboard.instantiateViewController(withIdentifier: "RegistAlbum") as! RegistAlbumViewController
        viewController.artistArray = self.artistArray
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    // MARK: - Private Methods
    // 絞り込み決定押下
    @objc func done() {
        self.chooseArtist.endEditing(true)
        if self.artistArray?.count != 0 {
            if let artistName = self.artistArray?[self.pickerView.selectedRow(inComponent: 0)].name {
                self.chooseArtist.text = artistName
            }
            if let id = self.artistArray?[self.pickerView.selectedRow(inComponent: 0)].id {
                self.albumArray = self.realm?.objects(Album.self).filter("artistId = \(id)")
            }
            self.albumListcollectionView.reloadData()
        }
    }
}

extension ViewController: UICollectionViewDelegate,UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.albumArray?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        //CustumCellを宣言する
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AlbumListCell", for: indexPath) as! AlbumListCollectionViewCell
        cell.layer.borderWidth = 1
        cell.layer.borderColor = CGColor(red: 126/255, green: 209/255, blue: 255/255, alpha: 1)
        cell.layer.cornerRadius = 15
        // Cellに値を設定する
        if let album = self.albumArray?[indexPath.row] { // taskをアンラップする
            cell.titleLabel.text = album.title
            if let artistArray = self.artistArray {
                for artist in artistArray {
                    if artist.id == album.artistId {
                        cell.artistLabel.text = artist.name
                    }
                }
            }
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy/MM/dd"
            let dateString:String = formatter.string(from: album.releaseDay)
            cell.releaseDayLabel.text = dateString
            
            //URL型にキャスト
            guard let fileURL: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(album.imageUrl) else { return cell }
            //パス型に変換
            let filePath = fileURL.path
            cell.jacketImage.image = UIImage(contentsOfFile: filePath)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: "RegistAlbum",bundle: nil)
        let viewController =  storyboard.instantiateViewController(withIdentifier: "RegistAlbum") as! RegistAlbumViewController
        viewController.artistArray = self.artistArray
        viewController.album = self.albumArray?[indexPath.row]
        viewController.updateFlg = true
        viewController.albumCnt = self.albumArray?.count ?? 0
        navigationController?.pushViewController(viewController, animated: true)
    }
}

// MARK: - UIPickerViewDelegate, UIPickerViewDataSource
extension ViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    // 絞り込み関連
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    // TODO: docコメント
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.artistArray?.count ?? 0
    }
    // TODO: docコメント
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return self.artistArray?[row].name
    }
}

