//
//  Passenger.swift
//  RainyDayReservations
//
//  Created by Dan Coughlin on 4/7/16.
//  Copyright © 2016 GroovyTree LLC. All rights reserved.
//

import UIKit
import CloudKit

let TravelerRecordType = "Traveler"

class Traveler : Equatable {
  static let PhotoSize = 120.0
  static let UnknownPhotoName : String = "UnknownPhoto"
  
  var name: String
  var age: Int
  var isPrimary: Bool
  var photo: UIImage?
 
  var record : CKRecord
  
  let backgroundQueue = NSOperationQueue()
  
  init(record: CKRecord) {
    self.record = record
    
    self.name = record["Name"] as? String ?? ""
    self.age = record["Age"] as? Int ?? 0
    self.isPrimary = record["Primary"] as? Bool ?? false
    self.photo = record["Photo"] as? UIImage ?? UIImage(named: Traveler.UnknownPhotoName)
  }
  
  func fetchPhoto(completion:(photo: UIImage?) -> ()) {
    
    // Although you download the asset at the same time that you retrieve the rest of the record, 
    // you want to load the image asynchronously, so wrap everything in a background thread operation block
    backgroundQueue.addOperationWithBlock() {
      let image = self.record["Photo"] as? CKAsset
      if let ckAsset = image {
        let url = ckAsset.fileURL
        if let imageData = NSData(contentsOfURL:url) {
          self.photo = UIImage(data: imageData)
        }
      }
      
      completion(photo: self.photo)
    }
  }
  
  func updateTravelerRecordWithUserID(userID : CKRecordID) {
    self.record["Name"] = self.name
    self.record["Age"] = self.age
    self.record["Primary"] = self.isPrimary ? 1 : 0
    self.record["User"] = CKReference(recordID: userID, action: .None)
    
    if self.photo != nil {
      if let photoURL = self.photo?.cacheImageDataLocally() {
        let photoAsset = CKAsset(fileURL: photoURL)
        self.record["Photo"] = photoAsset
      }
    }
  }
}

extension Traveler: CustomStringConvertible {
  var description : String {
    return "Traveler:\(name) Age:\(age) Primary Travler:\(isPrimary ? "YES" : "NO")"
  }
}


//Mark: Equatable

func == (lhs: Traveler, rhs: Traveler) -> Bool {
  return (lhs.record.recordID == rhs.record.recordID)
}


