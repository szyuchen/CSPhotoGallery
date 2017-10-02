//
//  CSPhotoViewerTransition.swift
//  CSPhotoGallery
//
//  Created by Youk Chansim on 2016. 12. 15..
//  Copyright © 2016년 Youk Chansim. All rights reserved.
//

import UIKit
import AVFoundation

class CSPhotoViewerTransition: NSObject, UIViewControllerTransitioningDelegate {
    var initialRect = CGRect.zero
    var originalImage = UIImage()
    weak var originalViewController:CSPhotoGalleryViewController?
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let presentAnimation = CSPhotoViewerPresentAnimation(initialRect: initialRect, originalImage: originalImage)
        return presentAnimation
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let dismissAnimation = CSPhotoViewerDismissAnimation()
        dismissAnimation.originalViewController = originalViewController
        return dismissAnimation
    }
}

class CSPhotoViewerPresentAnimation: NSObject, UIViewControllerAnimatedTransitioning {
    let initialRect: CGRect
    var originalImage: UIImage
    
    init(initialRect: CGRect, originalImage: UIImage) {
        self.initialRect = initialRect
        self.originalImage = originalImage
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toViewController = transitionContext.viewController(forKey: .to) as? CSPhotoGalleryDetailViewController else { return }
        
        let containerView = transitionContext.containerView
        let animationDuration = transitionDuration(using: transitionContext)
        
        let imageView = UIImageView(image: originalImage)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.frame = initialRect
        containerView.addSubview(imageView)
        
        toViewController.view.alpha = 0
        toViewController.view.layoutIfNeeded()
        containerView.addSubview(toViewController.view)
        
        let frame = getImageScaleFactor(originImage: originalImage, standardFrame: toViewController.collectionView.frame)
        UIView.animate(withDuration: animationDuration) {
            imageView.frame = frame
        }
        
        UIView.animate(withDuration: animationDuration, delay: 0.2, options: [], animations: {
            toViewController.view.alpha = 1
        }) { complete in
            imageView.removeFromSuperview()
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
}

class CSPhotoViewerDismissAnimation: NSObject, UIViewControllerAnimatedTransitioning {
    weak var originalViewController:CSPhotoGalleryViewController?
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        var toViewController: CSPhotoGalleryViewController?
        
        if let o = originalViewController {
            toViewController = o
        }
        else if let vc = transitionContext.viewController(forKey: .to) as? CSPhotoGalleryViewController {
            toViewController = vc
        } else if let nvc = transitionContext.viewController(forKey: .to) as? UINavigationController {
            guard let vc = nvc.topViewController as? CSPhotoGalleryViewController else { return }
            toViewController = vc
        }
        
        guard let fromViewController = transitionContext.viewController(forKey: .from) as? CSPhotoGalleryDetailViewController else { return }
        
        let animationDuration = transitionDuration(using: transitionContext)
        let containerView = transitionContext.containerView
        let originImage = fromViewController.currentImage ?? UIImage()
        let destinationFrame = toViewController?.collectionViewCellFrame(at: fromViewController.currentIndexPath) ?? CGRect.zero
        
        let frame = getImageScaleFactor(originImage: originImage, standardFrame: fromViewController.collectionView.frame)
        let imageView = UIImageView(frame: frame)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.image = originImage
        
        containerView.addSubview(imageView)
        UIView.animate(withDuration: animationDuration, animations: {
            fromViewController.view.alpha = 0
        })
        
        UIView.animate(withDuration: animationDuration, animations: {
            imageView.frame = destinationFrame
        }) { complete in
            imageView.removeFromSuperview()
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
}

fileprivate extension UIViewControllerAnimatedTransitioning {
    func getImageScaleFactor(originImage: UIImage, standardFrame: CGRect) -> CGRect {
        let imageWidth = CGFloat(originImage.cgImage!.width)
        let imageHeight = CGFloat(originImage.cgImage!.height)
        return AVMakeRect( aspectRatio: CGSize(width: imageWidth,height: imageHeight), insideRect: standardFrame)
    }
}
