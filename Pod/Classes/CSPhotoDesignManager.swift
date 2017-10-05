//
//  DesignManager.swift
//  CSPhotoGallery
//
//  Created by Youk Chansim on 2016. 12. 22..
//  Copyright © 2016년 Youk Chansim. All rights reserved.
//
//  This class manage design of CSPhotoGallery

import UIKit

public class CSPhotoDesignManager {
    public static var instance: CSPhotoDesignManager = CSPhotoDesignManager()
    
    //  Photo collection view
    public var photoGalleryBackButtonImage: UIImage?
    public var photoGalleryDismissCustomAction: (()->())?
    //  OK Button Title
    public var photoGalleryOKButtonTitle: String?
    public var photoGalleryOKButtonImage: UIImage?
    //  Check Image
    public var photoGalleryCheckImage: UIImage?
    //  UnCheck Image
    public var photoGalleryUnCheckImage: UIImage?
    //  When OK Button is hidden, CheckCountLabel and CheckBtn is hidden  
    public var isOKButtonHidden = false
    public var photoGalleryOKButtonCustomAction:((CSPhotoGalleryViewController)->())?
    public var isCountLabelHidden = false
    public var photoGalleryDeinit: ((CSPhotoGalleryViewController)->())?
    
    // Detail View Controller
    //  Photo detail view
    public var photoDetailBackButtonImage: UIImage?
    public var slideShowButtonTitle:String?
    public var slideShowButtonImage:UIImage?
    public var slideShowStopButtonTitle:String?
    public var slideShowStopButtonImage:UIImage?
    public var photoDetailOKButtonTitle:String?
    public var photoDetailOKButtonImage:UIImage?
    public var photoDetailOKButtonCustomAction: ((CSPhotoGalleryDetailViewController)->())?
    public var photoDetailViewDidLoadCustomAction: ((CSPhotoGalleryDetailViewController)->())?
    public var photoDetailDeinit: ((CSPhotoGalleryDetailViewController)->())?
    
}
