//
//  RouteListViewController.swift
//  Vineyard Bus and Ferry
//
//  Created by Fred Hewett on 3/21/15.
//  Copyright (c) 2015 Frederick Hewett. All rights reserved.
//

import UIKit

class RouteListViewController: UIViewController {
    var routes: [Route]?
    var groups: [String: [Route]]!
    var sortedKeys: [String]!
    
    // set by cell on select
    var selectedRoute: Route!
    var selectedVectorIndex: Int!
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        initializeGroups()
    }
    
    func initializeGroups() {
        groups = [String: [Route]]()
        sortedKeys = [String]()
        
        if routes != nil {

            for r in routes! {
                if groups[r.agency] == nil {
                    groups[r.agency] = [Route]()
                    sortedKeys.append(r.agency)
                }
                groups[r.agency]?.append(r)
            }
            sortedKeys.sort() {$0 < $1}
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == nil {
            Logger.log(fromSource: self, level: .ERROR, message: "missing segue id")
            return
        }
        let segId = segue.identifier!
        
        if segId == "showVector" {
            if selectedVectorIndex == nil || selectedRoute == nil {
                Logger.log(fromSource: self, level: .ERROR, message: "No route selection in segue")
                return
            }
            
            if let vectorVC = (segue.destinationViewController as? UINavigationController)?.viewControllers[0] as? VectorViewController? {
                vectorVC!.route = selectedRoute
                vectorVC!.vectorIndex = selectedVectorIndex
            }
        }
    }
}

extension RouteListViewController: UITableViewDataSource {
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sortedKeys.count
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let agency = AppDelegate.theScheduleManager.getAgencyById(sortedKeys[section]) {
            return agency.name
        }
        return ""
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("routeCell", forIndexPath: indexPath) as RouteListCell

        if routes != nil {
            let r = routes![indexPath.row]
            cell.initialize(route: r, width: tableView.frame.size.width)
        }

        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if routes != nil {
            return routes!.count
        }
        else {
            return 0
        }
    }
}

extension RouteListViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let h = RouteListCell.getHeight(routes![indexPath.row], width: tableView.frame.size.width)
        return h
    }
}

