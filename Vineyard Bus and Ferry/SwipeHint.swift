//
//  SwipeHint.swift
//  Vineyard Bus and Ferry
//
//  Created by Fred Hewett on 4/13/15.
//  Copyright (c) 2015 Frederick Hewett. All rights reserved.
//

import UIKit

class SwipeHintView : UIView {
    let XINSET: CGFloat = 2.0
    let YINSET: CGFloat = 10.0
    let FONT_SIZE: CGFloat = 12.0
    let HEIGHT_PADDING: CGFloat = 0.0
    let WIDTH_PADDING: CGFloat = 8.0
    let BGCOLOR = UIColor.darkGrayColor()
    let FGCOLOR = UIColor.whiteColor()
    let INITIAL_ALPHA: CGFloat = 0.75
    let label: UILabel!
    
    let TEXT = "\u{21e6}swipe column\u{21e8}"
    
    override init(frame: CGRect) {
        let font = UIFont.italicSystemFontOfSize(FONT_SIZE)
        let lblSize = (TEXT as NSString).sizeWithAttributes([NSFontAttributeName: font])
        let w = lblSize.width + WIDTH_PADDING
        let h = getLabelHeight(TEXT, font, w)
        
        let lblFrame = CGRect(x: XINSET, y: YINSET, width: w, height: h)
        label = UILabel(frame: lblFrame)
        label.attributedText = getAttributedString(TEXT, withFont: font)
        label.backgroundColor = BGCOLOR
        label.textColor = FGCOLOR
        label.textAlignment = NSTextAlignment.Center
        
        
        var selfFrame = frame
        selfFrame.size.height = h + HEIGHT_PADDING
        selfFrame.size.width = lblFrame.width + WIDTH_PADDING
        selfFrame.origin.y += YINSET
        super.init(frame: selfFrame)
        self.alpha = INITIAL_ALPHA
        
        addSubview(label)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func slideRight(#delaySeconds: Double) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(delaySeconds * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
            var f = self.frame
            f.origin.x += f.width
            UIView.animateWithDuration(0.35) {
                self.frame = f
                self.alpha = 0.0
            }
        }
    }
}
