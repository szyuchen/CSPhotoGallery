//
//  CSPhotoGalleryDetailViewController.swift
//  CSPhotoGallery
//
//  Created by Youk Chansim on 2016. 12. 7..
//  Copyright © 2016년 Youk Chansim. All rights reserved.
//

import UIKit
import Photos

class CSPhotoGalleryDetailViewController: UIViewController {
//    var scrollViewState: UIGestureRecognizerState = .possible
    var dragging:Bool = false
    
    
    @IBOutlet weak var progressView: UIProgressView!
    static var instance: CSPhotoGalleryDetailViewController {
        let podBundle = Bundle(for: CSPhotoGalleryViewController.self)
        let bundleURL = podBundle.url(forResource: "CSPhotoGallery", withExtension: "bundle")
        let bundle = bundleURL == nil ? podBundle : Bundle(url: bundleURL!)
        let storyBoard = UIStoryboard.init(name: "CSPhotoGallery", bundle: bundle)
        return storyBoard.instantiateViewController(withIdentifier: identifier) as! CSPhotoGalleryDetailViewController
    }
    @IBOutlet fileprivate weak var currentIndexLabel: UILabel? {
        didSet {
            updateCurrentIndexLabel()
        }
    }
    
    @IBOutlet fileprivate weak var currentCollectionCountLabel: UILabel? {
        didSet {
            updateCurrentCollectionAssetCount()
        }
    }
    
    @IBOutlet fileprivate weak var checkCountLabel: UILabel? {
        didSet {
            updateCurrentSelectedCount()
            checkCountLabel?.isHidden = CSPhotoDesignManager.instance.isCountLabelHidden
        }
    }
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet fileprivate weak var checkBtn: UIButton! {
        didSet {
            checkBtn.isHidden = CSPhotoDesignManager.instance.isCountLabelHidden
        }
    }
    
    @IBOutlet weak var okBtn: UIButton! {
        didSet {
            okBtn.setImage(CSPhotoDesignManager.instance.photoGalleryOKButtonImage, for: .normal)
            okBtn.setTitle(CSPhotoDesignManager.instance.photoGalleryOKButtonTitle, for: .normal)
            okBtn.isHidden = CSPhotoDesignManager.instance.isCountLabelHidden
        }
    }
    
    @IBOutlet fileprivate weak var backBtn: UIButton! {
        didSet {
            if let image = CSPhotoDesignManager.instance.photoDetailBackButtonImage {
                backBtn.setImage(image, for: .normal)
            }
        }
    }
    
    var delegate: CSPhotoGalleryDelegate?
    fileprivate var prevIndexPath: IndexPath?
    var currentIndexPath: IndexPath = IndexPath(item: 0, section: 0) {
        didSet {
            if PhotoManager.sharedInstance.assetsCount > 0 {
                updateCurrentIndexLabel()
                updateCheckBtnUI()
                let asset = PhotoManager.sharedInstance.getCurrentCollectionAsset(at: currentIndexPath)
                delegate?.CSPhotoGallerySelectedImageDidChange(asset:asset)
            }
        }
    }
    
    var currentImage: UIImage?
    var checkImage: UIImage?
    var unCheckImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setViewController()
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    override func viewDidLayoutSubviews(){
//        guard scrollViewState != .changed else{
//            return
//        }
        guard dragging == false else{
            return
        }
        collectionView.scrollToItem(at: currentIndexPath, at: .left, animated: false)
    }
    
}

//  IBAction
private extension CSPhotoGalleryDetailViewController {
    @IBAction func backBtnAction(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @IBAction func checkBtnAction(_ sender: Any) {
        let identifier = PhotoManager.sharedInstance.getLocalIdentifier(at: currentIndexPath)
        PhotoManager.sharedInstance.setSelectedIndexPath(identifier: identifier)
        updateCheckBtnUI()
        updateCurrentSelectedCount()
        
        let vc = presentingViewController as? CSPhotoGalleryViewController
        vc?.updateCollectionViewCellUI(indexPath: currentIndexPath)
    }
    
    @IBAction func okBtnAction(_ sender: Any) {
        delegate?.getAssets(assets: PhotoManager.sharedInstance.assets)
        dismiss(animated: false)
    }
}

//  MARK:- Init ViewController
fileprivate extension CSPhotoGalleryDetailViewController {
    fileprivate func setViewController() {
        setData()
        setView()
        self.collectionView.layoutIfNeeded()
    }
    
    private func setData() {
        
    }
    
    private func setView() {
//        scrollToCurrentIndexPath()
        
        let podBundle = Bundle(for: CSPhotoGalleryDetailViewController.self)
        let bundleURL = podBundle.url(forResource: "CSPhotoGallery", withExtension: "bundle")
        let bundle = bundleURL == nil ? podBundle : Bundle(url: bundleURL!)
        
        let originalCheckImage = UIImage(named: "check_select", in: bundle, compatibleWith: nil)
        let originalUnCheckImage = UIImage(named: "check_default", in: bundle, compatibleWith: nil)
        
        checkImage = CSPhotoDesignManager.instance.photoGalleryCheckImage ?? originalCheckImage
        unCheckImage = CSPhotoDesignManager.instance.photoGalleryUnCheckImage ?? originalUnCheckImage
    }
    
    func updateCurrentSelectedCount() {
        DispatchQueue.main.async {
            self.checkCountLabel?.text = "\(PhotoManager.sharedInstance.assets.count)"
        }
    }
    
    func updateCurrentIndexLabel() {
        DispatchQueue.main.async {
            self.currentIndexLabel?.text = "\(self.currentIndexPath.item + 1)"
        }
    }
    
    func updateCurrentCollectionAssetCount() {
        DispatchQueue.main.async {
            self.currentCollectionCountLabel?.text = "\(PhotoManager.sharedInstance.assetsCount)"
        }
    }
    
    func updateCheckBtnUI() {
        DispatchQueue.main.async {
            let identifier = PhotoManager.sharedInstance.getLocalIdentifier(at: self.currentIndexPath)
            if PhotoManager.sharedInstance.isSelectedIndexPath(identifier: identifier) {
                self.checkBtn?.setImage(self.checkImage, for: .normal)
            } else {
                self.checkBtn?.setImage(self.unCheckImage, for: .normal)
            }
        }
    }
    
    func scrollToCurrentIndexPath() {
        DispatchQueue.main.async {
            self.collectionView.scrollToItem(at: self.currentIndexPath, at: .left, animated: false)
        }

    }
    
    override internal func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        guard let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else {
            return
        }
        flowLayout.invalidateLayout()
        self.scrollToCurrentIndexPath()
    }
    
}

//  MARK:- Extension
fileprivate extension CSPhotoGalleryDetailViewController {
    func dismiss(animated: Bool) {
        var vc: CSPhotoGalleryViewController?
        
        if presentingViewController is CSPhotoGalleryViewController {
            vc = presentingViewController as? CSPhotoGalleryViewController
        } else if presentingViewController is UINavigationController {
            let nvc = presentingViewController as? UINavigationController
            vc = nvc?.topViewController as? CSPhotoGalleryViewController
        }
        
        vc?.scrollRectToVisible(indexPath: currentIndexPath)
        vc?.reloadCollectionView()
        
        let asset = PhotoManager.sharedInstance.getCurrentCollectionAsset(at: currentIndexPath)
        let size = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)

        
        PhotoManager.sharedInstance.assetToImage(asset: asset, imageSize: size, isCliping: false) { image in
            self.currentImage = image
            self.dismiss(animated: animated, completion: {
                if !animated {
                    vc?.delegate?.getAssets(assets: PhotoManager.sharedInstance.assets)
                    vc?.dismiss()
                }
            })
        }
    }
}

//  MARK:- UICollectionView DataSource
extension CSPhotoGalleryDetailViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return PhotoManager.sharedInstance.assetsCount
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(indexPath: indexPath) as CSPhotoGalleryDetailCollectionViewCell
        let asset = PhotoManager.sharedInstance.getCurrentCollectionAsset(at: indexPath)
        
        cell.representedAssetIdentifier = asset.localIdentifier
        
        let size = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
        let progress:PHAssetImageProgressHandler = {(progress, error, pointer, info) in
            DispatchQueue.main.async {
                self.progressView.isHidden = progress >= 1.0
                self.progressView.progress = Float(progress)
            }
        }
        PhotoManager.sharedInstance.setThumbnailImage(at: indexPath, thumbnailSize: size, isCliping: false, progress:progress) { image in
            if cell.representedAssetIdentifier == asset.localIdentifier {
                cell.imageView.image = image
            }
        }
        
        return cell
    }
}

//  MARK:- UICollectionView Delegate
extension CSPhotoGalleryDetailViewController: UICollectionViewDelegateFlowLayout {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView == collectionView {
            var visibleRect = CGRect()
            visibleRect.origin = collectionView.contentOffset
            visibleRect.size = collectionView.bounds.size
            let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
            if let visibleIndexPath: IndexPath = collectionView.indexPathForItem(at: visiblePoint) {
                if currentIndexPath != visibleIndexPath {
                    prevIndexPath = currentIndexPath
                    currentIndexPath = visibleIndexPath
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.frame.size
    }
}

//  MARK:- UIScrollView Delegate
extension CSPhotoGalleryDetailViewController: UIScrollViewDelegate {
//    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
//        let cell = collectionView.cellForItem(at: currentIndexPath) as? CSPhotoGalleryDetailCollectionViewCell
//        return cell?.imageView
//    }
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView == collectionView else {
            return
        }
//        scrollViewState = scrollView.panGestureRecognizer.state
    }
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        dragging = true
    }
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard decelerate == false else {
            return
        }
        dragging = false
    }
}
