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
    let PADDING_PX: CGFloat = 20.0
    let CELL_HEIGHT_PADDING: Double = 10.0
    
    let schedule: Schedule!
    var itemText: (single: String, plural: String)!
    var connectionRouteTable: UITableView!
    var connectionTimeTable: UITableView!
    var delegate: ConnectionTableDelegate?
    var rowHeights: [Double]!
    var _currentTrip: Trip?
    
    init(schedule: Schedule, text: (single: String, plural: String)) {
        super.init()
        self.schedule = schedule
        itemText = text
    
        connectionRouteTable = UITableView()
        connectionRouteTable.separatorStyle = UITableViewCellSeparatorStyle.None
        connectionRouteTable.registerClass(VectorTableStopCell.self, forCellReuseIdentifier: ROUTE_TABLE_CELL_ID)
        connectionRouteTable.scrollEnabled = false
        connectionRouteTable.dataSource = self
        connectionRouteTable.delegate = self
        
        connectionTimeTable = UITableView()
        connectionTimeTable.separatorStyle = UITableViewCellSeparatorStyle.None
        connectionTimeTable.registerClass(UITableViewCell.self, forCellReuseIdentifier: TIME_TABLE_CELL_ID)
        connectionTimeTable.scrollEnabled = false
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
            
            var totalHeight: Double = 0.0
            rowHeights = [Double]()
            for c in _currentTrip!.connections {
                let labelText = getTextForConnection(c)
                let font = UIFont.systemFontOfSize(VectorTable.CELL_FONT_SIZE)
                let h = Double(getLabelHeight(labelText, font, connectionRouteTable.frame.width - PADDING_PX)) + CELL_HEIGHT_PADDING
                rowHeights.append(h)
                totalHeight += h
            }
            
            var frame: CGRect
            var height = CGFloat(totalHeight)

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
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return CGFloat(rowHeights[indexPath.row])
    }
    
    func getTextForConnection(connection: Connection) -> String {
        var labelText = itemText.single + " " + connection.shortName
        if !connection.headSign.isEmpty {
            labelText += " to " + connection.headSign
        }
        return labelText
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var connection: Connection?
        if _currentTrip != nil {
            connection = _currentTrip!.connections[indexPath.row]
        }
        
        if tableView === connectionTimeTable {
            var cell = tableView.dequeueReusableCellWithIdentifier(TIME_TABLE_CELL_ID, forIndexPath: indexPath) as UITableViewCell
            if connection != nil {
                let labelText = ScheduleManager.formatTimeOfDay(connection!.time)
                cell.textLabel!.attributedText = getAttributedString(labelText, withFont: VectorTable.cellFont)
            }
            return cell
        }
        else {
            var cell = tableView.dequeueReusableCellWithIdentifier(ROUTE_TABLE_CELL_ID, forIndexPath: indexPath) as VectorTableStopCell
            if connection != nil  {
                let labelText = getTextForConnection(connection!)
                cell.textLabel!.numberOfLines = 0
                cell.textLabel!.lineBreakMode = .ByWordWrapping
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
