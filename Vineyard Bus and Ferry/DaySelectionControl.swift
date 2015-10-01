//
//  DaySelectionControl.swift
//  Vineyard Bus and Ferry
//
//  Created by Fred Hewett on 3/27/15.
//  Copyright (c) 2015 Frederick Hewett. All rights reserved.
//

import UIKit

protocol DaySelectionControlDelegate {
    func daySelection(selectedDayIndex index: Int)
}

class DaySelectionControl : UIView {
    let HEIGHT: CGFloat = 32.0
    let FONT_SIZE: CGFloat = 16.0
    let HMARGIN: CGFloat = 5.0
    let VMARGIN: CGFloat = 5.0
    let TEXT_COLOR: UIColor = UIColor.whiteColor()
    let TEXT_COLOR_SELECTED: UIColor = UIColor.yellowColor()
    
    var delegate: DaySelectionControlDelegate?
    var buttons: [UIButton]
    var dayAbbrevs: [String] = [
        "Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"
    ]

    init(width: CGFloat) {
        
        buttons = [UIButton]()
        
        let frame = CGRect(x: 0.0, y: 0.0, width: width, height: HEIGHT)
        super.init(frame: frame)
        userInteractionEnabled = true
        
        let deltaX = (width - HMARGIN*2)/7.0
        
        var buttonFrame = CGRect(x: 0.0, y: VMARGIN, width: deltaX, height: HEIGHT - (2*VMARGIN))
        for abbrev in dayAbbrevs {
            let button = UIButton(type: UIButtonType.Custom)
            button.frame = buttonFrame
            button.userInteractionEnabled = true
            buttonFrame.origin.x += deltaX
            button.titleLabel!.font = UIFont.systemFontOfSize(FONT_SIZE)
            
            var attrs = [String : AnyObject]()
            
            attrs[NSForegroundColorAttributeName] = TEXT_COLOR
            let normal = NSMutableAttributedString(string: abbrev, attributes: attrs)
            button.setAttributedTitle(normal, forState: UIControlState.Normal)
            
            attrs[NSForegroundColorAttributeName] = TEXT_COLOR_SELECTED
            attrs[NSFontAttributeName] = UIFont.boldSystemFontOfSize(FONT_SIZE)
            
            let selected = NSMutableAttributedString(string: abbrev, attributes: attrs)
            selected.addAttribute(NSUnderlineStyleAttributeName, value: NSUnderlineStyle.StyleSingle.rawValue, range: NSMakeRange(0,
                  button.titleLabel!.text!.utf16.count))

            button.setAttributedTitle(selected, forState: UIControlState.Selected)

            button.addTarget(self, action: "didTapButton:", forControlEvents: UIControlEvents.TouchUpInside)
            
            addSubview(button)
            buttons.append(button)
        }
    }
    
    func selectDayAtIndex(index: Int) {
        for button in buttons {
            button.selected = false
        }
        buttons[index].selected = true
    }
    
    func didTapButton(sender: AnyObject) {
        if let b = sender as? UIButton {

            for button in self.buttons {
                button.selected = false
            }
            b.selected = true
            
            if delegate != nil {
                let tapped = b.titleLabel!.text
                for (var index=0; index < dayAbbrevs.count; ++index) {
                    if dayAbbrevs[index] == tapped {
                        delegate?.daySelection(selectedDayIndex: index)
                        break
                    }
                }
            }
        }
    }
    

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}