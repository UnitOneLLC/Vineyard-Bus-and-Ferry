//
//  RouteListViewController.swift
//  Vineyard Bus and Ferry
//
//  Created by Fred Hewett on 3/21/15.
//  Copyright (c) 2015 Frederick Hewett. All rights reserved.
//

import UIKit

class RouteListViewController: IAdBannerViewController {
        
    let SECTION_FONT_SIZE: CGFloat = 15.0
    let SECTION_VPAD: CGFloat = 3.0
    let HMARGIN: CGFloat = 10.0
    
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
        if indexPath.section < sortedKeys.count {
            if let routeSet = groups[sortedKeys[indexPath.section]] {
                let r = routeSet[indexPath.row]
                cell.initialize(route: r, width: tableView.frame.size.width)
            }
        }

        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section < sortedKeys.count {
            if let group = groups[sortedKeys[section]] {
                return group.count
            }
        }

        return 0
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if let agency = AppDelegate.theScheduleManager.getAgencyById(sortedKeys[section]) {
            let text = agency.name
            let font = UIFont.boldSystemFontOfSize(SECTION_FONT_SIZE)
            let height = getLabelHeight(text, font, tableView.frame.width-HMARGIN) + 2*SECTION_VPAD
            println("the height of the header for section \(section) is \(height)")
            return height
        }
        else {
            return 0.1
        }
    }
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.1
    }
    
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let agency = AppDelegate.theScheduleManager.getAgencyById(sortedKeys[section]) {
            let text = agency.name
            let font = UIFont.boldSystemFontOfSize(SECTION_FONT_SIZE)
            var headframe = tableView.frame
            let height = getLabelHeight(text, font, headframe.width-HMARGIN)
            headframe.size.height = height
            let headerView = UIView(frame: headframe)
            headframe.origin.y += SECTION_VPAD
            headframe.size.height -= SECTION_VPAD
            var headerLbl = UILabel(frame: headframe)
            headerLbl.textAlignment = NSTextAlignment.Center
            headerLbl.numberOfLines = 0
            headerLbl.lineBreakMode = .ByWordWrapping
            headerLbl.textColor = UIColor.whiteColor()
            headerLbl.attributedText = getAttributedString(text, withFont: font)
            headerView.addSubview(headerLbl)
            return headerView
        }
        return nil
    }
    
    func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView(frame: CGRect(x:0, y:0, width: 0, height: 0))
    }
}

extension RouteListViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let h = RouteListCell.getHeight(routes![indexPath.row], width: tableView.frame.size.width)
        return h
    }
}

