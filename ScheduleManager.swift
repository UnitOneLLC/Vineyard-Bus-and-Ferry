//
//  ScheduleManager.swift
//  Vineyard Bus and Ferry
//
//  Created by Fred Hewett on 3/18/15.
//  Copyright (c) 2015 Frederick Hewett. All rights reserved.
//

import Foundation
import CoreData

let agencyURLMap: [String: String] = [
    "VTA": "http://frederickhewett.com/vta_sched_current.json"
]

class ScheduleManager : Printable {
    var schedules: [String: Schedule]
    
    init() {
        schedules = [String: Schedule]()
    }
    
    func addSchedule(agencyId: String, sched: Schedule) {
        schedules[agencyId] = sched
    }
    
    var description: String {
        return "Schedule Manager"
    }
    
    func isScheduleCurrent(s: Schedule) -> Bool {
        let calendar = NSCalendar.currentCalendar()
        if s.services.count > 0 {
            let firstSvc = s.services[0]
            let today = NSDate()
            
            if today.isBefore(firstSvc.startDate) || today.isAfter(firstSvc.endDate) {
                return false
            }
            else {
                return true
            }
            
        }
        
        return false
    }
    
    func getNameOfStoredFile(agencyId: String) -> String {
        var docPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
        let filePath = docPath.stringByAppendingPathComponent(agencyId + ".json")
        return filePath
    }
    
    func isScheduleFileStored(name: String) -> Bool {
        return NSFileManager.defaultManager().fileExistsAtPath(getNameOfStoredFile(name))
    }
    
    func saveScheduleToFile(data: NSData, name: String) {
        data.writeToFile(getNameOfStoredFile(name), atomically: true)
    }
    
    func readScheduleFromFile(name: String) -> Schedule? {
        let filePath = getNameOfStoredFile(name)
        if let data = NSData(contentsOfFile: filePath) {
            return Schedule(fromJson: data)
        }
        return nil
    }
    
    func deleteStoredFile(name: String) {
        var error = NSErrorPointer()
        NSFileManager.defaultManager().removeItemAtPath(getNameOfStoredFile(name), error: error)
    }
    
    func downloadSchedule(forAgency agencyId: String, moc: NSManagedObjectContext, completionHandler: ((data: NSData?)->Void)) {
        
        let url = agencyURLMap[agencyId]
        if url == nil {
            completionHandler(data: nil)
            return
        }
        
        var request = NSMutableURLRequest(URL: NSURL(string: url!)!, cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData, timeoutInterval: 60.0)
        
        request.setValue("gzip", forHTTPHeaderField: "Accept-Encoding")
        
        let queue:NSOperationQueue = NSOperationQueue()
        NSURLConnection.sendAsynchronousRequest(request, queue: queue, completionHandler:{ (response: NSURLResponse!, data: NSData!, error: NSError!) -> Void in
            var err: NSError

            AppDelegate.theSettingsManager.setAppParameter(parameter: "lastDownloadTime", value: NSDate(), moc: moc)
            completionHandler(data: data)
        })
    }
    
    
    func acquireSchedule(forAgency agencyId: String, moc: NSManagedObjectContext, completionHandler: ((s: Schedule?)->Void)) {
        
        let loadHandler: (data: NSData?) -> (Void) = { (data: NSData?) -> (Void) in
        
            if (data != nil) {
                self.saveScheduleToFile(data!, name: agencyId)
                let s = Schedule(fromJson: data!)
                self.addSchedule(agencyId, sched: s)
                completionHandler(s: s)
            }
        }
        
        if isScheduleFileStored(agencyId) {
            
            if let lastDownload: NSDate? = AppDelegate.theSettingsManager.getSetting(parameter: "lastDownloadTime", moc: moc) {
                if lastDownload!.isBefore(NSDate()) {
  Logger.log(fromSource: self, level: .ERROR, message: "This logic is not correct")
                    downloadSchedule(forAgency: agencyId, moc: moc, loadHandler)
                }
            }

            if let s = readScheduleFromFile(agencyId) {
                if isScheduleCurrent(s) {
                    self.addSchedule(agencyId, sched: s)
                    completionHandler(s: s)
                }
                else if isInternetConnected() {
                    downloadSchedule(forAgency: agencyId, moc: moc, loadHandler)
                }
                else {
                    Logger.log(fromSource: self, level: .ERROR, message: "Error: out of date and no internet")
                }
            }
        }
        else if isInternetConnected() {
            downloadSchedule(forAgency: agencyId, moc: moc, loadHandler)
        }
        else {
            Logger.log(fromSource: self, level: .ERROR, message: "error: schedule not stored and not connected")
        }
    }
    
    func scheduleForAgency(agencyId: String) -> Schedule? {
        return schedules[agencyId]
    }
    
    
    func getRouteDestinations(s: Schedule) -> [String] {
        var result = [String]()

        for r in s.routes {
            for v in r.vectors {
                if !contains(result, v.destination) {
                    result.append(v.destination)
                }
            }
        }

        return result
    }
    
    func getRouteDestinationsForAgency(agencyId: String) -> [String] {
        var result = [String]()
        if let s = schedules[agencyId] {
            for r in s.routes {
                if r.agency == agencyId {
                    for v in r.vectors {
                        if !contains(result, v.destination) {
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
    
    func getRoutesForDestination(destination: String, forSchedule s: Schedule, agencyId: String? = nil) -> [Route] {
        var result = [Route]()

        for r in s.routes {
            if agencyId != nil && r.agency != agencyId! {
                continue
            }
            for v in r.vectors {
                if destination == v.destination {
                    result.append(r)
                    break
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
                if !contains(set.keys, s.id) {
                    set[s.id] = [Int]()
                }
                if !contains(set[s.id]!, s.seq) {
                    set[s.id]!.append(s.seq)
                }
            }
        }
        
        var idList = [String]()
        for (var i = set.count; i > 0; --i) {
            
            var foundKey: String? = nil
            do {
                foundKey = nil
                for k in set.keys {
                    if contains(set[k]!, i) {
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
    
    func formatTimeOfDay(tod: TimeOfDay) -> String {
        let minutes = tod.minute < 10 ? "0" + String(tod.minute) : String(tod.minute)
        let mod12 = tod.hour == 12 ? 12 : tod.hour % 12
        let hour = (mod12) < 10 ? " " + String(mod12) : String(mod12)
        let ampm = (tod.hour < 12) ? "AM" : "PM"

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
        let dateComponents = calendar.components(NSCalendarUnit.CalendarUnitWeekday, fromDate: date)
        
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
            
            if contains(okCalendars, svcId) {
                filtered.append(t)
            }
            else if contains(notOkCalendars, svcId) {
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
        let dateComponents = calendar.components(NSCalendarUnit.CalendarUnitHour | NSCalendarUnit.CalendarUnitMinute, fromDate: now)

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