//
//  TripCollection.swift
//  Vineyard Bus and Ferry
//
//  Created by Fred Hewett on 3/25/15.
//  Copyright (c) 2015 Frederick Hewett. All rights reserved.
//

import UIKit

protocol TripCollectionDelegate {
     func tripCollection(didScrollToTrip: Trip)
}

class TripColllectionLayout : UICollectionViewFlowLayout {
    override func layoutAttributesForElementsInRect(rect: CGRect) -> [AnyObject]? {

        var result: [AnyObject]! = super.layoutAttributesForElementsInRect(rect)
        if result == nil {
            return nil
        }
        for (var i=1; i < result.count; ++i) {
            var currentLayoutAttributes = result[i] as UICollectionViewLayoutAttributes
            var prevLayoutAttributes = result[i-1] as UICollectionViewLayoutAttributes
            var currentFrame = currentLayoutAttributes.frame
            
            currentFrame.origin.x = CGFloat(currentLayoutAttributes.indexPath.row) * currentFrame.width
            currentLayoutAttributes.frame = currentFrame
        }
        
        return result
    }
}

class TripCollection: NSObject {
    class var COLL_REUSE_ID: String {return "tripCell"}
    
    let trips: [Trip]!
    var collectionView: UICollectionView!
    var delegate: TripCollectionDelegate!
    var frame: CGRect!
    var rowHeights: [Double]!
    var selectedTrip: Trip!
    var stopTimeTables: [StopTimeTable]!
    var stopSequence: [Stop]!
    
    init? (stopSequence: [Stop], rowHeights: [Double], tripArray: [Trip], frame: CGRect) {
        super.init()
        if tripArray.count == 0 {
            return nil
        }
        
        self.trips = tripArray
        self.frame = frame
        self.stopSequence = stopSequence
        self.rowHeights = rowHeights
        self.stopTimeTables = [StopTimeTable]()
        
        var layout = TripColllectionLayout()
        layout.scrollDirection = UICollectionViewScrollDirection.Horizontal

        collectionView = UICollectionView(frame: frame, collectionViewLayout:layout)
        collectionView.backgroundColor = UIColor.whiteColor()
        collectionView.registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: TripCollection.COLL_REUSE_ID)
        collectionView.decelerationRate = UIScrollViewDecelerationRateFast
        collectionView.directionalLockEnabled = true
        collectionView.pagingEnabled = true
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
    func didScrollToTrip(index: Int) {
        if index >= 0 && index < trips.count {
            selectedTrip = trips[index]
            delegate.tripCollection(selectedTrip)
        }
    }
    
    func scrollToNext() {
        let w = collectionView.frame.width
        var currentIndex: Int = Int(round(collectionView.contentOffset.x/w))
        if currentIndex < (trips.count-1) {
            currentIndex++
            let newOffset = CGFloat(currentIndex) * w
            let targetRect = CGRect(x: newOffset, y: CGFloat(0.0), width: w, height: CGFloat(1.0))
            collectionView.scrollRectToVisible(targetRect, animated: true)
            didScrollToTrip(currentIndex)
        }
    }

    func scrollToPrev() {
        let w = collectionView.frame.width
        var currentIndex: Int = Int(round(collectionView.contentOffset.x/w))
        if currentIndex > 0 {
            currentIndex--
            let newOffset = CGFloat(currentIndex) * w
            let targetRect = CGRect(x: newOffset, y: CGFloat(0.0), width: w, height: CGFloat(1.0))
            collectionView.scrollRectToVisible(targetRect, animated: true)
            didScrollToTrip(currentIndex)
        }
    }
    
    func scrollToTripAtIndex(index: Int) {
        let w = collectionView.frame.width
        let newOffset = CGFloat(index) * w
        let targetRect = CGRect(x: newOffset, y: CGFloat(0.0), width: w, height: CGFloat(1.0))
        collectionView.scrollRectToVisible(targetRect, animated: true)
        didScrollToTrip(index)
    }
    
    func scrollToCurrent() {
        let now = NSDate()
        let dateCompos = NSCalendar.currentCalendar().components(NSCalendarUnit.CalendarUnitHour|NSCalendarUnit.CalendarUnitMinute, fromDate: now)
        let nowScalar = dateCompos.hour * 60 + dateCompos.minute
        
        var index = 0;
        for (; index < trips.count; ++index) {
            if trips[index].stops.count == 0 {
                continue
            }
            let thisTime = trips[index].stops[0].time
            let tScalar = thisTime.hour * 60 + thisTime.minute
            if tScalar > nowScalar {
                break
            }
        }
        
        if index == trips.count {
            index = trips.count - 1
        }
        scrollToTripAtIndex(index-1)
    }
    
    
}

extension TripCollection:  UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        var cell = collectionView.dequeueReusableCellWithReuseIdentifier(TripCollection.COLL_REUSE_ID, forIndexPath: indexPath) as UICollectionViewCell

        let stopTimeTable = StopTimeTable(stopSequence: stopSequence, trip: trips[indexPath.row], rowHeights: rowHeights)
        stopTimeTables.append(stopTimeTable)
        
        let origin = CGPoint(x: 0.0, y: 0.0)
        let w = collectionView.frame.width - collectionView.layoutMargins.left - collectionView.layoutMargins.right
        let h = collectionView.frame.height // - collectionView.layoutMargins.top - collectionView.layoutMargins.bottom
        let f = CGRect(origin: origin, size: CGSize(width: w, height: h))
        
        var tvForCell = UITableView(frame: f)
        tvForCell.separatorStyle = UITableViewCellSeparatorStyle.None
        tvForCell.registerClass(UITableViewCell.self, forCellReuseIdentifier: StopTimeTable.REUSE_ID)
        tvForCell.scrollEnabled = false
        tvForCell.allowsSelection = false
        tvForCell.dataSource = stopTimeTable
        tvForCell.delegate = stopTimeTable
        tvForCell.bounces = false
        
        cell.addSubview(tvForCell)
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return trips.count
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let size = CGSizeMake(frame.width, frame.height)
        return size
    }
    
    func getIndexFromOffset(offset: CGFloat) -> Int {
        let w = frame.width
        let index = min(Int(floor((offset + (w/2)) / w)), trips.count-1)
        return index
    }

    func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        var raw = targetContentOffset.memory.x
        var paged = round((raw/frame.width) * frame.width)
        paged = min(paged, frame.width * CGFloat(trips.count - 1))
        targetContentOffset.memory.x = paged
    }
    
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if delegate != nil {
            didScrollToTrip(getIndexFromOffset(scrollView.contentOffset.x))
        }
    }
    
}
