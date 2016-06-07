//
//  UserInfo.swift
//  RainyDayReservations
//
//  Created by Dan Coughlin on 4/14/16.
//  Copyright © 2016 GroovyTree LLC. All rights reserved.
//

import UIKit
import CloudKit

enum UserType {
  case UserID
  case UserRecord
  case UserStatus
}

// `UserDelegate` exists to inform delegates of iCloud account status changes from either:
///    - a direct account status call to the container
///    - a notification from iCloud that a users status has changed (you must subscribe to this)
protocol UserDelegate: class {
  func didUpdateUser(userType: UserType)
  func didEncounterUserError(error: NSError?)
}

class User  {
  
  let container: CKContainer
  
  var userID: CKRecordID?
  var record: CKRecord?
  var iCloudAccountActive : Bool?
  
  /** A static type property is guaranteed to be lazily initialized only once;
   *  even when accessed across multiple threads.
   */
  static let sharedInstance = User()
  var delegate: UserDelegate?
  
  init() {
    self.container = CKContainer.defaultContainer()
  }
  
  // MARK: iCloud Account Status
  
  func updateCloudKitLoginStatus() {
    container.accountStatusWithCompletionHandler() {
      accountStatus, error in
      if error != nil {
        dispatch_async(dispatch_get_main_queue()) {
          self.delegate?.didEncounterUserError(error)
        }
      } else {
        self.iCloudAccountActive = (accountStatus == .Available)
        dispatch_async(dispatch_get_main_queue()) {
          self.delegate?.didUpdateUser(.UserStatus)
        }
      }
    }
  }
  
  // MARK: User ID
  
  func fetchUserID() {
    if self.userID != nil { //-- this doesn't change so save the network call
      dispatch_async(dispatch_get_main_queue()) {
        self.delegate?.didUpdateUser(.UserID)
      }
      return
    }
    
    container.fetchUserRecordIDWithCompletionHandler() {
      recordID, error in
      if let userID = recordID {
        self.userID = userID
        dispatch_async(dispatch_get_main_queue()) {
          self.delegate?.didUpdateUser(.UserID)
        }
      } else {
        dispatch_async(dispatch_get_main_queue()) {
          self.delegate?.didEncounterUserError(error)
        }
      }
    }
  }
  
}


