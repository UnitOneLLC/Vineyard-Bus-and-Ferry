//
//  Settings.swift
//  Vineyard Bus and Ferry
//
//  Created by Fred Hewett on 3/19/15.
//  Copyright (c) 2015 Frederick Hewett. All rights reserved.
//

import Foundation
import CoreData

@objc(Settings)
class Settings: NSManagedObject {

    @NSManaged var lastDownloadTime: NSDate

}
