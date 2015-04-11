//
//  Schedule.swift
//  Vineyard Bus and Ferry
//
//  Created by Fred Hewett on 3/18/15.
//  Copyright (c) 2015 Frederick Hewett. All rights reserved.
//

import Foundation
import CoreLocation

struct TimeOfDay {
    let hour: Int!
    let minute: Int!
    
    init(fromString string: String) {
        let array = split(string) {$0 == ":"}
        
        self.hour = (array[0] as NSString).integerValue
        self.minute = (array[1] as NSString).integerValue
    }
}

class Agency {
    let id: String!
    let name: String!
    let url: String?
    let timezone: String?
    let phone: String?
    let lang: String?

    init(fromDictionary dico: NSDictionary) {
        id = dico["id"] as! String
        name = dico["name"] as! String
        url = dico["url"] as? String
        timezone = dico["timezone"] as? String
        phone = dico["phone"] as? String
        lang = dico["lang"] as? String
    }
}

class StopTime {
    let id: String!
    let time: TimeOfDay!
    let seq: Int!
    
    init(fromDictionary dico: NSDictionary) {
        id = dico["id"] as! String
        time = TimeOfDay(fromString: dico["time"] as! String)
        seq = dico["seq"] as! Int
    }
}

class Connection {
    let routeId: String!
    let headSign: String!
    let tripId: String!
    let time: TimeOfDay!
    let shortName: String!
    
    init(fromDictionary dico: NSDictionary) {
        routeId = dico["routeId"] as! String
        headSign = dico["headsign"] as! String
        tripId = dico["tripId"] as! String
        time = TimeOfDay(fromString: dico["time"] as! String)
        shortName = dico["shortName"] as! String
    }
}

class Trip {
    let id: String!
    let serviceId: String!
    let stops: [StopTime]!
    let connections: [Connection]!
    
    init(fromDictionary dico: NSDictionary) {
        id = dico["tripId"] as! String
        serviceId = dico["calId"] as! String
        
        let stopTimeArr = dico["stops"] as! [NSDictionary]
        stops = [StopTime]()
        for item in stopTimeArr {
            stops.append(StopTime(fromDictionary: item))
        }
        
        let connectArr = dico["connections"] as! [NSDictionary]
        connections = [Connection]()
        for item in connectArr {
            connections.append(Connection(fromDictionary: item))
        }
    }
}

class Vector {
    var origin: String?
    let destination: String!
    let trips: [Trip]!
    let polyline: Polyline!
    
    init(fromDictionary dico: NSDictionary) {
        origin = dico["origin"] as? String
        destination = dico["destination"] as! String
        
        let tripArr = dico["trips"] as! [NSDictionary]
        trips = [Trip]()
        for item in tripArr {
            trips.append(Trip(fromDictionary: item))
        }
        let polyStr = dico["polyline"] as! String
        polyline = Polyline(encodedPolyline: polyStr, encodedLevels: nil)
    }
}

class Stop {
    let id: String!
    let name: String!
    let coord: CLLocationCoordinate2D!
    
    init(fromDictionary dico: NSDictionary) {
        id = dico["id"] as! String
        name = dico["name"] as! String
        coord = CLLocationCoordinate2D(latitude: dico["lat"] as! Double, longitude: dico["lng"] as! Double)
    }
}

class ServiceCalendar {
    let id: String!
    let daysActive: [Bool]!
    let startDate: NSDate!
    let endDate: NSDate!
    let activeExceptionDates: [NSDate]!
    let inactiveExceptionDates: [NSDate]!
    
    init(fromDictionary dico: NSDictionary) {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        id = dico["serviceId"] as! String
        let intDays = dico["days"] as! [Int]
        daysActive = [Bool](count: 7, repeatedValue: false)
        for (var i=0; i < 7; ++i) {
            daysActive[i] = intDays[i] == 1
        }
        
        startDate = formatter.dateFromString(dico["startDate"] as! String)
        endDate = formatter.dateFromString(dico["endDate"] as! String)
        
        let addExcs = dico["addExceptions"] as! [String]
        activeExceptionDates = [NSDate]()
        for item in addExcs {
            activeExceptionDates.append(formatter.dateFromString(item)!)
        }
        
        let removeExcs = dico["removeExceptions"] as! [String]
        inactiveExceptionDates = [NSDate]()
        for item in removeExcs {
            inactiveExceptionDates.append(formatter.dateFromString(item)!)
        }
    }
}


class Route {
    let id: String!
    let agency: String!
    let shortName: String?
    let longName: String!
    let colorRGB: String?
    let waypoint: String?
    let vectors: [Vector]!
    
    init(fromDictionary dico: NSDictionary) {
        id = dico["id"] as! String
        agency = dico["agency"] as! String
        shortName = dico["shortName"] as? String
        longName = dico["longName"] as! String
        colorRGB = dico["colorCode"] as? String
        waypoint = dico["waypoint"] as? String
        
        let vectorArr = dico["vectors"] as! [NSDictionary]
        vectors = [Vector]()
        for item in vectorArr {
            vectors.append(Vector(fromDictionary: item))
        }
    }
}

class Schedule {
    let agencies: [Agency]!
    let routes: [Route]!
    let stops: [Stop]!
    let services: [ServiceCalendar]!
    
    init(fromJson json: NSData) {
        var err: NSError?
        var dico = NSJSONSerialization.JSONObjectWithData(json, options: NSJSONReadingOptions.MutableContainers, error: &err) as! NSDictionary
        
        let agencyArr = dico["agencies"] as! [NSDictionary]
        self.agencies = [Agency]()
        for item in agencyArr {
            self.agencies.append(Agency(fromDictionary: item))
        }
        
        let routesArr = dico["routes"] as! [NSDictionary]
        self.routes = [Route]()
        for item in routesArr {
            self.routes.append(Route(fromDictionary: item))
        }
        
        let stopsArr = dico["stops"] as! [NSDictionary]
        self.stops = [Stop]()
        for item in stopsArr {
            self.stops.append(Stop(fromDictionary: item))
        }
        
        let servicesArr = dico["calendars"] as! [NSDictionary]
        self.services = [ServiceCalendar]()
        for item in servicesArr {
            self.services.append(ServiceCalendar(fromDictionary: item))
        }
    }
}