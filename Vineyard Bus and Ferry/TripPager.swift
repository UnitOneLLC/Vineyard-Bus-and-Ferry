//
//  TripPager.swift
//  Vineyard Bus and Ferry
//
//  Created by Fred Hewett on 3/30/15.
//  Copyright (c) 2015 Frederick Hewett. All rights reserved.
//

import UIKit

protocol TripPagerDelegate {
    func tripPagerDelegate(didPressEarlier: Bool)
}

class TripPager : UIView {
    class var PAGER_HEIGHT: CGFloat {return 45.0 }
    let BUTTON_HEIGHT: CGFloat = 40.0
    let BUTTON_WIDTH: CGFloat = 30.0

    // need offsetLeft
    var earlierButton: UIButton!
    var laterButton: UIButton!
    var delegate: TripPagerDelegate?
    
    init(frame: CGRect, xOffset: CGFloat) {
        super.init(frame: frame)
        let buttonVOffset = (TripPager.PAGER_HEIGHT - BUTTON_HEIGHT)/4.0
        
        self.backgroundColor = UIColor.whiteColor()
        
        let leftArrowFrame = CGRect(x: xOffset + BUTTON_WIDTH/2, y: buttonVOffset, width: BUTTON_WIDTH, height: TripPager.PAGER_HEIGHT)
        earlierButton = UIButton(frame: leftArrowFrame)
        let leftArrow = UIImage(contentsOfFile: NSBundle.mainBundle().pathForResource("blue-arrow-left", ofType: "png")!)
        earlierButton.setImage(leftArrow, forState: UIControlState.Normal)
        earlierButton.addTarget(self, action: "didPressEarlierTrip", forControlEvents: UIControlEvents.TouchUpInside)
        addSubview(earlierButton)
        
        let rightArrowFrame = CGRect(x: leftArrowFrame.origin.x + BUTTON_WIDTH, y: buttonVOffset,
            width: BUTTON_WIDTH, height: TripPager.PAGER_HEIGHT)
        laterButton = UIButton(frame: rightArrowFrame)
        let rightArrow = UIImage(contentsOfFile: NSBundle.mainBundle().pathForResource("blue-arrow-right", ofType: "png")!)
        laterButton.setImage(rightArrow, forState: UIControlState.Normal)
        laterButton.addTarget(self, action: "didPressLaterTrip", forControlEvents: UIControlEvents.TouchUpInside)
        addSubview(laterButton)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func didPressEarlierTrip() {
        if delegate != nil {
            delegate!.tripPagerDelegate(true)
        }
    }
    
    func didPressLaterTrip() {
        if delegate != nil {
            delegate!.tripPagerDelegate(false)
        }
    }
}
