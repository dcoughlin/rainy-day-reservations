//
//  Flight.swift
//  RainyDayReservations
//
//  Created by Dan Coughlin on 4/19/16.
//  Copyright © 2016 GroovyTree LLC. All rights reserved.
//

import UIKit
import CloudKit

let FlightRecordType = "Flight"

struct Flight {
  var flightName: String
  var originAirport: String
  var destinationAirport: String
  var flightDateTime: NSDate
  var flightDuration: Double
  var flightUpdated: Bool
  
  // MARK: CloudKit properties
  
  var record : CKRecord
  var database : CKDatabase
  
  let backgroundQueue = NSOperationQueue()
  
  var sharedModel = Model.sharedInstance
  
  init(record : CKRecord, database: CKDatabase) {
    self.record = record
    self.database = database
    
    print(self.record)
    self.flightName = record["FlightName"] as? String ?? ""
    self.originAirport = record["OriginAirport"] as? String ?? ""
    self.destinationAirport = record["DestinationAirport"] as? String ?? ""
    self.flightDateTime = record["FlightDateTime"] as? NSDate ?? NSDate()
    self.flightDuration = record["FlightDuration"] as? Double ?? 0.0
    self.flightUpdated =  record["FlightUpdated"] as? Bool ?? false
  }

  func flightForName(name: String, completion: (record: CKRecord?, error: NSError?) -> ()){
    let namePredicate = NSPredicate(format: "name == %@", name)
    let query = CKQuery(recordType: FlightRecordType, predicate: namePredicate)
    
    sharedModel.publicDB.performQuery(query, inZoneWithID: nil) {
      records, error in
      
      guard let records = records where records.count > 0 && error == nil else {
        completion(record: nil, error: error)
        return
      }
      
      let record = records[0]
      completion(record: record, error: nil)
    }
  }
  
  func fetchFlight(userRecord: CKRecordID!, completion: (rating: Double, isUser: Bool) -> ()) {
    let predicate = NSPredicate(format: "Traveler == %@", record)
    let query = CKQuery(recordType: "Reservation", predicate: predicate)
    
    database.performQuery(query, inZoneWithID: nil) {
      results, error in
      if error != nil {
        print(error?.localizedDescription)
        completion(rating: 0, isUser: false)
      } else {
        let resultsArray = results! as NSArray
        
        if let rating = resultsArray.valueForKeyPath("@avg.Rating") as? Double {
          completion(rating: rating, isUser: false)
        } else {
          completion(rating: 0, isUser: false)
        }
      }
    }
  }
  
  static func fetchAllFlights(database: CKDatabase, completion: (records: [CKRecord]?, error : NSError?) -> ()) {
    let predicate = NSPredicate(value:true)
    let query = CKQuery(recordType: "Flight", predicate: predicate)
    
    database.performQuery(query, inZoneWithID: nil) {
      results, error in
      if error != nil {
        print(error?.localizedDescription)
        completion(records: nil, error: error)
      } else {
        let resultsArray = results! as NSArray
        let records = resultsArray as? [CKRecord]
        completion(records: records, error: error)
      }
    }
  }

  static func addFlight(flightName name: String!,
                originAirport: String!,
                destinationAirport: String!,
                flightDateTime: NSDate!,
                flightDuration: Double!,
                flightUpdated: Bool!,
                database: CKDatabase,
                completion: (error : NSError?)-> ()) {
    let flightRecord = CKRecord(recordType: FlightRecordType)
    
    flightRecord["FlightName"] = name
    flightRecord["OriginAirport"] = originAirport
    flightRecord["DestinationAirport"] = destinationAirport
    flightRecord["FlightDateTime"] = flightDateTime
    flightRecord["FlightDuration"] = flightDuration
    flightRecord["FlightUpdated"] = flightUpdated

    database.saveRecord(flightRecord) {
      record, error in
      dispatch_async(dispatch_get_main_queue()) {
        completion(error: error)
      }
    }
  }
  
  static func deleteAllFlights(database : CKDatabase) {
    let predicate = NSPredicate(value: true)
    let query = CKQuery(recordType: "Flight", predicate: predicate)
    
    database.performQuery(query, inZoneWithID: nil) {
      results, error in
      var resultsArray = NSArray()
      if error != nil {
        print(error?.localizedDescription)
      } else {
        resultsArray = results! as NSArray
        print("Allflights query success record count:\(resultsArray.count)")
        
        for record in resultsArray {
          let recordID = (record as? CKRecord)!.recordID
          // print("Record ID to delete: \(recordID)")
          
          database.deleteRecordWithID(recordID) {
            recordId, error in
            if error != nil {
              print(error?.localizedDescription)
            } else {
              print("Delete confirmed: \(recordId)")
            }
          }
        }
      }
    }
  }
  
  static func uploadAllFlights(database : CKDatabase) {
    if let URL = NSBundle.mainBundle().URLForResource("Flights", withExtension: "plist") {
      if let flightsArray = NSArray(contentsOfURL: URL) {
        for flight in flightsArray {
          
          let flightName = flight["FlightName"] as? String
          let originAirport = flight["OriginAirport"] as? String
          let destinationAirport = flight["DestinationAirport"] as? String
          let flightDateTime = flight["FlightDateTime"] as? NSDate
          let flightDuration = flight["FlightDuration"] as? Double
          let flightUpdated = flight["Updated"] as? Bool
          
          Flight.addFlight(flightName: flightName, originAirport: originAirport, destinationAirport: destinationAirport, flightDateTime: flightDateTime, flightDuration: flightDuration, flightUpdated: flightUpdated, database: database) {
            error in
            if error != nil {
              print(error?.localizedDescription)
            } else {
              print("Flight added: \(flightName)")
            }
          }
        }
      }
    }
  }

}


