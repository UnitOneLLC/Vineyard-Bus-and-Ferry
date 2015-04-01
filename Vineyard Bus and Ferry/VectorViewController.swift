//
//  VectorViewController.swift
//  Vineyard Bus and Ferry
//
//  Created by Fred Hewett on 3/23/15.
//  Copyright (c) 2015 Frederick Hewett. All rights reserved.
//

import UIKit

class VectorViewController: UIViewController, DaySelectionControlDelegate, VectorTableDelegate {
    
    let SCHED_FRACTION: Double = 0.98
    let VERT_OFFSET_FOR_NAV: CGFloat = 80.0
    let DAY_SELECT_WIDTH: CGFloat = 230.0
    let SMALL_PAD: CGFloat = 10.0
    let TITLE_FONT_SIZE: CGFloat = 19.0
    
    // set from segue
    var route: Route!
    var vectorIndex: Int!
    
    @IBOutlet var frameView: UIView!
    @IBOutlet weak var routeTitleVConstraint: NSLayoutConstraint!
    @IBOutlet weak var routeTitleLabel: UILabel!
    @IBOutlet weak var reverseRouteButton: UIButton!
    @IBOutlet weak var betweenLabelAndReverseButtonConstraint: NSLayoutConstraint!
    
    var schedBox: UIScrollView!
    var vectorTable: VectorTable!
    var stopSelected: Stop?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createSubViews()
    }
    
    override func viewDidAppear(animated: Bool) {
        vectorTable.tripCollection.scrollToCurrent()
    }
    
    override func viewDidLayoutSubviews() {
        adjustHeaderLabelAndButton()
    }
    
    func createSubViews() {
        let w: Double = Double(frameView.frame.size.width),
            h: Double = SCHED_FRACTION * (Double(frameView.frame.size.height) - 112.0)
        
        let daySelect = DaySelectionControl(width: DAY_SELECT_WIDTH)
        var dayFrame = daySelect.frame
        dayFrame.origin.y = VERT_OFFSET_FOR_NAV + routeTitleVConstraint.constant + SMALL_PAD
        dayFrame = hCenterInFrame(frameToCenter: dayFrame, container: frameView.frame)
        daySelect.frame = dayFrame
        daySelect.delegate = self
        frameView.addSubview(daySelect)
        daySelect.selectDayAtIndex(ScheduleManager.getDayOfWeekIndex(forDate: NSDate()))
        
        let sizeSched = CGSize(width: w, height: h)

        let schedOffsetY = dayFrame.origin.y + dayFrame.height
        schedBox = UIScrollView(frame: CGRect(origin: CGPoint(x: 0.0, y: schedOffsetY), size:sizeSched))
        schedBox.scrollEnabled = true

        frameView.addSubview(schedBox)
        

        let vtFrame = CGRect(x: 0.0, y: 0.0, width: schedBox.frame.width, height: 0.0)
        vectorTable = VectorTable(frame: vtFrame, route: route, vectorIndex: vectorIndex)
        vectorTable.delegate = self
        vectorTable(route, vectorIndex: vectorIndex, stop: nil)
        schedBox.addSubview(vectorTable)
        vectorTable.scroller = schedBox
        vectorTable.resetTripCollection()
        setRouteReverseButton()
    }
    
    @IBAction func didPressReverseRoute(sender: AnyObject) {
        if route.vectors.count > 0 {
            if vectorIndex == 0 {
                vectorTable.setVector(forRoute: route, vectorIndex: 1)
            }
            else if vectorIndex == 1 {
                vectorTable.setVector(forRoute: route, vectorIndex: 0)
            }
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == nil {
            Logger.log(fromSource: self, level: .ERROR, message: "missing segue id")
            return
        }
        let segId = segue.identifier!
        
        if segId == "showMap" {
            if vectorIndex == nil || route == nil {
                Logger.log(fromSource: self, level: .ERROR, message: "No route selection in segue")
                return
            }
            
            if let mapVC = (segue.destinationViewController as? UINavigationController)?.viewControllers[0] as? MapViewController? {
                mapVC!.schedule = AppDelegate.theScheduleManager.scheduleForAgency(route.agency)!
                mapVC!.route = self.route
                mapVC!.vectorIndex = self.vectorIndex
                mapVC!.targetStop = self.stopSelected
                self.stopSelected = nil
            }
        }
    }
    
    
    @IBAction func showMap(sender: AnyObject) {
        performSegueWithIdentifier("showMap", sender: self)
    }
    
    
    func setRouteReverseButton() {
        if route.vectors.count > 1 {
            reverseRouteButton.hidden = false
        }
        else {
            reverseRouteButton.hidden = true
        }
    }
    
    // MARK -- DaySelectionControlDelegate
    
    func daySelection(selectedDayIndex index: Int) {
        let SECONDS_PER_DAY = 86400
        
        // reset the effective date
        let today = NSDate()
        let appDel = UIApplication.sharedApplication().delegate as AppDelegate
        
        let indexToday = ScheduleManager.getDayOfWeekIndex(forDate: today)
        if index == indexToday {
            appDel.effectiveDate = NSDate()
        }
        else {
            var offset: Int
            if index > indexToday {
                offset = index - indexToday
            }
            else {
                offset = index - indexToday + 7
            }
            
            let offsetInterval = NSTimeInterval(offset * SECONDS_PER_DAY)
            
            appDel.effectiveDate = NSDate(timeInterval: offsetInterval, sinceDate: today)
            vectorTable.resetTripCollection()
        }
    }
    
    // MARK -- VectorTableDelegate
    
    func vectorTable(routeSelected: Route, vectorIndex: Int, stop: Stop?) {
        if stop != nil {
            stopSelected = stop
            performSegueWithIdentifier("showMap", sender: self)
        }
        else {
            self.route = routeSelected
            self.vectorIndex = vectorIndex
            
            var labelText: String
            if routeSelected.shortName != nil && !routeSelected.shortName!.isEmpty {
                labelText = "Route " + routeSelected.shortName! + " to " + routeSelected.vectors[vectorIndex].destination
            }
            else {
                labelText = "To " + routeSelected.vectors[vectorIndex].destination
            }
            
            routeTitleLabel.attributedText = getAttributedString(labelText, withFont: UIFont.boldSystemFontOfSize(TITLE_FONT_SIZE))
            setRouteReverseButton()
            schedBox.scrollRectToVisible(CGRect(x:0.0, y:0.0, width: schedBox.frame.width, height: 1.0), animated: true)
        }
    }
    
    func vectorTable(scrolledToTripIndex index: Int) {
    }

    
    // MARK - utilities
    
    func adjustHeaderLabelAndButton() {
        let w = routeTitleLabel.frame.width +
            betweenLabelAndReverseButtonConstraint.constant +
            reverseRouteButton.frame.width
        
        let margin = (frameView.frame.width - w)/2.0
        
        var rect = routeTitleLabel.frame
        rect.origin.x = margin
        routeTitleLabel.frame = rect
        
        rect = reverseRouteButton.frame
        rect.origin.x = routeTitleLabel.frame.origin.x +
            routeTitleLabel.frame.width +
            betweenLabelAndReverseButtonConstraint.constant
        reverseRouteButton.frame = rect
    }
}
