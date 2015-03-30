//
//  VectorViewController.swift
//  Vineyard Bus and Ferry
//
//  Created by Fred Hewett on 3/23/15.
//  Copyright (c) 2015 Frederick Hewett. All rights reserved.
//

import UIKit
import MapKit

class VectorViewController: UIViewController, DaySelectionControlDelegate, VectorTableDelegate {
    
    let SCHED_FRACTION: Double = 0.5
    let VERT_OFFSET_FOR_NAV: CGFloat = 80.0
    let DAY_SELECT_WIDTH: CGFloat = 230.0
    let SMALL_PAD: CGFloat = 15.0
    let TITLE_FONT_SIZE: CGFloat = 19.0
    
    // set from segue
    var route: Route!
    var vectorIndex: Int!
    
    @IBOutlet var frameView: UIView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var routeTitleVConstraint: NSLayoutConstraint!
    @IBOutlet weak var routeTitleLabel: UILabel!
    
    var schedBox: UIScrollView!
    var vectorTable: VectorTable!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createSubViews()
    }
    
    override func viewDidAppear(animated: Bool) {
        dispatch_after(DISPATCH_TIME_NOW, dispatch_get_main_queue() ) {
//            self.vectorTable.tripCollection.collectionView.scrollToItemAtIndexPath(NSIndexPath(forRow: 3, inSection: 0), atScrollPosition: UICollectionViewScrollPosition.None, animated: true)
//            self.vectorTable.tripCollection.didScrollToTrip(3)
        }
    }
    
    override func viewDidLayoutSubviews() {

        var sizeMap = schedBox.frame.size
        sizeMap.height = frameView.frame.height - schedBox.frame.size.height

        let initialPoint = CLLocationCoordinate2D(latitude: 41.38764, longitude: -70.6)
        var span  = MKCoordinateSpanMake(0.1, 0.1);
        var region = MKCoordinateRegion(center: initialPoint, span: span)
        mapView.setRegion(region, animated: true)
        mapView.frame = CGRect(origin: CGPoint(x: 0.0, y: schedBox.frame.size.height), size: sizeMap)
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
        
        mapView.autoresizingMask = UIViewAutoresizing.FlexibleHeight

        let vtFrame = CGRect(x: 0.0, y: 0.0, width: schedBox.frame.width, height: 0.0)
        vectorTable = VectorTable(frame: vtFrame, route: route, vectorIndex: vectorIndex)
        vectorTable.delegate = self
        vectorTable(route, vectorIndex: vectorIndex)
        schedBox.addSubview(vectorTable)
        vectorTable.scroller = schedBox
        vectorTable.resetTripCollection()
    }
    
    func vectorTable(routeSelected: Route, vectorIndex: Int) {
        var labelText: String
        if routeSelected.shortName != nil && !routeSelected.shortName!.isEmpty {
            labelText = "Route " + routeSelected.shortName! + " to " + routeSelected.vectors[vectorIndex].destination
        }
        else {
            labelText = "To " + routeSelected.vectors[vectorIndex].destination
        }
        routeTitleLabel.attributedText = getAttributedString(labelText, withFont: UIFont.boldSystemFontOfSize(TITLE_FONT_SIZE))
    }
    
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
}
