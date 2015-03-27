//
//  VectorViewController.swift
//  Vineyard Bus and Ferry
//
//  Created by Fred Hewett on 3/23/15.
//  Copyright (c) 2015 Frederick Hewett. All rights reserved.
//

import UIKit
import MapKit

class VectorViewController: UIViewController {
    
    let SCHED_FRACTION: Double = 0.66
    let VERT_OFFSET_FOR_NAV: CGFloat = 80.0
    let DAY_SELECT_WIDTH: CGFloat = 230.0
    
    // set from segue
    var route: Route!
    var vectorIndex: Int!
    


    @IBOutlet var frameView: UIView!
    @IBOutlet weak var mapView: MKMapView!
    
    var schedBox: UIScrollView!
    var vectorTable: VectorTable!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createSubViews()
    }
    
    override func viewDidAppear(animated: Bool) {
        dispatch_after(DISPATCH_TIME_NOW, dispatch_get_main_queue() ) {
            self.vectorTable.tripCollection.collectionView.scrollToItemAtIndexPath(NSIndexPath(forRow: 3, inSection: 0), atScrollPosition: UICollectionViewScrollPosition.None, animated: true)
            self.vectorTable.tripCollection.didScrollToTrip(3)
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
            h: Double = SCHED_FRACTION * Double(frameView.frame.size.height)

        let daySelect = DaySelectionControl(width: DAY_SELECT_WIDTH)
        var dayFrame = daySelect.frame
        dayFrame.origin.y = VERT_OFFSET_FOR_NAV
        dayFrame = hCenterInFrame(frameToCenter: dayFrame, container: frameView.frame)
        daySelect.frame = dayFrame
        frameView.addSubview(daySelect)
        println("daySelect frame= \(daySelect.frame)")
        
        let sizeSched = CGSize(width: w, height: h)

        let schedOffsetY = VERT_OFFSET_FOR_NAV + dayFrame.height
        schedBox = UIScrollView(frame: CGRect(origin: CGPoint(x: 0.0, y: schedOffsetY), size:sizeSched))
        schedBox.scrollEnabled = true

        frameView.addSubview(schedBox)
        
        mapView.autoresizingMask = UIViewAutoresizing.FlexibleHeight

        let vtFrame = CGRect(x: 0.0, y: 0.0, width: schedBox.frame.width - 20.0, height: /*schedBox.frame.height - 20.0*/ 1200.0)
        vectorTable = VectorTable(frame: vtFrame, route: route, vectorIndex: vectorIndex)
        schedBox.addSubview(vectorTable)
        schedBox.contentSize = vtFrame.size
        
//        let tapper = UITapGestureRecognizer(target: self, action: "didTap:")
//        schedBox.addGestureRecognizer(tapper)
    }
    
    func didTap(sender: AnyObject) {
        println("the current offset is \(vectorTable.tripCollection.collectionView.contentOffset)")
//        vectorTable.tripCollection.collectionView.scrollToItemAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), atScrollPosition: UICollectionViewScrollPosition.None, animated: true)
        
        var sFrame = schedBox.frame
        var mFrame = mapView.frame
        var vFrame = vectorTable.frame
        
        println("mapView: \(mapView.frame)")
        println("schedBox: \(schedBox.frame)")
        println("vectorTable: \(vectorTable.frame)")
        
        let h = sFrame.height
        sFrame.size.height = mFrame.height
        mFrame.size.height = h
        
        mFrame.origin.y = sFrame.size.height

//        var vFrame = CGRect(x: 0, y: 0, width: mFrame.size.width, height: mFrame.size.height)
        
        
//        UIView.animateWithDuration(0.2) {
//            self.mapView.frame = mFrame
//            self.schedBox.frame = sFrame
//        }
    }
}
