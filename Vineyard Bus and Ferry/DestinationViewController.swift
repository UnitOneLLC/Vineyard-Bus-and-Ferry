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
    var agencyId: String!
    var mode: String!
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
                
                if let sched = AppDelegate.theScheduleManager.scheduleForAgency(self.agencyId) {
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
    
    func loadScheduleForView(completionHandler: (success: Bool) -> Void) {
        
        let moc = (UIApplication.sharedApplication().delegate as AppDelegate).managedObjectContext!

        AppDelegate.theScheduleManager.acquireSchedule(forAgency: agencyId, moc: moc) { (s: Schedule?) in
            if s != nil {
                if AppDelegate.theScheduleManager.isScheduleCurrent(s!) {
                    completionHandler(success: true)
                }
                else {
                    Logger.log(fromSource: self, level: .ERROR, message: "error: no current service in schedule")
                    completionHandler(success: false)
                    return
                }
            }
            else {
                Logger.log(fromSource: self, level: .ERROR, message: "failed to load")
                completionHandler(success: false)
                return
            }
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let segId = segue.identifier {
            if segId == listSegue && destinationToDisplay != nil {
                
                if let listVC = (segue.destinationViewController as? UINavigationController)?.viewControllers[0] as? RouteListViewController? {
                    let s = AppDelegate.theScheduleManager.scheduleForAgency(agencyId)
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


extension DestinationViewController: UITableViewDataSource {
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
}

extension DestinationViewController: UITableViewDelegate {
    func  tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        destinationToDisplay = indexPath.row
        dispatch_async(dispatch_get_main_queue(), {
            self.performSegueWithIdentifier(self.listSegue, sender: self.tableView);
        })

    }
}



