//
//  Utils.swift
//  Vineyard Bus and Ferry
//
//  Created by Fred Hewett on 3/18/15.
//  Copyright (c) 2015 Frederick Hewett. All rights reserved.
//

import UIKit
import SystemConfiguration

func hCenterInFrame(#frameToCenter: CGRect, #container: CGRect) -> CGRect {
    var origin = CGPoint(x: CGFloat(container.width - frameToCenter.width)/CGFloat(2.0), y: frameToCenter.origin.y)
    return CGRect(origin: origin, size: frameToCenter.size)
}

func getAttributedString(text: String, withFont font: UIFont) -> NSAttributedString {
    var dico: [NSObject: AnyObject] = [NSObject: AnyObject]()
    dico[NSFontAttributeName] = font
    let attrString = NSAttributedString(string: text, attributes: dico)
    
    return attrString
}

func getBoundingRect(#text: String, #font: UIFont, #width: CGFloat) -> CGRect {
    let attrString = getAttributedString(text, withFont: font)
    
    let size = CGSize(width: width - RIGHT_MARGIN, height: CGFloat.max)
    
    let rect: CGRect = attrString.boundingRectWithSize(size, options: NSStringDrawingOptions.UsesLineFragmentOrigin, context: nil)
    
    return rect
}

func getLabelHeight(text: String, font: UIFont, width: CGFloat) -> CGFloat {
    let rect = getBoundingRect(text: text, font: font, width: width)
    return CGFloat(ceilf(Float(rect.height)))
}

func isInternetConnected() -> Bool {
    
    var reachability = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, "frederickhewett.com").takeRetainedValue()
    
    var flags : SCNetworkReachabilityFlags = 0
    
    if SCNetworkReachabilityGetFlags(reachability, &flags) == 0 {
        return false
    }
    
    let isReachable     = (flags & UInt32(kSCNetworkFlagsReachable)) != 0
    let needsConnection = (flags & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
    
    return (isReachable && !needsConnection)
}

extension NSDate {
    
    func isBefore(d: NSDate) -> Bool {
        return compare(d) == NSComparisonResult.OrderedAscending
    }
    
    func isAfter(d: NSDate) -> Bool {
        return compare(d) == NSComparisonResult.OrderedDescending
    }
    
}


//
//  Logger.swift
//
//  Created by Fred Hewett on 2/3/15.
//  Copyright (c) 2015 Appleton Software. All rights reserved.
//

import Foundation

class Logger {
    
    enum Level: Int {
        case INFO=0
        case DEBUG
        case WARN
        case ERROR
        case FATAL
    }
    
    class func log<T: Printable>(fromSource source: T, level: Level, message: String) {
        var output = "\(source) "
        
        switch level {
        case .INFO: output += "INFO"
        case .DEBUG: output += "DEBUG"
        case .WARN: output += "WARN"
        case .ERROR: output += "ERROR"
        case .FATAL: output += "FATAL"
        }
        
        output += " \"" + message + "\""
        
        NSLog("%@", output)
    }
}
