//
//  SettingsManager.swift
//  Vineyard Bus and Ferry
//
//  Created by Fred Hewett on 3/19/15.
//  Copyright (c) 2015 Frederick Hewett. All rights reserved.
//

import Foundation
import CoreData


class SettingsManager : Printable {
    
    let ENTITY_SETTINGS: String = "Settings"
    
    var description: String {
        return "Settings Manager"
    }
    
    
    func isSettingsObjectCreated(moc: NSManagedObjectContext) -> Bool {
        var error: NSError?
        let fetchRequest = NSFetchRequest(entityName: ENTITY_SETTINGS)
        let fetchedResults = moc.executeFetchRequest(fetchRequest, error: &error) as [Settings]?
        
        return fetchedResults? != nil && fetchedResults!.count > 0
    }
    
    func storeSettingsObject(moc: NSManagedObjectContext, s: Settings) {
        
    }
    
    func createInitialAppParametersObject(#moc: NSManagedObjectContext) -> Bool {
        let newSettings = NSEntityDescription.insertNewObjectForEntityForName(ENTITY_SETTINGS, inManagedObjectContext: moc) as Settings;
        newSettings.lastDownloadTime = NSDate(timeIntervalSinceNow: -1000000000.0)
        var error: NSError?
        moc.save(&error)
        return error == nil
    }
    
    
    func getSetting<T: AnyObject>(#parameter: String, moc: NSManagedObjectContext) -> T? {
        
        let fetchRequest = NSFetchRequest(entityName: ENTITY_SETTINGS)
        var error: NSError?
        let fetchedResults = moc.executeFetchRequest(fetchRequest, error: &error) as [Settings]?
        if (error != nil || fetchedResults == nil) {
            Logger.log(fromSource: self, level: .ERROR, message: "failed to get app parameters")
        }
        else if fetchedResults!.count == 0 {
            if createInitialAppParametersObject(moc: moc) {
                return getSetting(parameter: parameter, moc: moc)
            }
        }
        
        let appParams = fetchedResults![0] as Settings
        let retObj = appParams.valueForKey(parameter) as? NSObject
        if retObj == nil {
            return nil
        }
        else {
            return retObj as? T
        }
    }
    
    func setAppParameter<T: AnyObject>(#parameter: String, value: T, moc: NSManagedObjectContext) -> Bool {
        
        let fetchRequest = NSFetchRequest(entityName: ENTITY_SETTINGS)
        var error: NSError?
        let fetchedResults = moc.executeFetchRequest(fetchRequest, error: &error) as [Settings]?
        if (error != nil || fetchedResults == nil) {
            Logger.log(fromSource: self, level: .ERROR, message: "failed to get app parameters")
        }
        else if fetchedResults!.count == 0 {
            if createInitialAppParametersObject(moc: moc) {
                return setAppParameter(parameter: parameter, value: value, moc: moc)
            }
        }
        
        let settings = fetchedResults![0] as Settings
        settings.setValue(value, forKey: parameter)
        
        moc.save(&error)
        return error == nil
    }
    
    
}