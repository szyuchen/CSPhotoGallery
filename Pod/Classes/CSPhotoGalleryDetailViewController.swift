//
//  CSPhotoGalleryDetailViewController.swift
//  CSPhotoGallery
//
//  Created by Youk Chansim on 2016. 12. 7..
//  Copyright © 2016년 Youk Chansim. All rights reserved.
//

import UIKit
import Photos

public class CSPhotoGalleryDetailViewController: UIViewController {
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
//    @IBOutlet fileprivate weak var checkBtn: UIButton! {
//        didSet {
//            checkBtn.isHidden = CSPhotoDesignManager.instance.isCountLabelHidden
//        }
//    }
    
    @IBOutlet weak var slideshowButton: UIButton! {
        didSet {
            slideshowButton.setTitle(CSPhotoDesignManager.instance.slideShowButtonTitle, for: .normal)
            slideshowButton.setImage(CSPhotoDesignManager.instance.slideShowButtonImage, for: .normal)
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
                let asset = PhotoManager.sharedInstance.getCurrentCollectionAsset(at: currentIndexPath)
                DispatchQueue.main.async {
                    self.delegate?.CSPhotoGallerySelectedImageDidChange(asset:asset, detailVC: self)
                }
            }
        }
    }
    public func currentAsset()-> PHAsset{
        return PhotoManager.sharedInstance.getCurrentCollectionAsset(at: currentIndexPath)
    }
    
    var currentImage: UIImage?
    var checkImage: UIImage?
    var unCheckImage: UIImage?
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setViewController()
        CSPhotoDesignManager.instance.photoDetailViewDidLoadCustomAction?(self)
    }
    
    override public var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    override public func viewDidLayoutSubviews(){
        guard dragging == false else{
            return
        }
        // iOS14 scorllToItem broken
        // collectionView.scrollToItem(at: currentIndexPath, at: .left, animated: false)
        if let cPoint = self.collectionView.layoutAttributesForItem(at: currentIndexPath) {
            let visiblePoint = CGPoint(x: cPoint.frame.minX, y: 0)
            collectionView.contentOffset = visiblePoint
        }
    }
    @IBOutlet weak var segmentControl: UISegmentedControl!
    var timer:Timer? = nil
    
    
    @IBAction func segmentValueChange(_ sender: Any) {
        guard timer != nil && timer!.isValid else{
            return
        }
        timer!.invalidate()
        timer = nil
        setSlideShowTimer()
    }
    
    @IBOutlet public weak var okButton: UIButton!{
        didSet {
            okButton.setTitle(CSPhotoDesignManager.instance.photoDetailOKButtonTitle, for: .normal)
            okButton.setImage(CSPhotoDesignManager.instance.photoDetailOKButtonImage, for: .normal)
        }
    }
    
    
    @IBAction func okButtonAction(_ sender: Any) {
        CSPhotoDesignManager.instance.photoDetailOKButtonCustomAction?(self)
    }
    
    deinit {
        CSPhotoDesignManager.instance.photoDetailDeinit?(self)
    }
}

//  IBAction
extension CSPhotoGalleryDetailViewController {
    @IBAction func backBtnAction(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @IBAction func slideShowButtonAction(_ sender: Any) {

        guard timer != nil && timer!.isValid else {
            slideshowButton.setTitle(CSPhotoDesignManager.instance.slideShowStopButtonTitle, for: .normal)
            slideshowButton.setImage(CSPhotoDesignManager.instance.slideShowStopButtonImage , for: .normal)
            setSlideShowTimer()
            return
        }
        slideshowButton.setTitle(CSPhotoDesignManager.instance.slideShowButtonTitle, for: .normal)
        slideshowButton.setImage(CSPhotoDesignManager.instance.slideShowButtonImage, for: .normal)
        timer!.invalidate()
        timer = nil
    }
    fileprivate func setSlideShowTimer(){
        var interval = 3.0
        if let title = segmentControl.titleForSegment(at: segmentControl.selectedSegmentIndex) {
            interval = Double(title)!
        }
        print("slide show goes with interval:\(interval)")
        timer?.invalidate()
        timer = nil
        timer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(self.fire(timer:)), userInfo: nil, repeats: true)
    }
    
    @objc func fire(timer:Timer)->Swift.Void{
        scrollToNextIndexPath(animated:true)
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
    
//    func updateCheckBtnUI() {
//        DispatchQueue.main.async {
//            let identifier = PhotoManager.sharedInstance.getLocalIdentifier(at: self.currentIndexPath)
//            if PhotoManager.sharedInstance.isSelectedIndexPath(identifier: identifier) {
//                self.checkBtn?.setImage(self.checkImage, for: .normal)
//            } else {
//                self.checkBtn?.setImage(self.unCheckImage, for: .normal)
//            }
//        }
//    }
    
    func scrollToCurrentIndexPath() {
        DispatchQueue.main.async {
            // self.collectionView.scrollToItem(at: self.currentIndexPath, at: .left, animated: false)
            if let cPoint = self.collectionView.layoutAttributesForItem(at: self.currentIndexPath) {
                let visiblePoint = CGPoint(x: cPoint.frame.minX, y: 0)
                self.collectionView.contentOffset = visiblePoint
            }
        }
    }
    func scrollToNextIndexPath(animated:Bool = false) {
        if(self.currentIndexPath.row >=  PhotoManager.sharedInstance.assetsCount-1){
            self.slideShowButtonAction(self)    //stop
            return
        }
        DispatchQueue.main.async {

            
            let newIndex = IndexPath(row: self.currentIndexPath.row+1, section: self.currentIndexPath.section)
            //self.collectionView.scrollToItem(at: newIndex, at: .left, animated: animated)
            if let cPoint = self.collectionView.layoutAttributesForItem(at: newIndex) {
                let visiblePoint = CGPoint(x: cPoint.frame.minX, y: 0)
                self.collectionView.contentOffset = visiblePoint
            }
            self.currentIndexPath = newIndex
        }
    }
    


}

//  MARK:- Extension
fileprivate extension CSPhotoGalleryDetailViewController {
    func dismiss(animated: Bool) {
        
        timer?.invalidate()
        timer = nil
        
        
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
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return PhotoManager.sharedInstance.assetsCount
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(indexPath: indexPath) as CSPhotoGalleryDetailCollectionViewCell
        let asset = PhotoManager.sharedInstance.getCurrentCollectionAsset(at: indexPath)
        
        cell.representedAssetIdentifier = asset.localIdentifier
        
        let size = UIScreen.main.nativeBounds.size
        let progress:PHAssetImageProgressHandler = {(progress, error, pointer, info) in
            DispatchQueue.main.async { [weak self] in
                self?.progressView.isHidden = progress >= 1.0
                self?.progressView.progress = Float(progress)
                if progress < 1.0 { //
                    self?.timer?.invalidate()
                } else if let timer = self?.timer, timer.isValid == false {
                    self?.setSlideShowTimer()
                }
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
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
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
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.frame.size
    }
}

//  MARK:- UIScrollView Delegate
extension CSPhotoGalleryDetailViewController: UIScrollViewDelegate {
//    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
//        let cell = collectionView.cellForItem(at: currentIndexPath) as? CSPhotoGalleryDetailCollectionViewCell
//        return cell?.imageView
//    }

    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        dragging = true
    }
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard decelerate == false else {
            return
        }
        dragging = false
    }
}

extension CSPhotoGalleryDetailViewController{
    override public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        guard let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else {
            return
        }
        flowLayout.invalidateLayout()
        self.scrollToCurrentIndexPath()
    }
}
