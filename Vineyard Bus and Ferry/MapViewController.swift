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
//    var subtitle: String! {
//        println("subtitle requested")
//        return "stop subtitle"
//    }
    
}

class MapViewController: UIViewController, MKMapViewDelegate {
    let STOP_ANNO_REUSE_ID = "map_stop_anno"
    let STOP_ANNOTATION_WIDTH: CGFloat = 10.0
    let STOP_ANNOTATION_HEIGHT: CGFloat = 10.0
    let STOP_COLOR: UIColor = UIColor.darkGrayColor()
    let TIME_LABEL_FONT_SIZE: CGFloat = 14.0
    let TITLE_FONT_SIZE: CGFloat = 17.0
    let VPADDING: CGFloat = 10.0
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var routeTitleLabel: UILabel!
    
    // set at segue
    var schedule: Schedule!
    var route: Route!
    var vectorIndex: Int!
    var targetStop: Stop?
    var activeStopLabel: UILabel!
    var timeScroller: UIScrollView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.autoresizingMask = UIViewAutoresizing.FlexibleHeight
        mapView.delegate = self
        
        activeStopLabel = UILabel(frame: CGRect(x: 0.0, y: 0.0, width: view.frame.width, height: 0.0))
        
        timeScroller = UIScrollView(frame: CGRect(x: 0.0, y: 0.0, width: view.frame.width, height: 0.0))
        timeScroller.addSubview(activeStopLabel)
        view.addSubview(timeScroller)

        drawVector()
        annotateStops()
    }
    
    override func viewDidLayoutSubviews() {
        setRouteLabel()
        stackView(timeScroller, positionBelow: routeTitleLabel)
        stackView(mapView, positionBelow: timeScroller)
    }
    
    override func viewDidAppear(animated: Bool) {
        if targetStop != nil {
            let s = targetStop
            targetStop = nil
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
    
    func annotateStops() {
        if let schedule = AppDelegate.theScheduleManager.scheduleForAgency(route.agency) {
            let stops = AppDelegate.theScheduleManager.stopSequenceForVector(route.vectors[vectorIndex], inSchedule: schedule)
            
            for stop in stops {
                mapView.addAnnotation(StopAnnotation(stop: stop))
            }
        }
    }
    
    func setRegion(poly: Polyline) {
        var minLat: Double = 180.0, minLng: Double = 180.0, maxLat: Double = -180.0, maxLng = -180.0
        for coord in poly.coordinates {
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
        let font = UIFont.systemFontOfSize(TIME_LABEL_FONT_SIZE)
        let stopTimeLabelText = getStopTimesForDisplay(stop)
        let stringSize = (stopTimeLabelText.string as NSString).sizeWithAttributes([NSFontAttributeName: font])
        var lblFrame = activeStopLabel.frame
        lblFrame.size = stringSize
        activeStopLabel.frame = lblFrame
        activeStopLabel.attributedText = stopTimeLabelText
        
        let deltaY = getLabelHeight(stopTimeLabelText.string, UIFont.systemFontOfSize(TIME_LABEL_FONT_SIZE), stringSize.width) + VPADDING
        var mapFrame = mapView.frame
        var scrollerFrame = timeScroller.frame
        
        lblFrame.size.height = deltaY
        scrollerFrame.size.height = deltaY
        timeScroller.contentSize = stringSize
        mapFrame.size.height -= deltaY
        mapFrame.origin.y += deltaY
        
        UIView.animateWithDuration(0.2) {
            self.mapView.frame = mapFrame
            self.timeScroller.frame = scrollerFrame
            self.activeStopLabel.frame = lblFrame
        }
    }
    
    
    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
        
        if view.annotation is StopAnnotation {
            let stop = (view.annotation as StopAnnotation).stop
            selectStop(stop)
        }
    }
    
    func mapView(mapView: MKMapView!, didDeselectAnnotationView view: MKAnnotationView!) {
        let deltaY = timeScroller.frame.height
        var mapFrame = mapView.frame
        var scrollerFrame = timeScroller.frame
        scrollerFrame.size.height = 0.0
        mapFrame.size.height += deltaY
        mapFrame.origin.y -= deltaY
        
        UIView.animateWithDuration(0.2) {
            mapView.frame = mapFrame
            self.timeScroller.frame = scrollerFrame
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
    
    
    func getStopTimesForDisplay(stop: Stop) -> NSMutableAttributedString {
        let effDate = (UIApplication.sharedApplication().delegate as AppDelegate).effectiveDate
        let stopTimes = AppDelegate.theScheduleManager.getStopTimes(forStop: stop.id,
            inVector: route.vectors[vectorIndex], inSchedule: schedule, forDate: effDate)

        var prefix = " Stop times: "
        var beforeStr = ""
        for (var i = 0; i < stopTimes.beforeNow.count; ++i) {
            beforeStr += AppDelegate.theScheduleManager.formatTimeOfDay(stopTimes.beforeNow[i])
            if i < stopTimes.beforeNow.count - 1 {
                beforeStr += ","
            }
        }
        
        var afterStr = ""
        for (var i = 0; i < stopTimes.afterNow.count; ++i) {
            afterStr += AppDelegate.theScheduleManager.formatTimeOfDay(stopTimes.afterNow[i])
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

