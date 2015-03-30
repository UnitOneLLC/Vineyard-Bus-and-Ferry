//
//  ConnectionTable.swift
//  Vineyard Bus and Ferry
//
//  Created by Fred Hewett on 3/28/15.
//  Copyright (c) 2015 Frederick Hewett. All rights reserved.
//

import UIKit

protocol ConnectionTableDelegate {
    func connectionTable(didSelectConnection c: Connection)
}


class ConnectionTable: NSObject, UITableViewDelegate, UITableViewDataSource {

    let ROUTE_TABLE_CELL_ID = "tripRouteCell"
    let TIME_TABLE_CELL_ID  = "tripTimeCell"
    let ROW_HEIGHT: CGFloat = 32.0
    let schedule: Schedule!
    var connectionRouteTable: UITableView!
    var connectionTimeTable: UITableView!
    var delegate: ConnectionTableDelegate?
    
    var _currentTrip: Trip?
    
    init(schedule: Schedule) {
        super.init()
        self.schedule = schedule
    
        connectionRouteTable = UITableView()
        connectionRouteTable.separatorStyle = UITableViewCellSeparatorStyle.None
        connectionRouteTable.registerClass(VectorTableStopCell.self, forCellReuseIdentifier: ROUTE_TABLE_CELL_ID)
        connectionRouteTable.scrollEnabled = false
        connectionRouteTable.rowHeight = ROW_HEIGHT
        connectionRouteTable.dataSource = self
        connectionRouteTable.delegate = self
        
        connectionTimeTable = UITableView()
        connectionTimeTable.separatorStyle = UITableViewCellSeparatorStyle.None
        connectionTimeTable.registerClass(UITableViewCell.self, forCellReuseIdentifier: TIME_TABLE_CELL_ID)
        connectionTimeTable.scrollEnabled = false
        connectionTimeTable.rowHeight = ROW_HEIGHT
        connectionTimeTable.dataSource = self
        connectionTimeTable.delegate = self
    }
    
    var currentTrip: Trip? {
        get {
            return _currentTrip
        }
        set(t) {
            _currentTrip = t
            
            adjustTableHeights()
            connectionRouteTable.reloadData()
            connectionTimeTable.reloadData()
        }
    }
    
    func adjustTableHeights() {
        if currentTrip != nil {
            var frame: CGRect
            var height = ROW_HEIGHT * CGFloat(currentTrip!.connections.count)

            frame = connectionTimeTable.frame
            frame.size.height = height
            connectionTimeTable.frame = frame
            println("time table frame \(connectionTimeTable.frame)")
            
            frame = connectionRouteTable.frame
            frame.size.height = height
            connectionRouteTable.frame = frame
            println("route table frame \(connectionRouteTable.frame)")
        }
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if currentTrip != nil {
            return currentTrip!.connections.count
        }
        else {
            return 0
        }
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var connection: Connection?
        if _currentTrip != nil {
            connection = _currentTrip!.connections[indexPath.row]
        }
        
        if tableView === connectionTimeTable {
            var cell = tableView.dequeueReusableCellWithIdentifier(TIME_TABLE_CELL_ID, forIndexPath: indexPath) as UITableViewCell
            if connection != nil {
                let labelText = AppDelegate.theScheduleManager.formatTimeOfDay(connection!.time)
                cell.textLabel!.attributedText = getAttributedString(labelText, withFont: VectorTable.cellFont)
            }
            return cell
        }
        else {
            var cell = tableView.dequeueReusableCellWithIdentifier(ROUTE_TABLE_CELL_ID, forIndexPath: indexPath) as VectorTableStopCell
            if connection != nil  {
                var labelText = "Route " + connection!.shortName
                if !connection!.headSign.isEmpty {
                    labelText += " to " + connection!.headSign
                }
                cell.textLabel!.attributedText = getAttributedString(labelText, withFont: VectorTable.cellFont)
            }
            return cell
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if delegate != nil && _currentTrip != nil {
            delegate?.connectionTable(didSelectConnection: _currentTrip!.connections[indexPath.row])
        }
    }
}
