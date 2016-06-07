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
private let airplaneEmojiFly = "✈︎"

struct Flight {
  var flightName: String
  var originAirport: String
  var destinationAirport: String
  var flightDateTime: NSDate
  var flightDuration: Double
  var flightUpdated: Bool
  
  var record : CKRecord
  
  init(record : CKRecord) {
    self.record = record
    
    self.flightName = record["FlightName"] as? String ?? ""
    self.originAirport = record["OriginAirport"] as? String ?? ""
    self.destinationAirport = record["DestinationAirport"] as? String ?? ""
    self.flightDateTime = record["FlightDateTime"] as? NSDate ?? NSDate()
    self.flightDuration = record["FlightDuration"] as? Double ?? 0.0
    self.flightUpdated =  record["FlightUpdated"] as? Bool ?? false
  }

  func updateFlightRecordWithFlight() {
    record["FlightName"] = self.flightName
    record["OriginAirport"] = self.originAirport
    record["DestinationAirport"] = self.destinationAirport
    record["FlightDateTime"] = self.flightDateTime
    record["FlightDuration"] = self.flightDuration
    record["FlightUpdated"] = self.flightUpdated
  }
}

extension Flight: CustomStringConvertible {
  var description : String {
    return "\(originAirport) \(airplaneEmojiFly) \(destinationAirport) / \(flightName)"
  }
  
  var flightDurationDescription : String {
    return String(format: "Duration: %.0fh %.0fm", flightDuration, 60 * (flightDuration % 1))
  }
  
  var flightDateTimeDescription: String {
    let formatter = NSDateFormatter()
    formatter.dateStyle = .MediumStyle
    formatter.timeStyle = .ShortStyle
    let dateString = formatter.stringFromDate(flightDateTime)
    return dateString
  }
}


