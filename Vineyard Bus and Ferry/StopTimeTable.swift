//
//  StopTimeTable.swift
//  Vineyard Bus and Ferry
//
//  Created by Fred Hewett on 3/25/15.
//  Copyright (c) 2015 Frederick Hewett. All rights reserved.
//

import UIKit


class StopTimeTable: NSObject, UITableViewDataSource, UITableViewDelegate {
    class var REUSE_ID: String {return "stopTableCell"}
    let trip: Trip
    let rowHeights: [Double]
    let stopSequence: [Stop]
    
    init(stopSequence: [Stop], trip: Trip, rowHeights: [Double]) {
        self.trip = trip
        self.rowHeights = rowHeights
        self.stopSequence = stopSequence
        super.init()
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(StopTimeTable.REUSE_ID, forIndexPath: indexPath)
        
        let stopId = stopSequence[indexPath.row].id
        var found: Bool = false
        for stopTime in trip.stops {
            if stopTime.id == stopId {
                let labelText = ScheduleManager.formatTimeOfDay(stopTime.time)
                cell.textLabel!.attributedText = getAttributedString(labelText, withFont: VectorTable.cellFont)
                found = true
                break
            }
        }
        if !found {
            cell.textLabel!.text = ""
        }
        

        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return stopSequence.count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let i = indexPath.row
        if i < rowHeights.count {
            return CGFloat(rowHeights[indexPath.row])
        }
        else {
            Logger.log(fromSource: self, level: .ERROR, message: "Row index \(i) out of bounds, max expected is \(rowHeights.count-1)")
            return 0.0
        }
    }
    
    
}
