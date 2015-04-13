//
//  SwipeHint.swift
//  Vineyard Bus and Ferry
//
//  Created by Fred Hewett on 4/13/15.
//  Copyright (c) 2015 Frederick Hewett. All rights reserved.
//

import UIKit

class SwipeHintView : UIView {
    let XINSET: CGFloat = 5.0
    let YINSET: CGFloat = 10.0
    let FONT_SIZE: CGFloat = 13.0
    let HEIGHT_PADDING: CGFloat = 5.0
    let BGCOLOR = UIColor.darkGrayColor()
    let FGCOLOR = UIColor.whiteColor()
    let label: UILabel!
    
    let TEXT = "\u{21e6} Swipe column \u{21e8}"
    
    override init(frame: CGRect) {
        let font = UIFont.italicSystemFontOfSize(FONT_SIZE)
        let w = frame.width - (XINSET*2)
        let h = getLabelHeight(TEXT, font, w)
        
        let lblFrame = CGRect(x: XINSET, y: YINSET, width: w, height: h)
        label = UILabel(frame: lblFrame)
        label.numberOfLines = 0
        label.lineBreakMode = .ByWordWrapping
        label.attributedText = getAttributedString(TEXT, withFont: font)
        label.backgroundColor = BGCOLOR
        label.textColor = FGCOLOR
        label.textAlignment = NSTextAlignment.Center
        
        var selfFrame = frame
        selfFrame.size.height = h + HEIGHT_PADDING
        super.init(frame: selfFrame)
        
        addSubview(label)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func slideRight(#delaySeconds: Double) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(delaySeconds * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
            var f = self.frame
            f.origin.x += f.width
            UIView.animateWithDuration(0.5) {
                self.frame = f
                self.alpha = 0.0
            }
        }
    }
}
