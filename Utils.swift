//
//  Utils.swift
//  Vineyard Bus and Ferry
//
//  Created by Fred Hewett on 3/18/15.
//  Copyright (c) 2015 Frederick Hewett. All rights reserved.
//

import UIKit
import SystemConfiguration
import MapKit

func hCenterInFrame(frameToCenter frameToCenter: CGRect, container: CGRect) -> CGRect {
    let origin = CGPoint(x: CGFloat(container.width - frameToCenter.width)/CGFloat(2.0), y: frameToCenter.origin.y)
    return CGRect(origin: origin, size: frameToCenter.size)
}

func getAttributedString(text: String, withFont font: UIFont) -> NSAttributedString {
    var dico: [String: AnyObject] = [String: AnyObject]()
    dico[NSFontAttributeName] = font
    let attrString = NSAttributedString(string: text, attributes: dico)
    
    return attrString
}

func getMutableAttributedString(text: String, withFont font: UIFont) -> NSMutableAttributedString {
    var dico: [String: AnyObject] = [String: AnyObject]()
    dico[NSFontAttributeName] = font
    let attrString = NSMutableAttributedString(string: text, attributes: dico)
    
    return attrString
}

func getBoundingRect(text text: String, font: UIFont, width: CGFloat) -> CGRect {
    let attrString = getAttributedString(text, withFont: font)
    
    let size = CGSize(width: width - RIGHT_MARGIN, height: CGFloat.max)
    
    let rect: CGRect = attrString.boundingRectWithSize(size, options: NSStringDrawingOptions.UsesLineFragmentOrigin, context: nil)
    
    return rect
}

func getLabelHeight(text: String, font: UIFont, width: CGFloat) -> CGFloat {
    let rect = getBoundingRect(text: text, font: font, width: width)
    return CGFloat(ceilf(Float(rect.height)))
}


public class Reachability {
    class func isConnectedToNetwork() -> Bool {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(sizeofValue(zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        let defaultRouteReachability = withUnsafePointer(&zeroAddress) {
            SCNetworkReachabilityCreateWithAddress(nil, UnsafePointer($0))
        }
        var flags = SCNetworkReachabilityFlags()
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
            return false
        }
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        return (isReachable && !needsConnection)
    }
}


func isInternetConnected() -> Bool {
    return Reachability.isConnectedToNetwork()
}

func normalizedDate(date: NSDate) -> NSDate {
    let calendar = NSCalendar.currentCalendar()
    let set : NSCalendarUnit = [NSCalendarUnit.Year, NSCalendarUnit.Month, NSCalendarUnit.Day]
    let components = calendar.components(set, fromDate: date)
    let result = calendar.dateFromComponents(components)
    return result!
}

func stackView(view: UIView, positionBelow refView: UIView) {
    var f = view.frame
    f.origin.y = refView.frame.origin.y + refView.frame.height
    view.frame = f
}

extension NSDate {
    
    func isBefore(d: NSDate) -> Bool {
        return compare(d) == NSComparisonResult.OrderedAscending
    }
    
    func isAfter(d: NSDate) -> Bool {
        return compare(d) == NSComparisonResult.OrderedDescending
    }
    
}

func makeSpan(latDelta: Double, lngDelta: Double, view: UIView) -> MKCoordinateSpan {
    let frameHeight = view.frame.size.height
    let frameWidth = view.frame.size.width
    let MARGIN: Double = 0.05
    
    if frameHeight >= frameWidth {
        let aspect = Double(frameHeight/frameWidth)
        
        let latDelta2 = latDelta + MARGIN
        let lngDelta2 = (lngDelta + MARGIN) * aspect
        let span = MKCoordinateSpan(latitudeDelta: CLLocationDegrees(latDelta2), longitudeDelta: CLLocationDegrees(lngDelta2))
        return span
    }
    else {
        let aspect = Double(frameWidth/frameHeight)
        
        let latDelta2 = (latDelta + MARGIN) * aspect
        let lngDelta2 = lngDelta + MARGIN
        let span = MKCoordinateSpan(latitudeDelta: CLLocationDegrees(latDelta2), longitudeDelta: CLLocationDegrees(lngDelta2))
        return span
    }
}

// Creates a UIColor from a Hex string.
// https://gist.github.com/arshad/de147c42d7b3063ef7bc

func colorWithHexString (hex:String) -> UIColor {
    var cString:String = hex.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).uppercaseString
    if (cString.hasPrefix("#")) {
        cString = cString.substringFromIndex(hex.startIndex)
    }
    if (cString.characters.count != 6) {
        return UIColor.grayColor()
    }
    let rString = cString.substringToIndex(hex.startIndex.advancedBy(2))
    var gString = cString.substringFromIndex(hex.startIndex.advancedBy(2))
        gString = gString.substringToIndex(gString.startIndex.advancedBy(2))
    var bString = cString.substringFromIndex(hex.startIndex.advancedBy(4))
        bString = bString.substringToIndex(bString.startIndex.advancedBy(2))
    
    var r:CUnsignedInt = 0, g:CUnsignedInt = 0, b:CUnsignedInt = 0;
    NSScanner(string: rString).scanHexInt(&r)
    NSScanner(string: gString).scanHexInt(&g)
    NSScanner(string: bString).scanHexInt(&b)

    return UIColor(red: CGFloat(r) / 255.0, green: CGFloat(g) / 255.0, blue: CGFloat(b) / 255.0, alpha: CGFloat(1))
}

func simpleAlert(title: String, message: String, controller: AnyObject) {
    let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
    let okAction = UIAlertAction(title: "OK", style: .Default) { (action) in  }
    alert.addAction(okAction)
    (controller as! UIViewController).presentViewController(alert, animated: true, completion: nil)
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
    
    class func log<T:CustomStringConvertible>(fromSource source: T, level: Level, message: String) {
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
