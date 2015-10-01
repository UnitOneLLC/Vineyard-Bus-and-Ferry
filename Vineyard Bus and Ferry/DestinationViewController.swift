//
//  DestinationViewController.swift
//  Vineyard Bus and Ferry
//
//  Created by Fred Hewett on 3/18/15.
//  Copyright (c) 2015 Frederick Hewett. All rights reserved.
//

import UIKit

class DestinationViewController: UIViewController {
    let ROW_HEIGHT: CGFloat = 44.0
    let HEADER_HEIGHT: CGFloat = 22.0
    
    // values set in IB
    var responsibleForInit: Bool = false
    var transitMode: String!
    var itemNameSingular: String!
    var itemNamePlural: String!
    var listSegue: String!

    var destinations: [String]!
    var destinationToDisplay: Int?
    var scheduleIsReady: Bool = false
    var activity: UIActivityIndicatorView!
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scheduleIsReady = false
        startLoadingIndicator()

        loadScheduleForView() { (success: Bool) in
            if (success) {
                self.scheduleIsReady = true
                var destSet = [String: Bool]()
                let effDate = (UIApplication.sharedApplication().delegate as! AppDelegate).effectiveDate
                
                if let sched = AppDelegate.theScheduleManager.scheduleForMode(self.transitMode) {
                    for a in sched.agencies {
                        let theseDests = AppDelegate.theScheduleManager.getRouteDestinationsForAgency(a.id, effectiveDate: effDate)
                        for d in theseDests {
                            destSet[d] = true
                        }
                    }
                    
                    self.destinations = [String]()
                    for k in destSet.keys {
                        self.destinations.append(k)
                    }
                    self.destinations.sortInPlace() {$0 < $1}
                }
                self.tableView.rowHeight = self.ROW_HEIGHT
                self.tableView.dataSource = self
                self.tableView.delegate = self
                dispatch_async(dispatch_get_main_queue()) {
                    self.tableView.reloadData()
                    self.stopLoadingIndicator()
                    self.welcome()
                }
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func startLoadingIndicator() {
        let ACTIVITY_WIDTH: CGFloat = 50.0
        if activity == nil {
            let f = CGRect(x: (view.frame.width-ACTIVITY_WIDTH)/2, y: view.frame.height/3, width: ACTIVITY_WIDTH, height: ACTIVITY_WIDTH)
            activity = UIActivityIndicatorView(frame: f)
            view.addSubview(activity)
        }
        activity.startAnimating()
    }
    
    func stopLoadingIndicator() {
        if activity != nil {
            activity.stopAnimating()
        }
    }

    func loadScheduleForView(completionHandler: (success: Bool) -> Void) {
        
        let moc = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext

        AppDelegate.theScheduleManager.acquireSchedule(forMode: transitMode, vc: self, moc: moc) { (s: Schedule?) in
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
                    listVC!.itemText = (single: itemNameSingular, plural: itemNamePlural)
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
    
    func welcome() {
        let moc = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
        var alreadyDone: NSNumber? = AppDelegate.theSettingsManager.getSetting(parameter: "welcomeIssued", moc: moc)
        if alreadyDone == 0 {
            alreadyDone = 1
            AppDelegate.theSettingsManager.setAppParameter(parameter: "welcomeIssued", value: alreadyDone!, moc: moc)
            simpleAlert("Welcome", message: AppDelegate.welcomeText, controller: self)
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
        let cell = tableView.dequeueReusableCellWithIdentifier("destinationCell", forIndexPath: indexPath) 
        
        var labelText = ""
        if indexPath.row == 0 {
            labelText = "All " + itemNamePlural
        }
        else {
            labelText = itemNamePlural + " to " + destinations[indexPath.row - 1]
        }
        
        cell.textLabel!.text = labelText
        
        return cell
    }
    
    func  tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        destinationToDisplay = indexPath.row
        performSegueWithIdentifier(self.listSegue, sender: self.tableView);
    }
}



