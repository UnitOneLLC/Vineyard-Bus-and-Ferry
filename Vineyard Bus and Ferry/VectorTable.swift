//
//  VectorTable.swift
//  Vineyard Bus and Ferry
//
//  Created by Fred Hewett on 3/25/15.
//  Copyright (c) 2015 Frederick Hewett. All rights reserved.
//

import UIKit

protocol VectorTableDelegate {
    func vectorTable(routeSelected: Route, vectorIndex: Int)
}


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


class VectorTable : UIView, UITableViewDataSource, UITableViewDelegate, TripCollectionDelegate,
                    ConnectionTableDelegate, TripPagerDelegate {
    class var REUSE_ID: String { return "vectorTableStopCell" }
    class var CELL_FONT_SIZE: CGFloat { return 17.0 }
    class var TIME_WIDTH: CGFloat { return 124.0 }
    class var STOPLIST_RATIO: CGFloat { return 0.70 }
    
    let CELL_HEIGHT_PADDING: CGFloat = 10.0
    let PADDING_PX: CGFloat = 15.0
    
    class var cellFont: UIFont {
        return UIFont.systemFontOfSize(CELL_FONT_SIZE)
    }
    
    var stopTable: UITableView!
    var schedule: Schedule!
    var vectorIndex: Int!
    var route: Route!
    var stopSequence: [Stop]!
    var cellText: [String]!
    var stopListWidth: CGFloat!
    var tripCollection: TripCollection!
    var rowHeights: [Double]!
    var stopInTrip: [Bool]!
    var tableFrame: CGRect!
    var connectionTable: ConnectionTable!
    var scroller: UIScrollView?
    var delegate: VectorTableDelegate?
    
    init(frame: CGRect, route: Route, vectorIndex: Int) {
        super.init(frame: frame)
        stopListWidth = frame.width * VectorTable.STOPLIST_RATIO
        
        setVector(forRoute: route, vectorIndex: vectorIndex)
        
        tableFrame = CGRect(x: 0.0, y: 0.0, width: stopListWidth, height: CGFloat(totalHeight))
        stopTable = UITableView(frame: tableFrame)
        stopTable.separatorStyle = UITableViewCellSeparatorStyle.None
        stopTable.registerClass(VectorTableStopCell.self, forCellReuseIdentifier: VectorTable.REUSE_ID)
        stopTable.scrollEnabled = false
        stopTable.dataSource = self
        stopTable.delegate = self
        addSubview(stopTable)
        
        connectionTable = ConnectionTable(schedule: schedule)
        connectionTable.delegate = self
        addSubview(connectionTable.connectionRouteTable)
        addSubview(connectionTable.connectionTimeTable)
    }
    
    func setVector(forRoute route: Route, vectorIndex: Int) {
        let isInitial = self.route == nil
        
        if route.vectors.count <= vectorIndex {
            Logger.log(fromSource: self, level: .ERROR, message: "Bad vector index \(vectorIndex) for route \(route.id)")
            return
        }
        self.vectorIndex = vectorIndex
        self.schedule = AppDelegate.theScheduleManager.scheduleForAgency(route.agency)!
        self.route = route
        self.stopSequence = AppDelegate.theScheduleManager.stopSequenceForVector(route.vectors[vectorIndex], inSchedule: self.schedule)
        rowHeights = [Double]()
        for stop in stopSequence {
            let h: Double = Double(getLabelHeight(stop.name, UIFont.systemFontOfSize(VectorTable.CELL_FONT_SIZE), stopListWidth - PADDING_PX)) + Double(CELL_HEIGHT_PADDING)
            rowHeights.append(h)
        }
        
        if !isInitial {
            tableFrame = CGRect(x: 0.0, y: 0.0, width: stopListWidth, height: CGFloat(totalHeight))
            stopTable.frame = tableFrame
            resetTripCollection()
            stopTable.reloadData()
        }
        if delegate != nil {
            delegate!.vectorTable(route, vectorIndex: vectorIndex)
        }
    }
    
    
    func resetTripCollection() {
        if tripCollection != nil && tripCollection.collectionView != nil {
            tripCollection.collectionView.removeFromSuperview()
        }
        let tripCollectionFrame = CGRect(x: stopListWidth, y: 0.0, width: VectorTable.TIME_WIDTH, height: tableFrame.height)
        let effectiveDate = (UIApplication.sharedApplication().delegate as AppDelegate).effectiveDate
        let effectiveTrips = AppDelegate.theScheduleManager.filterTripsForDate(effectiveDate, trips: route.vectors[vectorIndex].trips, inSchedule: schedule)
        tripCollection = TripCollection(stopSequence: stopSequence, rowHeights: rowHeights, tripArray: effectiveTrips, frame: tripCollectionFrame)
        tripCollection.delegate = self
        addSubview(tripCollection.collectionView)

        var vecFrame = tableFrame
        vecFrame.origin.y = vecFrame.origin.y + vecFrame.size.height + 10.0
        connectionTable.connectionRouteTable.frame = vecFrame
        
        var cvFrame = tripCollection.collectionView.frame
        cvFrame.origin.y = cvFrame.origin.y + cvFrame.size.height + 10.0
        connectionTable.connectionTimeTable.frame = cvFrame
        
        tripCollection.collectionView.scrollToItemAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), atScrollPosition: UICollectionViewScrollPosition.None, animated: true)
        
        var selfSize = frame.size
        selfSize.height = stopTable!.frame.height + connectionTable.connectionRouteTable.frame.height
        println("vector table height = \(selfSize.height)")
        frame.size = selfSize
        
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
            let h: Double = Double(getLabelHeight(stop.name, VectorTable.cellFont, stopListWidth - PADDING_PX))
            result += h + Double(CELL_HEIGHT_PADDING)
        }
        return result
    }
    
    
    // MARK - TripCollectionDelegate
    
    func tripCollection(didScrollToTrip: Trip) {
        stopInTrip = [Bool](count: stopSequence.count, repeatedValue: false)
        for (var i=0; i < stopSequence.count; ++i) {
            let id = stopSequence[i].id
            for stopTime in didScrollToTrip.stops {
                if stopTime.id == id {
                    stopInTrip[i] = true
                    break
                }
            }
        }
        stopTable.reloadData()
        connectionTable.currentTrip = didScrollToTrip
        
        
        if scroller != nil {
            var h = self.frame.height + connectionTable.connectionRouteTable.frame.height
            println("set content size to \(h)")
            scroller!.contentSize = CGSize(width: scroller!.frame.width, height: h)
        }
        
    }
    
    // MARK - ConnectionTableDelegate
    
    func connectionTable(didSelectConnection c: Connection) {
        if let r = AppDelegate.theScheduleManager.getRoute(fromSchedule: schedule, withId: c.routeId) {
            for (var index=0; index < r.vectors.count; ++index) {
                if r.vectors[index].destination == c.headSign {
                    setVector(forRoute: r, vectorIndex: index)
                    break
                }
            }
        }
    }
    
    // MARK - TripPagerDelegate
    func tripPagerDelegate(didPressEarlier: Bool) {
        if didPressEarlier {
            tripCollection.scrollToPrev()
        }
        else {
            tripCollection.scrollToNext()
        }
    }
}
