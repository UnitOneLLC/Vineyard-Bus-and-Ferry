//
//  RouteListCell.swift
//  Vineyard Bus and Ferry
//
//  Created by Fred Hewett on 3/21/15.
//  Copyright (c) 2015 Frederick Hewett. All rights reserved.
//

import UIKit

let SMALL_FONT_SIZE: CGFloat = 12.0
let LARGE_FONT_SIZE: CGFloat = 17.0
let SUBCELL_FONT_SIZE: CGFloat = 16.0
let SUBTABLE_ROW_HEIGHT: CGFloat = 29.0
let PADDING_SIZE: CGFloat = 9.0
let LEFT_MARGIN: CGFloat = 10.0
let RIGHT_MARGIN: CGFloat = 10.0

class RouteListCell: UITableViewCell {
    var shortNameLabel: UILabel!
    var longNameLabel: UILabel!
    var subTableView: UITableView!
    
    var route: Route!
    var itemText: (single: String, plural: String)!
    
    class func getHeight(route: Route, width: CGFloat) -> CGFloat {
        var shortNameHeight: CGFloat
        if route.shortName == nil || route.shortName!.isEmpty {
            shortNameHeight = 0.0
        }
        else {
            shortNameHeight = getLabelHeight(route.shortName!, UIFont.systemFontOfSize(SMALL_FONT_SIZE), width)
        }
        var longNameHeight = getLabelHeight(route.longName, UIFont.boldSystemFontOfSize(LARGE_FONT_SIZE), width)
        
        let total: CGFloat = shortNameHeight + longNameHeight + PADDING_SIZE + CGFloat(route.vectors.count) * SUBTABLE_ROW_HEIGHT
        
        return total
    }
    
    func initialize(#route: Route, width: CGFloat, text: (single: String, plural: String)) {
        self.route = route
        self.itemText = text
        
        if shortNameLabel == nil {
            shortNameLabel = UILabel()
            addSubview(shortNameLabel)
        }
        if longNameLabel == nil {
            longNameLabel = UILabel()
            addSubview(longNameLabel)
        }
        
        shortNameLabel.font = UIFont.systemFontOfSize(SMALL_FONT_SIZE)
        shortNameLabel.numberOfLines = 0
        shortNameLabel.lineBreakMode = .ByWordWrapping
        shortNameLabel.attributedText = getAttributedString(itemText.single + " " + route.shortName!, withFont: UIFont.systemFontOfSize(SMALL_FONT_SIZE))
        
        longNameLabel.font = UIFont.systemFontOfSize(LARGE_FONT_SIZE)
        longNameLabel.numberOfLines = 0
        longNameLabel.lineBreakMode = .ByWordWrapping
        longNameLabel.attributedText = getAttributedString(route.longName, withFont: UIFont.boldSystemFontOfSize(LARGE_FONT_SIZE))

        
        let width = self.contentView.frame.size.width
        var shortNameRect = CGRect()
        if route.shortName != nil && !route.shortName!.isEmpty {
            shortNameRect = getBoundingRect(text: itemText.single + " " + route.shortName!, font: UIFont.systemFontOfSize(SMALL_FONT_SIZE), width: width)
            shortNameRect.origin.x = LEFT_MARGIN
            shortNameRect.origin.y = 5.0
            shortNameLabel.frame = shortNameRect
        }
        var longNameRect = getBoundingRect(text: route.longName, font: UIFont.boldSystemFontOfSize(LARGE_FONT_SIZE), width: width)
        longNameRect.origin.x = CGFloat(ceilf(Float(LEFT_MARGIN)))
        longNameRect.origin.y = shortNameRect.size.height + 10.0
        longNameLabel.frame = longNameRect

        if subTableView == nil {
            subTableView = UITableView()
            subTableView.rowHeight = SUBTABLE_ROW_HEIGHT
            subTableView.scrollEnabled = false
            subTableView.separatorStyle = UITableViewCellSeparatorStyle.None
            
            addSubview(subTableView)
            subTableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "routeSubCell")
            subTableView.dataSource = self
            subTableView.delegate = self
        }
        
        
        let f = CGRect(origin: CGPoint(x: LEFT_MARGIN, y: longNameLabel.frame.origin.y + longNameLabel.frame.height), size: CGSize(width: width, height: CGFloat(route.vectors.count) * SUBTABLE_ROW_HEIGHT ))
        subTableView.frame = f
        subTableView.reloadData()
    }
}

extension RouteListCell: UITableViewDataSource {
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("routeSubCell", forIndexPath: indexPath) as! UITableViewCell
        var dest = route.vectors[indexPath.row].destination
        if dest == "Loop" && route.waypoint != nil && !route.waypoint!.isEmpty {
            dest = route.waypoint!
        }
        let attrText = getAttributedString("   To " + dest, withFont: UIFont.italicSystemFontOfSize(SUBCELL_FONT_SIZE))
        cell.textLabel!.attributedText = attrText
        cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
        
        return cell
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return route.vectors.count
    }
}

extension RouteListCell: UITableViewDelegate {
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var vc = (self.superview!.superview as! UITableView).delegate as! RouteListViewController
        vc.selectedRoute = route
        vc.selectedVectorIndex = indexPath.row
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
        vc.performSegueWithIdentifier("showVector", sender: self)
    }
    
}
