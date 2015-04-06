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
    
    
    override func viewDidLoad() {
        println("enter IAdBannerViewController.iewDidLoad")
        super.viewDidLoad()
        
        adBannerView = ADBannerView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 0))
        adBannerView.delegate = self
        adBannerView.hidden = true
        //canDisplayBannerAds = true
        view.addSubview(adBannerView)
        println("leave IAdBannerViewController.iewDidLoad")
    }
    
    
    override func viewWillAppear(animated: Bool) {
        adBannerView.hidden = true
    }
    
    func bannerViewWillLoadAd(banner: ADBannerView!) {
        Logger.log(fromSource: self, level: .INFO, message: "BannerView will load ad")
    }
    
    func bannerViewDidLoadAd(banner: ADBannerView!) {
        adBannerView.hidden = false
        adBannerView.alpha = 1.0
        view.bringSubviewToFront(adBannerView)
        let f = CGRect(x: 0, y: view.frame.height - BOTTOM_BAR_HEIGHT - BANNER_HEIGHT, width: view.frame.width, height: BANNER_HEIGHT)
        adBannerView.frame = f
        Logger.log(fromSource: self, level: .INFO, message: "BannerView did load ad frame=\(adBannerView.frame)")
    }
    
    func bannerViewActionDidFinish(banner: ADBannerView!) {
        Logger.log(fromSource: self, level: .INFO, message: "Banner ad finished")
    }
    
    func bannerViewActionShouldBegin(banner: ADBannerView!, willLeaveApplication willLeave: Bool) -> Bool {
        Logger.log(fromSource: self, level: .INFO, message: "BannerView will leave = \(willLeave)")
        return true 
    }
    
    func bannerView(banner: ADBannerView!, didFailToReceiveAdWithError error: NSError!) {
        Logger.log(fromSource: self, level: .INFO, message: "BannerView failed to receive add")
        adBannerView.hidden = true
    }
}



