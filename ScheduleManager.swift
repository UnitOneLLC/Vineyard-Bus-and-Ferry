//
//  ScheduleManager.swift
//  Vineyard Bus and Ferry
//
//  Created by Fred Hewett on 3/18/15.
//  Copyright (c) 2015 Frederick Hewett. All rights reserved.
//

import Foundation
import CoreData

let EXTENSION = ".json"

var DOMAIN_STEM : String!
var modeURLMap: [String: String]!
var modeVersionURLMap: [String: String]!

class ScheduleManager : CustomStringConvertible {
    var schedulesByAgency: [String: Schedule]
    var schedulesByMode: [String: Schedule]
    
    init() {
        schedulesByAgency = [String: Schedule]()
        schedulesByMode   = [String: Schedule]()
        readUrlData()
    }
    
    func readUrlData() {
        let path = NSBundle.mainBundle().pathForResource("urlinfo", ofType: "json")
        
        modeURLMap = [String: String]()
        modeVersionURLMap = [String: String]()

        if let json = NSData(contentsOfFile: path!) {
            do {
                let dico = try NSJSONSerialization.JSONObjectWithData(json, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary;

                DOMAIN_STEM = dico["domainStem"] as! String
                
                let urlDico = dico["urlMap"] as! NSDictionary
                for key in urlDico.keyEnumerator() {
                    let mode = key as! String
                    let url = urlDico[mode] as! String
                    modeURLMap[mode] = DOMAIN_STEM + url
                }
                let verDico = dico["versionUrlMap"] as! NSDictionary
                for key in verDico.keyEnumerator() {
                    let mode = key as! String
                    let url = verDico[mode] as! String
                    modeVersionURLMap[mode] = DOMAIN_STEM + url
                }
            }
            catch {
                return
            }
            
        }
    }
    
    func addScheduleForAgency(agencyId: String, sched: Schedule) {
        schedulesByAgency[agencyId] = sched
    }
    
    func addScheduleForMode(mode: String, sched: Schedule) {
        schedulesByMode[mode] = sched
    }
    
    var description: String {
        return "Schedule Manager"
    }
    
    func getNameOfStoredFile(mode: String) -> String {
        let docPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let docURL = NSURL(fileURLWithPath: docPath)
        let filePath = docURL.URLByAppendingPathComponent(mode + EXTENSION)
        return filePath.absoluteString
    }
    
    func isScheduleFileStored(mode: String) -> Bool {
        return NSFileManager.defaultManager().fileExistsAtPath(getNameOfStoredFile(mode))
    }
    
    func saveScheduleToFile(data: NSData, mode: String) {
        data.writeToFile(getNameOfStoredFile(mode), atomically: true)
    }
    
    func readScheduleFromFile(mode: String) -> Schedule? {
        let filePath = getNameOfStoredFile(mode)
        if let data = NSData(contentsOfFile: filePath) {
            return Schedule(fromJson: data)
        }
        return nil
    }
    
    func deleteStoredFile(mode: String) {
        do {
            try NSFileManager.defaultManager().removeItemAtPath(getNameOfStoredFile(mode));
        }
        catch {
        }
    }
    
    func downloadSchedule(forMode mode: String, moc: NSManagedObjectContext, completionHandler: ((data: NSData?)->Void)) {
        
        let url = modeURLMap[mode]
        if url == nil {
            completionHandler(data: nil)
            return
        }
        Logger.log(fromSource: self, level: .INFO, message: "Downloading new schedule for mode \(mode)")
        
        let request = NSMutableURLRequest(URL: NSURL(string: url!)!, cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData, timeoutInterval: 60.0)
        
        request.setValue("gzip", forHTTPHeaderField: "Accept-Encoding")
        
        
        let session = NSURLSession.sharedSession()
        request.HTTPMethod = "POST"
        
        let task = session.dataTaskWithRequest(request, completionHandler: { ( data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            completionHandler(data: data)
        })
        
        task.resume()
        
        
//        let queue:NSOperationQueue = NSOperationQueue()
//        NSURLConnection.sendAsynchronousRequest(request, queue: queue, completionHandler:{ (response: NSURLResponse!, data: NSData!, error: NSError!) -> Void in
//            completionHandler(data: data)
//        })
    }
    
    
    func downloadCurrentVersion(forMode mode: String, completionHandler: ((version: Int) -> Void)) {
        let url = modeVersionURLMap[mode]
        if url == nil {
            completionHandler(version: -1)
            return
        }
        
        let request = NSMutableURLRequest(URL: NSURL(string: url!)!, cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData, timeoutInterval: 60.0)
        
        let queue:NSOperationQueue = NSOperationQueue()
        NSURLConnection.sendAsynchronousRequest(request, queue: queue, completionHandler:{ (response: NSURLResponse?, json: NSData?, error: NSError?) -> Void in

            var version: Int
            do {
                let dico = try NSJSONSerialization.JSONObjectWithData(json!, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary

                version = dico["version"] as! Int
                Logger.log(fromSource: self, level: .INFO, message: "Current version for mode \(mode) is \(version)")

                completionHandler(version: version as Int)
            }
            catch {
                Logger.log(fromSource: self, level: .ERROR, message: "Did not retrieve version")
                version = -1
                
            }
        })
        
    }
    
    func getVersionParameterName(forMode mode: String) -> String? {
        if mode == "BUS" {
            return "busVersion"
        }
        else if mode == "FERRY" {
            return "ferryVersion"
        }
        else {
            return nil
        }
    }
    
    func getStoredVersion(forMode mode: String, moc: NSManagedObjectContext) -> Int {
        if let parameterName = getVersionParameterName(forMode: mode) {
            if let version: NSNumber? = AppDelegate.theSettingsManager.getSetting(parameter: parameterName, moc: moc) {
                return version as! Int
            }
            else {
                return -1
            }
        }
        else {
            Logger.log(fromSource: self, level: .ERROR, message: "Unknown mode: \(mode)")
            return -1
        }
    }
    
    func processSchedule(forMode mode: String, sched: Schedule) {
        addScheduleForMode(mode, sched: sched)
        for agency in sched.agencies {
            addScheduleForAgency(agency.id, sched: sched)
        }
    }
    
    func acquireSchedule(forMode mode: String, vc: AnyObject, moc: NSManagedObjectContext, completionHandler: ((s: Schedule?)->Void)) {
        let storedVersion = getStoredVersion(forMode: mode, moc: moc)
        Logger.log(fromSource: self, level: .INFO, message: "Stored version for mode \(mode) is \(storedVersion)")
        
        if isInternetConnected() {
            
            downloadCurrentVersion(forMode: mode) { (version: Int) in
                
                if storedVersion < version {
                    self.downloadSchedule(forMode: mode, moc: moc) { (data: NSData?) -> Void in
                        if data != nil {
                            self.saveScheduleToFile(data!, mode: mode)
                            let number: NSNumber = version as NSNumber
                            AppDelegate.theSettingsManager.setAppParameter(parameter: self.getVersionParameterName(forMode: mode)!, value: number, moc: moc)
                            let s = Schedule(fromJson: data!)
                            self.processSchedule(forMode: mode, sched: s)
                            completionHandler(s: s)
                        }
                    } // schedule closure
                }
                else { // stored version is current
                    Logger.log(fromSource: self, level: .INFO, message: "Stored schedule version for mode \(mode) is current")
                    if let sched = self.readScheduleFromFile(mode) {
                        self.processSchedule(forMode: mode, sched: sched)
                        completionHandler(s: sched)
                    }
                    else {
                        Logger.log(fromSource: self, level: .ERROR, message: "Fatal: no schedule for mode \(mode)")
                        completionHandler(s: nil)
                        simpleAlert("Network Error", message: "No \(mode) schedule available. Close the app and re-try.", controller: vc)
                    }
                }
            } // version closure
        }
        else { // no network
            if storedVersion > 0 { // assume stored version is OK when no network
                Logger.log(fromSource: self, level: .INFO, message: "No network -- asuming stored schedule for mode \(mode) is current")
                if let sched = self.readScheduleFromFile(mode) {
                    self.processSchedule(forMode: mode, sched: sched)
                    completionHandler(s: sched)
                }
                else {
                    Logger.log(fromSource: self, level: .ERROR, message: "Fatal: no schedule for mode \(mode)")
                    completionHandler(s: nil)
                    simpleAlert("Network Error", message: "No \(mode) schedule available. You must have an internet connection.", controller: vc)                }
            }
            else {
                Logger.log(fromSource: self, level: .ERROR, message: "Fatal: no schedule for mode \(mode)")
                completionHandler(s: nil)
                simpleAlert("Network Error", message: "No \(mode) schedule available. You must have an internet connection.", controller: vc)
            }
        }
    }
    
    func scheduleForMode(mode: String) -> Schedule? {
        return schedulesByMode[mode]
    }
    
    func scheduleForAgency(agencyId: String) -> Schedule? {
        return schedulesByAgency[agencyId]
    }
    
    func getRouteDestinationsForAgency(agencyId: String, effectiveDate: NSDate) -> [String] {
        var result = [String]()
        if let s = schedulesByAgency[agencyId] {
            for r in s.routes {
                if r.agency == agencyId && isRouteInService(r, effectiveDate: effectiveDate){
                    if r.waypoint != nil && !r.waypoint!.isEmpty {
                        result.append(r.waypoint!)
                    }
                    for v in r.vectors {
                        if v.destination == "Loop" {
                            continue
                        }
                        if !result.contains(v.destination) {
                            result.append(v.destination)
                        }
                    }
                }
            }
        }
        else {
            Logger.log(fromSource: self, level: .ERROR, message: "Bad agencyId: \(agencyId)")
        }
        return result
    }
    
    
    func isRouteInService(route: Route, effectiveDate: NSDate) -> Bool {
        var calendarsForRoute: Set<String> = Set<String>()
        let sched = scheduleForAgency(route.agency)

        for v in route.vectors {
            for t in v.trips {
                calendarsForRoute.insert(t.serviceId)
            }
        }

        for c in calendarsForRoute {
            if let cal = getServiceCalendar(forId: c, inSchedule: sched!) {
                if isDateValidForCalendar(effectiveDate, serviceCalendar: cal) {
                    return true
                }
            }
        }
        
        return false
        
    }
    
    
    func getRoutesForDestination(destination: String, forSchedule s: Schedule, agencyId: String? = nil) -> [Route] {
        var result = [Route]()

        for r in s.routes {
            if agencyId != nil && r.agency != agencyId! {
                continue
            }
            if r.waypoint != nil && r.waypoint! == destination {
                result.append(r)
            }
            else {
                for v in r.vectors {
                    if destination == v.destination {
                        result.append(r)
                        break
                    }
                }
            }
        }
        
        return result
    }
    
    func getAgencyById(agencyId: String) -> Agency? {
        if let s = scheduleForAgency(agencyId) {
            for a in s.agencies {
                if a.id == agencyId {
                    return a
                }
            }
        }
        return nil
    }
    
    func getRoute(fromSchedule s: Schedule, withId routeId: String) -> Route? {
        for r in s.routes {
            if r.id == routeId {
                return r
            }
        }
        return nil
    }
    
    func getStop(fromSchedule sched: Schedule, withId stopId: String) -> Stop? {
        for stop in sched.stops {
            if stop.id == stopId {
                return stop
            }
        }
        return nil
    }

    
    func stopSequenceForVector(v: Vector, inSchedule sched: Schedule) -> [Stop] {

        var set = [String: [Int]]()
        
        for t in v.trips {
            for s in t.stops {
                if !set.keys.contains(s.id) {
                    set[s.id] = [Int]()
                }
                if !set[s.id]!.contains(s.seq) {
                    set[s.id]!.append(s.seq)
                }
            }
        }
        
        var idList = [String]()
        for (var i = set.count; i > 0; --i) {
            
            var foundKey: String? = nil
            repeat {
                foundKey = nil
                for k in set.keys {
                    if set[k]!.contains(i) {
                        foundKey = k
                        idList.append(k)
                        set.removeValueForKey(k)
                        break;
                    }
                }
            }  while (foundKey != nil)
        }
        
        idList = idList.reverse()
        
        var result = [Stop]()
        for id in idList {
            result.append(getStop(fromSchedule: sched, withId: id)!)
        }
        return result
    }
    
    class func formatTimeOfDay(tod: TimeOfDay) -> String {
        let minutes = tod.minute < 10 ? "0" + String(tod.minute) : String(tod.minute)
        let mod12 = tod.hour == 12 ? 12 : tod.hour % 12
        var hour = (mod12) < 10 ? " " + String(mod12) : String(mod12)
        let ampm = (tod.hour < 12) ? "AM" : "PM"
        if hour == " 0" {
            hour = "12"
        }

        return hour + ":" + minutes + " " + ampm
    }
    
    func getServiceCalendar(forId id: String, inSchedule sched: Schedule) -> ServiceCalendar? {
        for sc in sched.services {
            if id == sc.id {
                return sc
            }
        }
        return nil
    }
    
    class func getDayOfWeekIndex(forDate date: NSDate) -> Int { // Monday=0, Sunday=6
        let calendar = NSCalendar.currentCalendar()
        let dateComponents = calendar.components(NSCalendarUnit.Weekday, fromDate: date)
        
        let ord = dateComponents.weekday - 2
        if ord == -1 {
            return 6
        }
        else {
            return ord
        }
    }
    
    // date input format is "yyyy-MM-dd"
    class func getDayOfWeekIndex(forString s: String) -> Int? { // Monday=0, Sunday=6
        let df = NSDateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        if let date = df.dateFromString(s) {
            return getDayOfWeekIndex(forDate: date)
        }
        else {
            return nil
        }
    }
    
    func isDateValidForCalendar(dateIn: NSDate, serviceCalendar sc: ServiceCalendar) -> Bool {
        let date = normalizedDate(dateIn)
        if date.isBefore(sc.startDate) || date.isAfter(sc.endDate) {
            return false
        }
        let dayIndex = ScheduleManager.getDayOfWeekIndex(forDate: date)
        if sc.daysActive[dayIndex] {
            // check for remove exception
            for remExc in sc.inactiveExceptionDates {
                if date.compare(remExc) == NSComparisonResult.OrderedSame {
                    return false
                }
            }
            
            return true
        }
        else {
            // check for add exception
            for addExc in sc.activeExceptionDates {
                if date.compare(addExc) == NSComparisonResult.OrderedSame {
                    return true
                }
            }
            
            return false
        }
    }
    
    func filterTripsForDate(date: NSDate, trips: [Trip], inSchedule sched: Schedule) -> [Trip] {
        var filtered = [Trip]()
        var okCalendars = [String]()
        var notOkCalendars = [String]()

        for t in trips {
            let svcId = t.serviceId
            
            if okCalendars.contains(svcId) {
                filtered.append(t)
            }
            else if notOkCalendars.contains(svcId) {
                continue
            }
            else {
                if let sc = getServiceCalendar(forId: svcId, inSchedule: sched) {
                    if isDateValidForCalendar(date, serviceCalendar: sc) {
                        filtered.append(t)
                        okCalendars.append(svcId)
                    }
                    else {
                        notOkCalendars.append(svcId)
                    }
                }
                else {
                    Logger.log(fromSource: self, level: .ERROR, message: "Trip \(t.id) has bad calendar id: \(svcId)")
                    return trips
                }
            }
        }
        
        return filtered
    }
    
    func getTripIndex(inVector vector: Vector, forTripId tripId: String) -> Int {

        for (var i = 0; i < vector.trips.count; ++i) {
            if vector.trips[i].id == tripId {
                return i
            }
        }
        
        return -1
    }
    
    func getStopTimes(forStop stop: String, inVector vector: Vector, inSchedule schedule: Schedule, forDate effDate: NSDate) -> (beforeNow: [TimeOfDay], afterNow: [TimeOfDay]) {
        let now = NSDate()
        
        let calendar = NSCalendar.currentCalendar()
        let dateComponents = calendar.components([.Hour, .Minute], fromDate: now)

        let nowTod = TimeOfDay(fromString: String(dateComponents.hour) + ":" + String(dateComponents.minute))
        
        var beforeTimes = [TimeOfDay]()
        var afterTimes = [TimeOfDay]()

        for trip in vector.trips {
            let cal = getServiceCalendar(forId: trip.serviceId, inSchedule: schedule)
            if !isDateValidForCalendar(effDate, serviceCalendar: cal!) {
                continue
            }
            for stopTime in trip.stops {
                if stopTime.id == stop {
                    if stopTime.time.hour > nowTod.hour || (stopTime.time.hour == nowTod.hour && stopTime.time.minute > nowTod.minute) {
                        afterTimes.append(stopTime.time)
                    }
                    else {
                        beforeTimes.append(stopTime.time)
                    }
                }
            }
        }
        
        return (beforeNow: beforeTimes, afterNow: afterTimes)
    }
    
    
    
    
    
    
}