//
//  VectorTable.swift
//  Vineyard Bus and Ferry
//
//  Created by Fred Hewett on 3/25/15.
//  Copyright (c) 2015 Frederick Hewett. All rights reserved.
//

import UIKit

class VectorTableStopCell : UITableViewCell {

    override func layoutSubviews() {
        super.layoutSubviews()
        
        textLabel!.textAlignment = NSTextAlignment.Right
        var lblFrame = textLabel!.frame
        let cellWidth = self.contentView.frame.width
        lblFrame.origin.x = cellWidth - lblFrame.width - 10.0
        textLabel!.frame = lblFrame
    }
}


class VectorTable : UIScrollView, UITableViewDataSource, UITableViewDelegate, TripCollectionDelegate {
    class var REUSE_ID: String { return "vectorTableStopCell" }
    class var CELL_FONT_SIZE: CGFloat { return 15.0 }
    class var CELL_HEIGHT_PADDING: CGFloat { return 10.0 }
    class var PADDING_PX: CGFloat { return 15.0 }
    class var TIME_WIDTH: CGFloat { return 124.0 }
    
    class var cellFont: UIFont {
        return UIFont.systemFontOfSize(CELL_FONT_SIZE)
    }
    
    var stopTable: UITableView!
    let schedule: Schedule!
    let vectorIndex: Int!
    let route: Route!
    var stopSequence: [Stop]!
    var cellText: [String]!
    var stopListWidth: CGFloat!
    var tripCollection: TripCollection!
    var rowHeights: [Double]!
    var stopInTrip: [Bool]!
    
    init(frame: CGRect, route: Route, vectorIndex: Int) {
        super.init(frame: frame)
        
        self.vectorIndex = vectorIndex
        self.schedule = AppDelegate.theScheduleManager.scheduleForAgency(route.agency)!
        self.route = route
        
        if route.vectors.count <= vectorIndex {
            Logger.log(fromSource: self, level: .ERROR, message: "Bad vector index \(vectorIndex) for route \(route.id)")
            return
        }
        
        stopSequence = AppDelegate.theScheduleManager.stopSequenceForVector(route.vectors[vectorIndex], inSchedule: self.schedule)
        
        stopListWidth = frame.width * 0.70
        let tableFrame = CGRect(x: 0.0, y: 0.0, width: stopListWidth, height: CGFloat(totalHeight))
        stopTable = UITableView(frame: tableFrame)
        stopTable.separatorStyle = UITableViewCellSeparatorStyle.None
        stopTable.registerClass(VectorTableStopCell.self, forCellReuseIdentifier: VectorTable.REUSE_ID)
        stopTable.scrollEnabled = false
        stopTable.dataSource = self
        stopTable.delegate = self
        addSubview(stopTable)
        
        rowHeights = [Double]()
        var totalHeight2 = 0.0
        for stop in stopSequence {
            let h: Double = Double(getLabelHeight(stop.name, UIFont.systemFontOfSize(VectorTable.CELL_FONT_SIZE), stopListWidth - VectorTable.PADDING_PX)) + Double(VectorTable.CELL_HEIGHT_PADDING)
            rowHeights.append(h)
            totalHeight2 += h
        }
        
        println("theight = \(totalHeight), tHeight2=\(totalHeight2)")
        
        let tripCollectionFrame = CGRect(x: stopListWidth, y: tableFrame.origin.y, width: VectorTable.TIME_WIDTH, height: tableFrame.height)
        tripCollection = TripCollection(stopSequence: stopSequence, rowHeights: rowHeights, tripArray: route.vectors[vectorIndex].trips, frame: tripCollectionFrame, delegate: self)
        addSubview(tripCollection.collectionView)
        
        tripCollection.collectionView.scrollToItemAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), atScrollPosition: UICollectionViewScrollPosition.None, animated: true)
        tripCollection.didScrollToTrip(0)
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: VectorTableStopCell! = tableView.dequeueReusableCellWithIdentifier(VectorTable.REUSE_ID) as? VectorTableStopCell
        if cell == nil {
            cell = VectorTableStopCell(style: UITableViewCellStyle.Value2, reuseIdentifier: VectorTable.REUSE_ID)
            
        }
        
        cell.textLabel!.numberOfLines = 0
        cell.textLabel!.lineBreakMode = .ByWordWrapping
        cell.textLabel!.attributedText = getAttributedString(stopSequence[indexPath.row].name, withFont: VectorTable.cellFont)
        if !stopInTrip[indexPath.row] {
            cell.textLabel!.textColor = UIColor.lightGrayColor()
        }
        else {
            cell.textLabel!.textColor = UIColor.blackColor()
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return stopSequence.count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return CGFloat(rowHeights[indexPath.row])
    }
    
    var totalHeight: Double {
        var result: Double = 0.0
        for stop in stopSequence {
            let h: Double = Double(getLabelHeight(stop.name, VectorTable.cellFont, stopListWidth - VectorTable.PADDING_PX))
            result += h + Double(VectorTable.CELL_HEIGHT_PADDING)
        }
        return result
    }
    
    
    // MARK - TripCollectionDelegate
    
    func didScrollToTrip(t: Trip)  {
        stopInTrip = [Bool](count: stopSequence.count, repeatedValue: false)
        for (var i=0; i < stopSequence.count; ++i) {
            let id = stopSequence[i].id
            for stopTime in t.stops {
                if stopTime.id == id {
                    stopInTrip[i] = true
                    break
                }
            }
        }
        stopTable.reloadData()
    }
}
