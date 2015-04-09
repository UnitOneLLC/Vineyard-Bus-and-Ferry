//
//  MapViewController.swift
//  Vineyard Bus and Ferry
//
//  Created by Fred Hewett on 3/30/15.
//  Copyright (c) 2015 Frederick Hewett. All rights reserved.
//

import UIKit
import MapKit


class StopAnnotation : NSObject, MKAnnotation {
    let stop: Stop
    
    init(stop: Stop) {
        self.stop = stop
    }
    
    // Center latitude and longitude of the annotation view.
    // The implementation of this property must be KVO compliant.
    var coordinate: CLLocationCoordinate2D {
        return stop.coord
    }
    
    // Title and subtitle for use by selection UI.
    var title: String! {
        return stop.name
    }
    
}

class MapViewController: UIViewController, MKMapViewDelegate {
    let STOP_ANNO_REUSE_ID = "map_stop_anno"
    let STOP_TABLE_REUSE_ID = "map_stop_table"
    let STOP_TABLE_FONT_SIZE: CGFloat = 13.0
    let STOP_ANNOTATION_WIDTH: CGFloat = 10.0
    let STOP_ANNOTATION_HEIGHT: CGFloat = 10.0
    let STOP_COLOR: UIColor = UIColor.darkGrayColor()
    let TIME_LABEL_FONT_SIZE: CGFloat = 14.0
    let TITLE_FONT_SIZE: CGFloat = 17.0
    let VPADDING: CGFloat = 10.0
    let FULL_ALPHA: CGFloat = 0.7
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var routeTitleLabel: UILabel!
    @IBOutlet weak var stopTimeTableView: UITableView!
    
    // set at segue
    var schedule: Schedule!
    var route: Route!
    var vectorIndex: Int!
    var targetStop: Stop?
    var stopTimes: (beforeNow: [TimeOfDay], afterNow: [TimeOfDay])!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.autoresizingMask = UIViewAutoresizing.FlexibleHeight
        mapView.delegate = self
        
        stopTimeTableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: STOP_TABLE_REUSE_ID)
        stopTimeTableView.alpha = (targetStop == nil) ? 0.0 : FULL_ALPHA
        stopTimeTableView.dataSource = self
        stopTimeTableView.delegate = self

        drawVector()
        annotateStops()
    }
    
    override func viewDidLayoutSubviews() {
        setRouteLabel()
        stackView(stopTimeTableView, positionBelow: routeTitleLabel)
        stackView(mapView, positionBelow: routeTitleLabel)
    }
    
    override func viewDidAppear(animated: Bool) {
        if targetStop != nil {
            let s = targetStop
            selectStop(s!)
            for a in mapView.annotations {
                if let stopAnno = a as? StopAnnotation {
                    if stopAnno.stop.id == s!.id {
                        mapView.selectAnnotation(stopAnno, animated: true)
                    }
                }
            }
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        targetStop = nil
    }
    
    func setRouteLabel() {
        if (!inputValid()) {
            return
        }
        
        let font = UIFont.boldSystemFontOfSize(TITLE_FONT_SIZE)
        var frame = routeTitleLabel.frame
        frame.size.width = view.frame.width
        frame.origin = CGPoint(x: 0.0, y: 75.0)
        frame.size.height = getLabelHeight(route.longName, font, frame.size.width) + VPADDING

        routeTitleLabel.frame = frame
        routeTitleLabel.textAlignment = NSTextAlignment.Center
        routeTitleLabel.numberOfLines = 0
        routeTitleLabel.lineBreakMode = .ByWordWrapping
        routeTitleLabel.attributedText = getMutableAttributedString(route.longName, withFont: font)
    }
    
    func drawVector() {
        if (!inputValid()) {
            return
        }
        
        let v = route.vectors[vectorIndex]
        setRegion(v.polyline)
        
        var coords: [CLLocationCoordinate2D] = v.polyline.coordinates
        
        var mkPoly = MKPolyline(coordinates: &coords, count: v.polyline.coordinates.count)
        mapView.addOverlay(mkPoly)
    }
    
    func getStopSequence() -> [Stop] {
        var result = [Stop]()
        if let schedule = AppDelegate.theScheduleManager.scheduleForAgency(route.agency) {
            result = AppDelegate.theScheduleManager.stopSequenceForVector(route.vectors[vectorIndex], inSchedule: schedule)
        }
        return result
    }
    
    func annotateStops() {
        let stops = getStopSequence()
        for stop in stops {
            mapView.addAnnotation(StopAnnotation(stop: stop))
        }
    }
    
    func setRegion(poly: Polyline) {
        var minLat: Double = 180.0, minLng: Double = 180.0, maxLat: Double = -180.0, maxLng = -180.0
        
        var coordList = poly.coordinates
        if poly.coordinates.count == 0 {
            let stops = getStopSequence()
            for s in stops {
                coordList.append(s.coord)
            }
        }
        for coord in coordList {
            minLat = min(minLat, coord.latitude)
            minLng = min(minLng, coord.longitude)
            maxLat = max(maxLat, coord.latitude)
            maxLng = max(maxLng, coord.longitude)
        }
        
        let span = makeSpan(maxLat-minLat, maxLng-minLng, mapView!)
        let center = CLLocationCoordinate2D(latitude: (minLat+maxLat)/2, longitude: (minLng+maxLng)/2)
        let region = MKCoordinateRegionMake(center, span)
        mapView.setRegion(region, animated: true)
    }
    
    // MARK - MKMapViewDelegate
    
    func mapView(mapView: MKMapView!, rendererForOverlay overlay: MKOverlay!) -> MKOverlayRenderer! {
        if overlay is MKPolyline {
            var pr = MKPolylineRenderer(overlay: overlay);
            pr.strokeColor = colorWithHexString(route.colorRGB!)
            pr.lineWidth = 5;
            return pr;
        }
        Logger.log(fromSource: self, level: .ERROR, message: "Unexpected call to mapView:rendererForOverlay")
        return nil
    }
    
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        if annotation is StopAnnotation {
            
            var annoView = mapView.dequeueReusableAnnotationViewWithIdentifier(STOP_ANNO_REUSE_ID)
            if annoView == nil {
                annoView = MKAnnotationView(annotation: annotation, reuseIdentifier: STOP_ANNO_REUSE_ID)
            }
            annoView.frame = CGRect(x: 0.0, y: 0.0, width: STOP_ANNOTATION_WIDTH, height: STOP_ANNOTATION_HEIGHT)
            annoView!.annotation = annotation
            annoView.backgroundColor = STOP_COLOR
            annoView.canShowCallout = true
            return annoView
        }
        
        return nil
    }
    
    func selectStop(stop: Stop) {
        targetStop = stop
        UIView.animateWithDuration(0.25) {
            self.stopTimeTableView!.alpha = self.FULL_ALPHA
        }
        stopTimes = nil
        stopTimeTableView.reloadData()
        
        
        if stopTimes != nil {
            var targetRow: Int
            if stopTimes!.afterNow.count > 0 {
                targetRow = stopTimes!.beforeNow.count
            }
            else {
                targetRow = stopTimes!.beforeNow.count + stopTimes!.afterNow.count - 1
            }
            stopTimeTableView.scrollToRowAtIndexPath(NSIndexPath(forRow: targetRow, inSection: 0), atScrollPosition: UITableViewScrollPosition.None, animated: true)
        }
    }
    
    
    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
        
        if view.annotation is StopAnnotation {
            let stop = (view.annotation as StopAnnotation).stop
            selectStop(stop)
        }
    }
    
    func mapView(mapView: MKMapView!, didDeselectAnnotationView view: MKAnnotationView!) {
        UIView.animateWithDuration(0.25) {
            self.stopTimeTableView.alpha = 0.0
        }
    }
    
    
    // MARK - utilities
    
    func inputValid() -> Bool {
        if route == nil || vectorIndex == nil {
            Logger.log(fromSource: self, level: .ERROR, message: "Vector not specified")
            return false
        }
        if vectorIndex >= route.vectors.count {
            Logger.log(fromSource: self, level: .ERROR, message: "Vector Index is invalid")
            return false
        }
        
        let v = route.vectors[vectorIndex]
        if v.polyline == nil {
            Logger.log(fromSource: self, level: .ERROR, message: "Vector has no polyline")
            return false
        }
        
        return true
    }
    
    func initStopTimes() {
        if stopTimes == nil && targetStop != nil {
            let effDate = (UIApplication.sharedApplication().delegate as AppDelegate).effectiveDate
            stopTimes = AppDelegate.theScheduleManager.getStopTimes(forStop: targetStop!.id,
                inVector: route.vectors[vectorIndex], inSchedule: schedule, forDate: effDate)
        }
    }
    
    
    
    func getStopTimesForDisplay(stop: Stop) -> NSMutableAttributedString {
        initStopTimes()
        var prefix = " Stop times: "
        var beforeStr = ""
        for (var i = 0; i < stopTimes.beforeNow.count; ++i) {
            beforeStr += ScheduleManager.formatTimeOfDay(stopTimes.beforeNow[i])
            if i < stopTimes.beforeNow.count - 1 {
                beforeStr += ","
            }
        }
        
        var afterStr = ""
        for (var i = 0; i < stopTimes.afterNow.count; ++i) {
            afterStr += ScheduleManager.formatTimeOfDay(stopTimes.afterNow[i])
            if i < stopTimes.afterNow.count - 1 {
                afterStr += ","
            }
        }
        
        var labelText = ""
        if !afterStr.isEmpty {
            labelText = prefix + beforeStr + "," + afterStr
        }
        else {
            labelText = prefix + beforeStr
        }
        
        var attrStr = getMutableAttributedString(labelText, withFont: UIFont.systemFontOfSize(TIME_LABEL_FONT_SIZE))
        let beforeRange = NSMakeRange(countElements(prefix), countElements(beforeStr))
        let afterRange =  NSMakeRange(countElements(prefix + beforeStr), countElements(afterStr))
        
        attrStr.addAttribute(NSForegroundColorAttributeName, value: UIColor.lightGrayColor(), range: beforeRange)
        attrStr.addAttribute(NSForegroundColorAttributeName, value: UIColor.blackColor(), range: afterRange)
    
        return attrStr
    }
}


extension MapViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if targetStop != nil {
            initStopTimes()
            var cell = tableView.dequeueReusableCellWithIdentifier(STOP_TABLE_REUSE_ID, forIndexPath: indexPath) as UITableViewCell
            if stopTimes != nil {
                var row = indexPath.row

                if row < stopTimes!.beforeNow.count {
                    cell.textLabel!.text = ScheduleManager.formatTimeOfDay(stopTimes!.beforeNow[row])
                    cell.textLabel!.textColor = UIColor.lightGrayColor()
                }
                else {
                    row = row - stopTimes!.beforeNow.count
                    cell.textLabel!.text = ScheduleManager.formatTimeOfDay(stopTimes!.afterNow[row])
                    cell.textLabel!.textColor = UIColor.blackColor()
                }
                cell.textLabel!.font = UIFont.boldSystemFontOfSize(STOP_TABLE_FONT_SIZE)
            }
            return cell
        }
        
        return UITableViewCell()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if targetStop != nil {
            initStopTimes()
        }
        if stopTimes != nil {
            return stopTimes!.beforeNow.count + stopTimes!.afterNow.count
        }
        else {
            return 0
        }
    }
    
}






