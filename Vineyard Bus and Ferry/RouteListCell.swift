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
let PADDING_SIZE: CGFloat = 15.0
let LEFT_MARGIN: CGFloat = 10.0
let RIGHT_MARGIN: CGFloat = 10.0

class RouteListCell: UITableViewCell {
    var shortNameLabel: UILabel!
    var longNameLabel: UILabel!
    @IBOutlet weak var subTableView: UITableView!
    
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
        
        subTableView.dataSource = self
        subTableView.delegate = self
        subTableView.reloadData()

        shortNameLabel.font = UIFont.systemFontOfSize(SMALL_FONT_SIZE)
        shortNameLabel.numberOfLines = 0
        shortNameLabel.lineBreakMode = .ByWordWrapping
        shortNameLabel.attributedText = getAttributedString(itemText.single + " " + route.shortName!, withFont: UIFont.systemFontOfSize(SMALL_FONT_SIZE))
        
        longNameLabel.font = UIFont.systemFontOfSize(LARGE_FONT_SIZE)
        longNameLabel.numberOfLines = 0
        longNameLabel.lineBreakMode = .ByWordWrapping
        longNameLabel.attributedText = getAttributedString(route.longName, withFont: UIFont.boldSystemFontOfSize(LARGE_FONT_SIZE))
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

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
        
        var subTableRect = CGRect(origin: CGPoint(x: LEFT_MARGIN, y: shortNameRect.size.height + longNameRect.size.height + 10.0), size: CGSize(width: width, height: CGFloat(route.vectors.count) * SUBTABLE_ROW_HEIGHT ))
        subTableView.frame = subTableRect
    }
}

extension RouteListCell: UITableViewDataSource {
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("routeSubCell", forIndexPath: indexPath) as UITableViewCell
        let attrText = getAttributedString("   To " + route.vectors[indexPath.row].destination, withFont: UIFont.italicSystemFontOfSize(SUBCELL_FONT_SIZE))
        cell.textLabel!.attributedText = attrText
        
        return cell
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return route.vectors.count
    }
}

extension RouteListCell: UITableViewDelegate {
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var vc = (self.superview!.superview as UITableView).delegate as RouteListViewController
        vc.selectedRoute = route
        vc.selectedVectorIndex = indexPath.row
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
        vc.performSegueWithIdentifier("showVector", sender: self)
    }
    
}
