
//
//  Model.swift
//  RainyDayReservations
//
//  Created by Dan Coughlin on 4/14/16.
//  Copyright © 2016 GroovyTree LLC. All rights reserved.
//

import UIKit
import CloudKit

enum StorageMode {
  case Create
  case Read
  case Update
  case Delete
}

enum ModelType {
  case Flight
  case Traveler(mode : StorageMode)
  case Reservation(mode : StorageMode)
}

protocol ModelDelegate {
  func didUpdateModel(modelType: ModelType)
  func didEncounterModelError(error: NSError?)
}

let UserIDnotInitializedLogMsg = "Error: userID not initialized in data Model."
let TempRecordName = "TEMPORARY"
let tempRecordID = CKRecordID(recordName: TempRecordName)

class Model {
  
  /** A static type property is guaranteed to be lazily initialized only once;
   *  even when accessed across multiple threads.
   */
  static let sharedInstance = Model()
  var delegate : ModelDelegate?
  
  var travelers = [Traveler]()
  var flights = [Flight]()
  var reservations = [Reservation]()
  
  let container: CKContainer
  let publicDB: CKDatabase
  let privateDB: CKDatabase
  
  init() {
    self.container = CKContainer.defaultContainer()
    self.publicDB = container.publicCloudDatabase
    self.privateDB = container.privateCloudDatabase
  }
    
  func fetchTravelersWithUserID(userID: CKRecordID?) {
    guard let userID = userID else {
      print(UserIDnotInitializedLogMsg)
      return
    }
    
    let predicate = NSPredicate(format: "User = %@", userID)
    let query = CKQuery(recordType: TravelerRecordType, predicate: predicate)
    
    let sortDescriptor = NSSortDescriptor(key: "Primary", ascending: false)
    query.sortDescriptors = [sortDescriptor]
    
    print("Fetching all travelers...")
    publicDB.performQuery(query, inZoneWithID: nil) { results, error in
      if error != nil {
        print("Error fetching Traveler: \(error?.localizedDescription ?? "No description")")
        self.delegate?.didEncounterModelError(error!)
      } else {
        self.travelers.removeAll(keepCapacity: true)
        for record in results! {
          let traveler = Traveler(record: record)
          self.travelers.append(traveler)
          print("Traveler fetched: \(record.recordID.recordName)")
        }
        self.delegate?.didUpdateModel(.Traveler(mode: .Read))
      }
    }
  }
  
  func deleteTravelersWithUserID(userID: CKRecordID?) {
    guard let userID = userID else {
      print(UserIDnotInitializedLogMsg)
      return
    }
    self.travelers.removeAll()
    
    let predicate = NSPredicate(format: "User = %@", userID)
    let query = CKQuery(recordType: TravelerRecordType, predicate: predicate)
    
    print("Deleting all travelers for user: \(userID)...")
    publicDB.performQuery(query, inZoneWithID: nil) {
      results, error in
      var resultsArray = NSArray()
      if error != nil {
        print("Error deleting all travelers: \(error?.localizedDescription)")
        self.delegate?.didEncounterModelError(error!)
      } else {
        resultsArray = results! as NSArray
        for record in resultsArray {
          let recordID = (record as? CKRecord)!.recordID
          self.deleteTravelerWithRecordID(recordID)
        }
      }
    }
  }

  func saveTraveler(record: CKRecord) {
    publicDB.saveRecord(record) {
      record, error in
      if error != nil {
        print("Error saving Traveler: \(error?.localizedDescription)")
        self.delegate?.didEncounterModelError(error!)
      } else {
        if let recordName = record?.recordID.recordName {
          print("Traveler saved: \(recordName)")
        }
        self.delegate?.didUpdateModel(.Traveler(mode: .Create))
      }
    }
  }
  
  func deleteTravelerWithRecordID(recordID : CKRecordID) {
    publicDB.deleteRecordWithID(recordID) {
      recordID, error in
      if error != nil {
        print("Error deleting Traveler: \(error?.localizedDescription)")
        self.delegate?.didEncounterModelError(error!)
      } else {
        if let recordName = recordID?.recordName {
          print("Traveler deleted: \(recordName)")
        }
        self.delegate?.didUpdateModel(.Traveler(mode: .Delete))
      }
    }
  }
  
  func fetchTravelerWithRecordID(recordID : CKRecordID) {
    publicDB.fetchRecordWithID(recordID) {
      record, error in
      if error != nil {
        print("Error fetching Traveler: \(error?.localizedDescription)")
        self.delegate?.didEncounterModelError(error!)
      } else {
        if let recordName = record?.recordID.recordName {
          print("Reservation Traveler fetched: \(recordName)")
        }
        self.delegate?.didUpdateModel(.Traveler(mode: .Read))
      }
    }
  }
  
  func fetchReservationTravelerWithRecordID(recordID : CKRecordID, inout traveler: Traveler?) {
    publicDB.fetchRecordWithID(recordID) {
      record, error in
      if error != nil {
        print("Error fetching Reservation Traveler: \(error?.localizedDescription)")
        self.delegate?.didEncounterModelError(error!)
      } else {
        if let record = record {
          let recordName = record.recordID.recordName
          print("Traveler fetched: \(recordName)")
          traveler = Traveler(record: record)
          print(traveler?.description)
        }
        self.delegate?.didUpdateModel(.Traveler(mode: .Read))
      }
    }
  }
  
  func isPrimaryTraveler() -> Int? {
    var primaryIdx : Int?
    
    for (idx, traveler) in travelers.enumerate() {
      if traveler.primary {
        primaryIdx = idx
        break
      }
    }
    return primaryIdx
  }
  
  func travelerWithReference(ref: CKReference) -> Traveler! {
    let matchingTravelers = travelers.filter {$0.record.recordID == ref.recordID }
    var traveler : Traveler!
    if matchingTravelers.count > 0 {
      traveler = matchingTravelers[0]
    }
    return traveler
  }
  
  // MARK: Flights
  
  func fetchFlights() {
    let flightPredicate = NSPredicate(format: "FlightDuration != 0.0")  //-- Don't use true predicate, since recordID is not queryable by default
    let query = CKQuery(recordType: FlightRecordType, predicate: flightPredicate)
    
    let sortDescriptor = NSSortDescriptor(key: "FlightDateTime", ascending: true)
    query.sortDescriptors = [sortDescriptor]
    
    print("Fetching all flights...")
    publicDB.performQuery(query, inZoneWithID: nil) { results, error in
      if error != nil {
        print("Error fetching Flight: \(error?.localizedDescription)")
        self.delegate?.didEncounterModelError(error!)
      } else {
        self.flights.removeAll(keepCapacity: true)
        for record in results! {
          let flight = Flight(record: record)
          self.flights.append(flight)
          print("Flight fetched: \(record.recordID.recordName)")
        }
        self.delegate?.didUpdateModel(.Flight)
      }
    }
  }
  
  func deleteFlightWithRecordID(recordID : CKRecordID) {
    publicDB.deleteRecordWithID(recordID) {
      recordID, error in
      if error != nil {
        print("Error deleting Flight: \(error?.localizedDescription)")
        self.delegate?.didEncounterModelError(error!)
      } else {
        if let recordName = recordID?.recordName {
          print("Flight deleted: \(recordName)")
        }
        self.delegate?.didUpdateModel(.Flight)
      }
    }
  }
  
  func saveFlight(record: CKRecord) {
    publicDB.saveRecord(record) {
      record, error in
      if error != nil {
        print("Error saving Flight: \(error?.localizedDescription)")
        self.delegate?.didEncounterModelError(error!)
      } else {
        if let recordName = record?.recordID.recordName {
          print("Flight saved: \(recordName)")
        }
        self.delegate?.didUpdateModel(.Flight)
      }
    }
  }
  
  func deleteFlights() {
    self.flights.removeAll()
    
    let flightPredicate = NSPredicate(format: "FlightDuration != 0.0")  //-- Don't use true predicate, since recordID is not queryable by default
    let query = CKQuery(recordType: FlightRecordType, predicate: flightPredicate)
    
    print("Deleting all flights...")
    publicDB.performQuery(query, inZoneWithID: nil) {
      results, error in
      var resultsArray = NSArray()
      if error != nil {
        print("Error deleting all flights: \(error?.localizedDescription)")
        self.delegate?.didEncounterModelError(error!)
      } else {
        resultsArray = results! as NSArray
        for record in resultsArray {
          let recordID = (record as? CKRecord)!.recordID
          self.deleteFlightWithRecordID(recordID)
        }
      }
    }
  }
  
  func flightWithReference(ref: CKReference) -> Flight! {
    let matchingFlights = flights.filter {$0.record.recordID == ref.recordID }
    var flight : Flight!
    if matchingFlights.count > 0 {
      flight = matchingFlights[0]
    }
    return flight
  }
  
  func seedFlightsFromPlist(plistName: String) {
    if let URL = NSBundle.mainBundle().URLForResource(plistName, withExtension: "plist") {
      if let flightsArray = NSArray(contentsOfURL: URL) {
        print("Seeding flights from plist: \(plistName)...")
        for flightItem in flightsArray {
          let record = CKRecord(recordType: FlightRecordType)
          var flight = Flight(record: record)
          
          flight.flightName = flightItem["FlightName"] as? String ?? ""
          flight.originAirport = flightItem["OriginAirport"] as? String ?? ""
          flight.destinationAirport = flightItem["DestinationAirport"] as? String ?? ""
          flight.flightDateTime = flightItem["FlightDateTime"] as? NSDate ?? NSDate()
          flight.flightDuration = flightItem["FlightDuration"] as? Double ?? 2.5
          flight.flightUpdated = flightItem["Updated"] as? Bool ?? false
          flight.updateFlightRecordWithFlight()
          
          self.saveFlight(record)
        }
      }
    }
  }

  // MARK: Reservations
  
  func fetchReservationsForWithUserID(userID: CKRecordID?) {
    
    print("Fetching current user reservations...")
    guard let userID = userID else {
      print(UserIDnotInitializedLogMsg)
      return
    }
      
    let predicate = NSPredicate(format: "User = %@", userID)
    let sortDescriptor = NSSortDescriptor(key: "BookingDate", ascending: true)
    
    let query = CKQuery(recordType: ReservationRecordType, predicate: predicate)
    query.sortDescriptors = [sortDescriptor]
    
    publicDB.performQuery(query, inZoneWithID: nil) { results, error in
      if error != nil {
        print("Error fetching reservations: \(error?.localizedDescription)")
        self.delegate?.didEncounterModelError(error!)
      } else {
        self.reservations.removeAll(keepCapacity: true)
        for record in results! {
          let reservation = Reservation(record: record)
          self.reservations.append(reservation)
          print("Reservation fetched: \(record.recordID.recordName)")
        }
        self.delegate?.didUpdateModel(.Reservation(mode: .Read))
      }
    }
  }
  
  func saveReservation(travelerRecordID: CKRecordID?, flightRecordID: CKRecordID?, userRecordID: CKRecordID?) {
    let reservationRecord = CKRecord(recordType: ReservationRecordType)
    
    reservationRecord["BookingDate"] = NSDate()
    if let travelerRecordID = travelerRecordID {
      reservationRecord["Traveler"] = CKReference(recordID: travelerRecordID, action: .DeleteSelf)
    }
    
    if let flightRecordID = flightRecordID{
      reservationRecord["Flight"] = CKReference(recordID: flightRecordID, action: .DeleteSelf)
    }
    
    if let userRecordID = userRecordID {
      reservationRecord["User"] = CKReference(recordID: userRecordID, action: .None)
    }
    
    publicDB.saveRecord(reservationRecord) {
      record, error in
      if error != nil {
        print("Error saving Reservation: \(error?.localizedDescription)")
        self.delegate?.didEncounterModelError(error!)
      } else {
        if let recordName = record?.recordID.recordName {
          print("Reservation saved: \(recordName)")
        }
        self.delegate?.didUpdateModel(.Reservation(mode: .Create))
      }
    }
  }
  
  func deleteReservationWithRecordID(recordID : CKRecordID) {
    publicDB.deleteRecordWithID(recordID) {
      recordID, error in
      if error != nil {
        print("Error deleting Reservation: \(error?.localizedDescription)")
        self.delegate?.didEncounterModelError(error!)
      } else {
        if let recordName = recordID?.recordName {
          print("Reservation deleted: \(recordName)")
        }
        self.delegate?.didUpdateModel(.Reservation(mode: .Delete))
      }
    }
  }
  
  func deleteReservationsWithUserID(userID: CKRecordID?)  {
    guard let userID = userID else {
      print(UserIDnotInitializedLogMsg)
      return
    }
    self.reservations.removeAll()
    
    let userPredicate = NSPredicate(format: "User = %@", userID)
    let query = CKQuery(recordType: ReservationRecordType, predicate: userPredicate)
    
    print("Deleting all reservations for user: \(userID)...")
    publicDB.performQuery(query, inZoneWithID: nil) {
      results, error in
      var resultsArray = NSArray()
      if error != nil {
        print("Error deleting all reservations: \(error?.localizedDescription)")
        self.delegate?.didEncounterModelError(error!)
      } else {
        resultsArray = results! as NSArray
        for record in resultsArray {
          let recordID = (record as? CKRecord)!.recordID
          self.deleteReservationWithRecordID(recordID)
        }
      }
    }
  }
  
  // MARK: Just-in-time Record Type Schemas
  
  func createJustInTimeSchemasAndAddFlights() {
    print("Checking if just-in-time record type schemas needed...")
    
    let tempPredicate = NSPredicate(format: "User = %@", tempRecordID)
    // Traveler Record Type
    let travelerQuery = CKQuery(recordType: TravelerRecordType, predicate: tempPredicate)
    publicDB.performQuery(travelerQuery, inZoneWithID: nil) {
      _, error in
      if error != nil {
        let ckErrorCode = CKErrorCode(rawValue: error!.code)!
        if ckErrorCode == .UnknownItem {
          print("Creating Traveler record type...")
          let record = CKRecord(recordType: TravelerRecordType)
          let traveler = Traveler(record: record)
          traveler.updateTravelerRecordWithUserID(tempRecordID)
          self.saveTraveler(traveler.record)
        } else {
          self.delegate?.didEncounterModelError(error!)
        }
      } else {
        print("Traveler record type is defined.")
      }
    }
    
    // Reservation Record Type
    let reservationQuery = CKQuery(recordType: ReservationRecordType, predicate: tempPredicate)
    publicDB.performQuery(reservationQuery, inZoneWithID: nil) {
      _, error in
      if error != nil {
        let ckErrorCode = CKErrorCode(rawValue: error!.code)!
        if ckErrorCode == .UnknownItem {
          print("Creating Reservation record type...")
          self.saveReservation(tempRecordID, flightRecordID: tempRecordID, userRecordID: tempRecordID)
        } else {
          self.delegate?.didEncounterModelError(error!)
        }
      } else {
        print("Reservation record type is defined.")
      }
    }
    
    // Flight Record Type
    let flightPredicate = NSPredicate(format: "FlightDuration != 0.0")  //-- Don't use true predicate, since recordID is not queryable by default
    let flightQuery = CKQuery(recordType: FlightRecordType, predicate: flightPredicate)
    publicDB.performQuery(flightQuery, inZoneWithID: nil) {
      _, error in
      if error != nil {
        let ckErrorCode = CKErrorCode(rawValue: error!.code)!
        if ckErrorCode == .UnknownItem {
          print("Creating Flight record type and flights...")
          self.seedFlightsFromPlist("Flights")
        } else {
          self.delegate?.didEncounterModelError(error!)
        }
      } else {
        print("Flight record type is defined and default flights are loaded.")
      }
    }

    
  }

}

