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

    var destinations: [String]!
    var destinationToDisplay: Int?
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if responsibleForInit  {
            appInit()
        }
        
        destinations = AppDelegate.theScheduleManager.getRouteDestinationsForAgency(agencyId)
        destinations.sort() {$0 < $1}
        tableView.dataSource = self
        tableView.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func appInit() {
        
        let moc = (UIApplication.sharedApplication().delegate as AppDelegate).managedObjectContext!

        AppDelegate.theScheduleManager.acquireSchedule(forAgency: agencyId, moc: moc) { (s: Schedule?) in
            if s != nil {
                
                if AppDelegate.theScheduleManager.isScheduleCurrent(s!) {
                    Logger.log(fromSource: self, level: .INFO, message: "schedule load: \(s!.agencies[0].name)")
                }
                else {
                    Logger.log(fromSource: self, level: .ERROR, message: "error: no current service in schedule")
                }
            }
            else {
                Logger.log(fromSource: self, level: .ERROR, message: "failed to load")
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



