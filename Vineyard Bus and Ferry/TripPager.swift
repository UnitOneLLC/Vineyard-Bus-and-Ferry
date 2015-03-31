//
//  TripPager.swift
//  Vineyard Bus and Ferry
//
//  Created by Fred Hewett on 3/30/15.
//  Copyright (c) 2015 Frederick Hewett. All rights reserved.
//

import UIKit

protocol TripPagerDelegate {
    func tripPagerDelegate(#didSelectPage: Int)
}

class TripPager : UIView {
    class var PAGER_HEIGHT: CGFloat { return 30.0 }
    let MARGIN: CGFloat = 20.0
    var slider: UISlider!
    var delegate: TripPagerDelegate?
    
    init(frame: CGRect, count: Int) {
        super.init(frame: frame)
        var sliderFrame = frame
        sliderFrame.origin = CGPoint(x: MARGIN, y: 0.0)
        sliderFrame.size.width = frame.width - (2*MARGIN)
        slider = UISlider(frame: sliderFrame)
        slider.addTarget(self, action: "didChangeSliderValue:", forControlEvents: UIControlEvents.ValueChanged)
        
        slider.maximumValue = Float(count)-1
        slider.minimumValue = 0

        addSubview(slider)
    }
    
    func didChangeSliderValue(sender: AnyObject) {
        if delegate != nil {
            var newValue: Float = floor((slider.value/slider.maximumValue)*slider.maximumValue)
            slider.setValue(newValue, animated: true)
            delegate!.tripPagerDelegate(didSelectPage: Int(newValue))
            println("slider event: value = \(slider.value)")
        }
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
