//
//  DestinationViewController.swift
//  Vineyard Bus and Ferry
//
//  Created by Fred Hewett on 3/18/15.
//  Copyright (c) 2015 Frederick Hewett. All rights reserved.
//

import UIKit

class DestinationViewController: UIViewController {
    
    // values set in IB
    var responsibleForInit: Bool = false
    var transitMode: String!
    var itemName: String!
    var listSegue: String!
    var scheduleLoaded: Bool = false

    var destinations: [String]!
    var destinationToDisplay: Int?
    var scheduleIsReady: Bool = false
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scheduleIsReady = false

        loadScheduleForView() { (success: Bool) in
            if (success) {
                self.scheduleIsReady = true
                var destSet = [String: Bool]()
                
                if let sched = AppDelegate.theScheduleManager.scheduleForMode(self.transitMode) {
                    for a in sched.agencies {
                        var theseDests = AppDelegate.theScheduleManager.getRouteDestinationsForAgency(a.id)
                        for d in theseDests {
                            destSet[d] = true
                        }
                    }
                    
                    self.destinations = [String]()
                    for k in destSet.keys {
                        self.destinations.append(k)
                    }
                    self.destinations.sort() {$0 < $1}
                }
                self.tableView.dataSource = self
                self.tableView.delegate = self
                dispatch_async(dispatch_get_main_queue()) {
                    self.tableView.reloadData()
                }
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupTableFrame()
    }
    
    func setupTableFrame() {
        var frame = CGRect(x: CGFloat(0.0), y: 0.0, width: view.frame.width, height: view.frame.height)
        tableView.frame = frame
    }

    func loadScheduleForView(completionHandler: (success: Bool) -> Void) {
        
        let moc = (UIApplication.sharedApplication().delegate as AppDelegate).managedObjectContext!

        AppDelegate.theScheduleManager.acquireSchedule(forMode: transitMode, moc: moc) { (s: Schedule?) in
            if s != nil {
                completionHandler(success: true)
            }
            else {
                Logger.log(fromSource: self, level: .ERROR, message: "Failed to load schedule for mode \(self.transitMode)")
                completionHandler(success: false)
                return
            }
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let segId = segue.identifier {
            if segId == listSegue && destinationToDisplay != nil {
                
                if let listVC = (segue.destinationViewController as? UINavigationController)?.viewControllers[0] as? RouteListViewController? {
                    let s = AppDelegate.theScheduleManager.scheduleForMode(transitMode)
                    if destinationToDisplay == 0 {
                        // all routes
                        listVC!.routes = s!.routes
                    }
                    else {
                        let dest = destinations[destinationToDisplay!-1]
                        listVC!.routes = AppDelegate.theScheduleManager.getRoutesForDestination(dest, forSchedule: s!)
                    }
                    
                }
            }
        }
    }
}


extension DestinationViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if !scheduleIsReady {
            Logger.log(fromSource: self, level: .INFO, message: "Called for row count, but data is not ready")
            return 0
        }

        return destinations.count + 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("destinationCell", forIndexPath: indexPath) as UITableViewCell
        
        var labelText = ""
        if indexPath.row == 0 {
            labelText = "All routes"
        }
        else {
            labelText = itemName + " to " + destinations[indexPath.row - 1]
        }
        
        cell.textLabel!.text = labelText
        
        return cell
    }
    
    func  tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        destinationToDisplay = indexPath.row
        performSegueWithIdentifier(self.listSegue, sender: self.tableView);
    }
}



