//
//  TripCollection.swift
//  Vineyard Bus and Ferry
//
//  Created by Fred Hewett on 3/25/15.
//  Copyright (c) 2015 Frederick Hewett. All rights reserved.
//

import UIKit

protocol TripCollectionDelegate {
     func didScrollToTrip(t: Trip)
}

class TripColllectionLayout : UICollectionViewFlowLayout {
    override func layoutAttributesForElementsInRect(rect: CGRect) -> [AnyObject]? {

        var result: [AnyObject]! = super.layoutAttributesForElementsInRect(rect)
        if result == nil {
            return nil
        }
        println("layoutAttributesForElementsInRect: rect = \(rect)")
        for (var i=1; i < result.count; ++i) {
            var currentLayoutAttributes = result[i] as UICollectionViewLayoutAttributes
            var prevLayoutAttributes = result[i-1] as UICollectionViewLayoutAttributes
            var currentFrame = currentLayoutAttributes.frame
            
            println("adjust frame x in = \(currentFrame.origin.x)")
                
//            currentFrame.origin.x = prevLayoutAttributes.frame.origin.x + prevLayoutAttributes.frame.width
            currentFrame.origin.x = CGFloat(currentLayoutAttributes.indexPath.row) * currentFrame.width
            currentLayoutAttributes.frame = currentFrame
            
            println("adjust frame x out = \(currentFrame.origin.x)")
        }
        
        return result
    }
}

class TripCollection: NSObject {
    class var REUSE_ID: String {return "tripCell"}
    let trips: [Trip]!
    var collectionView: UICollectionView!
    var delegate: TripCollectionDelegate!
    var frame: CGRect!
    var rowHeights: [Double]!
    var selectedTrip: Trip!
    var stopTimeTables: [StopTimeTable]!
    var stopSequence: [Stop]!
    
    
    init? (stopSequence: [Stop], rowHeights: [Double], tripArray: [Trip], frame: CGRect, delegate: TripCollectionDelegate) {
        super.init()
        if tripArray.count == 0 {
            return nil
        }
        
        self.trips = tripArray
        self.delegate = delegate
        self.frame = frame
        self.stopSequence = stopSequence
        self.rowHeights = rowHeights
        self.stopTimeTables = [StopTimeTable]()
        
        var layout = TripColllectionLayout()
        layout.scrollDirection = UICollectionViewScrollDirection.Horizontal

        collectionView = UICollectionView(frame: frame, collectionViewLayout:layout)
        collectionView.backgroundColor = UIColor.whiteColor()
        collectionView.registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: TripCollection.REUSE_ID)
        collectionView.decelerationRate = UIScrollViewDecelerationRateFast
        collectionView.directionalLockEnabled = true
        collectionView.pagingEnabled = true
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
    func didScrollToTrip(index: Int) {
        println("did scroll to trip index=\(index)")
        selectedTrip = trips[index]
        delegate.didScrollToTrip(selectedTrip)
    }

}

extension TripCollection:  UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        println("requesting cell for trip \(indexPath.row)")
        var cell = collectionView.dequeueReusableCellWithReuseIdentifier(TripCollection.REUSE_ID, forIndexPath: indexPath) as UICollectionViewCell

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
        tvForCell.dataSource = stopTimeTable
        tvForCell.delegate = stopTimeTable
        
        cell.addSubview(tvForCell)
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        println("number of items in collection = \(trips.count)")
        return trips.count
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let size = CGSizeMake(frame.width, frame.height)
        println("collection: size of item at row \(indexPath.row) is \(size)")
        return size
    }
    
    func getIndexFromOffset(offset: CGFloat) -> Int {
        let w = frame.width
        let index = min(Int(floor((offset + (w/2)) / w)), trips.count-1)
        return index
    }

    func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        println("will end dragging x = \(scrollView.contentOffset.x) y = \(scrollView.contentOffset.y) width = \(frame.width) target x = \(targetContentOffset.memory.x)")
        
        let index = getIndexFromOffset(targetContentOffset.memory.x)
        
//        targetContentOffset.memory.x = CGFloat(index) * (frame.width + collectionView.layoutMargins.right)

//        println("after adjustment  x = \(targetContentOffset.memory.x) y = \(scrollView.contentOffset.y) index=\(index)")

    }
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        println("Drag ended at offset \(scrollView.contentOffset)")
        if delegate != nil {
            didScrollToTrip(getIndexFromOffset(scrollView.contentOffset.x))
        }
    }
    
}
