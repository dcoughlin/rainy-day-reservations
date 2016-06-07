//
//  Reservation.swift
//  RainyDayReservations
//
//  Created by Dan Coughlin on 4/19/16.
//  Copyright © 2016 GroovyTree LLC. All rights reserved.
//

import UIKit
import CloudKit

let ReservationRecordType = "Reservation"

struct Reservation {
  var travelerRef: CKReference?
  var flightRef: CKReference?
  
  var record : CKRecord
  
  init(record : CKRecord) {
    self.record = record
     
    self.travelerRef = record["Traveler"] as? CKReference
    self.flightRef = record["Flight"] as? CKReference
  }
}