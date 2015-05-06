//
//  IAdBannerViewController.swift
//  Vineyard Bus and Ferry
//
//  Created by Fred Hewett on 4/2/15.
//  Copyright (c) 2015 Frederick Hewett. All rights reserved.
//

import UIKit
import iAd

class IAdBannerViewController: UIViewController, ADBannerViewDelegate {
    let BANNER_HEIGHT: CGFloat = 50
    let BOTTOM_BAR_HEIGHT: CGFloat = 50
    
    var adBannerView: ADBannerView!
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        adBannerView = ADBannerView(frame: CGRect.zeroRect)
        if adBannerView != nil {
            adBannerView.delegate = self
        }
        if adBannerView != nil {
            adBannerView.hidden = true
            view.addSubview(adBannerView)
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        if adBannerView != nil {
            adBannerView.removeFromSuperview()
            adBannerView = nil
        }
    }
    
    func bannerViewDidLoadAd(banner: ADBannerView!) {
        if banner == nil  {
            return
        }
        banner.hidden = false
        view.bringSubviewToFront(banner)
        let f = CGRect(x: 0, y: view.frame.height - BOTTOM_BAR_HEIGHT - BANNER_HEIGHT, width: view.frame.width, height: BANNER_HEIGHT)
        banner.frame = f
    }
    
    func bannerView(banner: ADBannerView!, didFailToReceiveAdWithError error: NSError!) {
        if banner == nil {
            return
        }
        banner.removeFromSuperview()
        adBannerView = nil
    }
}



