//
//  CSPhotoGalleryViewController.swift
//  CSPhotoGallery
//
//  Created by Youk Chansim on 2016. 12. 7..
//  Copyright © 2016년 Youk Chansim. All rights reserved.
//

import UIKit
import Photos

typealias CSObservation = UInt8


public class CSPhotoGalleryViewController: UIViewController {
    public static var instance: CSPhotoGalleryViewController {
        let podBundle = Bundle(for: CSPhotoGalleryViewController.self)
        let bundleURL = podBundle.url(forResource: "CSPhotoGallery", withExtension: "bundle")
        let bundle = bundleURL == nil ? podBundle : Bundle(url: bundleURL!)
        let storyBoard = UIStoryboard.init(name: "CSPhotoGallery", bundle: bundle)
        return storyBoard.instantiateViewController(withIdentifier: identifier) as! CSPhotoGalleryViewController
    }
    
    @IBOutlet fileprivate weak var collectionName: UILabel! {
        didSet {
            let gesture = UITapGestureRecognizer(target: self, action: #selector(collectionNameTap(_:)))
            collectionName.addGestureRecognizer(gesture)
            collectionName.isUserInteractionEnabled = true
        }
    }
    @IBOutlet fileprivate weak var collectionNameArrow: UILabel!
    @IBOutlet fileprivate weak var checkCount: UILabel! {
        didSet {
            checkCount.isHidden = CSPhotoDesignManager.instance.isCountLabelHidden
        }
    }
    
    @IBOutlet public weak var okBtn: UIButton! {
        didSet {
            reloadOKButton()
        }
    }
    public func reloadOKButton(){
        okBtn.setImage(CSPhotoDesignManager.instance.photoGalleryOKButtonImage, for: .normal)
        okBtn.setTitle(CSPhotoDesignManager.instance.photoGalleryOKButtonTitle, for: .normal)
        okBtn.isHidden = CSPhotoDesignManager.instance.isOKButtonHidden
    }
    
    @IBOutlet fileprivate weak var backBtn: UIButton! {
        didSet {
            if let image = CSPhotoDesignManager.instance.photoGalleryBackButtonImage {
                backBtn.setImage(image, for: .normal)
            }
        }
    }
    
    @IBOutlet fileprivate weak var collectionView: UICollectionView!
    
    @IBOutlet weak var progressView: UIProgressView!
    public var delegate: CSPhotoGalleryDelegate?
    public var mediaType: CSPhotoImageType = .image
    public var CHECK_MAX_COUNT = 20
    public var horizontalCount: CGFloat = 3

    fileprivate var thumbnailSize: CGSize = CGSize.zero
    fileprivate var CSObservationContext = CSObservation()
    fileprivate var CSCollectionObservationContext = CSObservation()
    fileprivate var transitionDelegate: CSPhotoViewerTransition = CSPhotoViewerTransition()
    
    var checkImage: UIImage?
    var unCheckImage: UIImage?
    
    
    override  public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
            super.viewWillTransition(to: size, with: coordinator)
            guard let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else {
                return
            }
            flowLayout.invalidateLayout()
        }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        definesPresentationContext = true
        // Do any additional setup after loading the view.
        setViewController()
        setThumbnailSize()
        addObserver()
        checkPhotoLibraryPermission()
        scrollToBottom()
    }
    
    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &CSObservationContext {
            let count = PhotoManager.sharedInstance.selectedItemCount
            setCheckCountLabel(count: count)
        } else if context == &CSCollectionObservationContext {
            setTitle()
            reloadCollectionView()
            DispatchQueue.main.async {
                self.scrollToBottom()
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    deinit {
        CSPhotoDesignManager.instance.photoGalleryDeinit?(self)
        removeObserver()
    }
    fileprivate var observersAdded = false
}

//  MARK:- Gesture
extension CSPhotoGalleryViewController {
    @objc func collectionNameTap(_ sender: UITapGestureRecognizer) {
        let a = CSPhotoGalleryAssetCollectionViewController.instance
        present(a, animated: true, completion: nil)
        collectionNameArrow.text =  "▼"
    }
    func reloadCollectionView() {
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
    
    func updateCollectionViewCellUI(indexPath: IndexPath) {
        DispatchQueue.main.async {
            let cell = self.collectionView.cellForItem(at: indexPath) as? CSPhotoGalleryCollectionViewCell
            cell?.setButtonImage()
        }
    }
    
    func collectionViewCellFrame(at indexPath: IndexPath) -> CGRect {
        let item = collectionView.layoutAttributesForItem(at: indexPath)
        
        var frame = item!.frame
        frame.origin.y = frame.origin.y - collectionView.contentOffset.y + collectionView.frame.origin.y
        
        return frame
    }
    
    func scrollRectToVisible(indexPath: IndexPath) {
        let rect = collectionView.layoutAttributesForItem(at: indexPath)?.frame ?? CGRect.zero
        let currentOffsetY = collectionView.contentOffset.y
        
        //  상단
        if currentOffsetY > rect.origin.y {
            collectionView.contentOffset.y = rect.origin.y
        //  하단
        } else if currentOffsetY + collectionView.frame.height < rect.origin.y + rect.height {
            collectionView.contentOffset.y = rect.origin.y + rect.height - collectionView.frame.height
        }
    }
    
    func durationToText(time: TimeInterval) -> String {
        let time = Date(timeIntervalSince1970: time)
        
        let dateFormater = DateFormatter()
        dateFormater.dateFormat = "mm:ss"
        
        return dateFormater.string(from: time)
    }
}

//  MARK:- Actions
private extension CSPhotoGalleryViewController {
    @IBAction func backBtnAction(_ sender: Any) {
        if let custom = CSPhotoDesignManager.instance.photoGalleryDismissCustomAction {
            custom()
            return
        }
        dismiss()
    }
    
    @IBAction func checkBtnAction(_ sender: Any) {
        let designManager = CSPhotoDesignManager.instance
        if let action = designManager.photoGalleryOKButtonCustomAction {
            action(self)
            return
        }
        
        delegate?.getAssets(assets: PhotoManager.sharedInstance.assets)
        dismiss()
    }
}

//  MARK:- Extension
fileprivate extension CSPhotoGalleryViewController {
    func setViewController() {
        setData()
        setView()
    }
    
    func setData() {
        PhotoManager.sharedInstance.CHECK_MAX_COUNT = CHECK_MAX_COUNT
        PhotoManager.sharedInstance.mediaType = mediaType
        PhotoManager.sharedInstance.initPhotoManager()
    }
    
    func setThumbnailSize(_ newSize:CGSize?=nil) {
        let scale = UIScreen.main.scale
        if newSize != nil {
            thumbnailSize = CGSize(width: newSize!.width*scale, height: newSize!.height*scale)
        }else{
            let cellSize = (collectionView.collectionViewLayout as! UICollectionViewFlowLayout).itemSize
            let size = min(cellSize.width, cellSize.height) * scale
            thumbnailSize = CGSize(width: size, height: size)
        }
        
    }
    
    func setView() {
        
        setTitle()
        
        let podBundle = Bundle(for: CSPhotoGalleryViewController.self)
        let bundleURL = podBundle.url(forResource: "CSPhotoGallery", withExtension: "bundle")
        let bundle = bundleURL == nil ? podBundle : Bundle(url: bundleURL!)
        
        let originalCheckImage = UIImage(named: "check_select", in: bundle, compatibleWith: nil)
        let originalUnCheckImage = UIImage(named: "check_default", in: bundle, compatibleWith: nil)
        
        checkImage = CSPhotoDesignManager.instance.photoGalleryCheckImage ?? originalCheckImage
        unCheckImage = CSPhotoDesignManager.instance.photoGalleryUnCheckImage ?? originalUnCheckImage
    }
    
    func addObserver() {
        PhotoManager.sharedInstance.register(object: self)
        PhotoManager.sharedInstance.addObserver(self, forKeyPath: "selectedItemCount", options: .new, context: &CSObservationContext)
        PhotoManager.sharedInstance.addObserver(self, forKeyPath: "currentCollection", options: .new, context: &CSCollectionObservationContext)
        observersAdded = true
    }
    func removeObserver(){
        guard observersAdded == true else {
            return;
        }
        PhotoManager.sharedInstance.removeObserver(self, forKeyPath: "selectedItemCount")
        PhotoManager.sharedInstance.removeObserver(self, forKeyPath: "currentCollection")
        PhotoManager.sharedInstance.remover(object: self)
        observersAdded = false
    }
    
    func setCheckCountLabel(count: Int) {
        DispatchQueue.main.async {
            self.checkCount.text = "\(count)"
        }
    }
    
    func setTitle() {
        DispatchQueue.main.async {
            let title = PhotoManager.sharedInstance.currentCollection?.localizedTitle
            self.collectionName.text = title
        }
    }
    
    func checkPhotoLibraryPermission() {
        PHPhotoLibrary.requestAuthorization() { status in
            switch status {
            case .authorized:
                PhotoManager.sharedInstance.initPhotoManager()
            case .denied, .restricted:
                break
            case .notDetermined:
                self.checkPhotoLibraryPermission()
            }
        }
    }
}

extension CSPhotoGalleryViewController {
    func dismiss() {
        if let nvc = navigationController {
            let _ = nvc.popViewController(animated: true)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
}

//  MARK:- UICollectionView DataSource
extension CSPhotoGalleryViewController: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return PhotoManager.sharedInstance.assetsCount
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let asset = PhotoManager.sharedInstance.getCurrentCollectionAsset(at: indexPath)
        
        var cell: CSPhotoGalleryCollectionViewCell?
        
        switch asset.mediaType {
        case .image:
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CSPhotoGalleryCollectionViewCell", for: indexPath) as? CSPhotoGalleryCollectionViewCell
        case .video:
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CSPhotoGalleryVideoCollectionViewCell", for: indexPath) as? CSPhotoGalleryCollectionViewCell
            cell?.setTime(time: durationToText(time: asset.duration))
        default:
            return UICollectionViewCell()
        }
        
        cell?.indexPath = indexPath
        cell?.representedAssetIdentifier = asset.localIdentifier
        cell?.checkImage = checkImage
        cell?.unCheckImage = unCheckImage
        cell?.setButtonImage()
        
        cell?.checkBtn.isHidden = CSPhotoDesignManager.instance.isCountLabelHidden
        
        cell?.setPlaceHolderImage(image: nil)
        
        PhotoManager.sharedInstance.setThumbnailImage(at: indexPath, thumbnailSize: thumbnailSize, isCliping: true) { image in
            if cell?.representedAssetIdentifier == asset.localIdentifier {
                cell?.setImage(image: image)
            }
        }
        
        return cell!
    }
}

//  MARK:- UICollectionView Delegate
extension CSPhotoGalleryViewController: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        scrollRectToVisible(indexPath: indexPath)
        let asset = PhotoManager.sharedInstance.getCurrentCollectionAsset(at: indexPath)
        
        if asset.mediaType == .image {
            
            let progress:PHAssetImageProgressHandler = {(progress, error, pointer, info) in
                DispatchQueue.main.async {
                self.progressView.isHidden = progress >= 1.0
                    self.progressView.progress = Float(progress)
                }
            }
            PhotoManager.sharedInstance.assetToImage(asset: asset, imageSize: CGSize(width: asset.pixelWidth, height: asset.pixelHeight), isCliping: false, contentMode: .aspectFill, progressHandler: progress) { image in
                //  Present photo viewer
                let item = collectionView.layoutAttributesForItem(at: indexPath)
                let vc = CSPhotoGalleryDetailViewController.instance
                
                var frame = item!.frame
                frame.origin.y = frame.origin.y - collectionView.contentOffset.y + collectionView.frame.origin.y
                self.transitionDelegate.initialRect = frame
                self.transitionDelegate.originalImage = image
                self.transitionDelegate.originalViewController = self
                
                vc.delegate = self.delegate
                vc.currentIndexPath = indexPath
                vc.transitioningDelegate = self.transitionDelegate
                vc.modalPresentationStyle = .custom
                
                self.present(vc, animated: true, completion: nil)
            }
        } else if asset.mediaType == .video {
            PHCachingImageManager().requestAVAsset(forVideo: asset,
                                         options: nil,
                                         resultHandler: {(asset: AVAsset?,
                                            audioMix: AVAudioMix?,
                                            info: [AnyHashable: Any]?) in
                                            
                                            /* Did we get the URL to the video? */
                                            if let asset = asset as? AVURLAsset{
                                                let player = AVPlayer(url: asset.url)
                                                let playerViewController = CSVideoViewController()
                                                playerViewController.player = player
                                                
                                                self.present(playerViewController, animated: true) {
                                                    if let validPlayer = playerViewController.player {
                                                        validPlayer.play()
                                                    }
                                                }
                                            } else {
                                                NSLog("This is not a URL asset. Cannot play")
                                            }
            })
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let size = (collectionView.bounds.width - horizontalCount - 1) / horizontalCount
        setThumbnailSize(CGSize(width: size, height: size))
        return CGSize(width: size, height: size)
    }
}

extension CSPhotoGalleryViewController: PHPhotoLibraryChangeObserver {
    public func photoLibraryDidChange(_ changeInstance: PHChange) {
        guard let currentAsset = PhotoManager.sharedInstance.getCurrentAsset(), let changes = changeInstance.changeDetails(for: currentAsset) else {
            return
        }
        
        DispatchQueue.main.sync {
            // Hang on to the new fetch result.
            PhotoManager.sharedInstance.reloadCurrentAsset()
            if changes.hasIncrementalChanges {
                // If we have incremental diffs, animate them in the collection view.
                guard let collectionView = self.collectionView else { fatalError() }
                collectionView.performBatchUpdates({
                    // For indexes to make sense, updates must be in this order:
                    // delete, insert, reload, move
                    if let removed = changes.removedIndexes, removed.count > 0 {
                        collectionView.deleteItems(at: removed.map({ IndexPath(item: $0, section: 0) }))
                    }
                    if let inserted = changes.insertedIndexes, inserted.count > 0 {
                        collectionView.insertItems(at: inserted.map({ IndexPath(item: $0, section: 0) }))
                    }
                    if let changed = changes.changedIndexes, changed.count > 0 {
                        collectionView.reloadItems(at: changed.map({ IndexPath(item: $0, section: 0) }))
                    }
                    changes.enumerateMoves { fromIndex, toIndex in
                        collectionView.moveItem(at: IndexPath(item: fromIndex, section: 0),
                                                to: IndexPath(item: toIndex, section: 0))
                    }
                })
            } else {
                // Reload the collection view if incremental diffs are not available.
                collectionView!.reloadData()
            }
        }
    }
}
extension CSPhotoGalleryViewController{
    func scrollToBottom(){
        let item = self.collectionView(self.collectionView!, numberOfItemsInSection: 0) - 1
        guard item > 0 else{
            return
        }
        let lastItemIndex = IndexPath(item: item, section: 0)
        collectionView?.scrollToItem(at: lastItemIndex, at: UICollectionView.ScrollPosition.top, animated: false)
    }
}
