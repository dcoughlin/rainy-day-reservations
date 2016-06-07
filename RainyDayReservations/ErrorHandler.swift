//
//  ErrorHandler.swift
//  RainyDayReservations
//
//  Created by Dan Coughlin on 4/25/16.
//  Copyright © 2016 GroovyTree LLC. All rights reserved.
//

import Foundation
import UIKit
import CloudKit

func showError(error: NSError?, inController controller: UIViewController?) {
  var controller = controller  //-- Do this instead of `var` parameter because it will be removed 
                               //   in Swift 3 to avoid confusion with `inout` call-by-reference parameter
  
  if controller == nil {
    //-- Prevent 'Presenting view controllers on detached view controllers is discourage' warnings
    controller = UIApplication.sharedApplication().windows.first!.rootViewController!
  }
  
  let title = "An Error Occurred"
  var message = error?.localizedDescription ?? ""
  
  //-- Give as much technical detail as we can garner from the system for CloudKit specific errors
  if error?.domain == CKErrorDomain {
    let ckErrorCode = CKErrorCode(rawValue: error!.code)!
    message += ".\n\(ckErrorCode.rawValue): \(getCloudKitErrorDetail(ckErrorCode))"
  }
  
  let acceptButtonTitle = "OK"
  let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
  
  let acceptAction = UIAlertAction(title: acceptButtonTitle, style: .Cancel) { _ in }
  alertController.addAction(acceptAction)
  
  dispatch_async(dispatch_get_main_queue()) {
    controller?.presentViewController(alertController, animated: true, completion: nil)
  }
}

// Current list of error codes that can be returned by CloudKit 
//   taken from CKError.h
//
private func getCloudKitErrorDetail(ckErrorCode : CKErrorCode) -> String {
  var errorDesc = ""
  
  switch (ckErrorCode)  {
  case .NotAuthenticated: errorDesc = "Not authenticated, log into iCloud in Settings."
  case .InternalError:  errorDesc = "CloudKit.framework encountered an error."
  case .PartialFailure:  errorDesc = "Some items failed, but the operation succeeded overall."
  case .NetworkUnavailable: errorDesc = "Network not available."
  case .NetworkFailure: errorDesc = "Network error (available but CFNetwork gave us an error)"
  case .BadContainer: errorDesc = "Un-provisioned or unauthorized container."
  case .ServiceUnavailable: errorDesc = "Service unavailable"
  case .RequestRateLimited: errorDesc = "Client is being rate limited"
  case .MissingEntitlement: errorDesc = "Missing entitlement."
  case .PermissionFailure: errorDesc = "Access failure (save or fetch)."
  case .UnknownItem: errorDesc = "Record does not exist"
  case .InvalidArguments: errorDesc = "Bad client request (bad record graph, malformed predicate)"
  case .ResultsTruncated: errorDesc = "Query results were truncated by the server"
  case .ServerRecordChanged: errorDesc = "The record was rejected because the version on the server was different."
  case .ServerRejectedRequest: errorDesc = "The server rejected this request."
  case .AssetFileNotFound: errorDesc = "Asset file was not found"
  case .AssetFileModified: errorDesc = "Asset file content was modified while being saved"
  case .IncompatibleVersion: errorDesc = "App version is less than the minimum allowed version."
  case .ConstraintViolation: errorDesc = "The server rejected the request because there was a conflict with a unique field."
  case .OperationCancelled:  errorDesc = "A CKOperation was explicitly cancelled."
  case .ChangeTokenExpired:  errorDesc = "The previousServerChangeToken value is too old and the client must re-sync from scratch."
  case .BatchRequestFailed:  errorDesc = "One of the items in this batch operation failed in a zone with atomic updates, so the entire batch was rejected."
  case .ZoneBusy: errorDesc = "The server is too busy to handle this zone operation."
  case .BadDatabase: errorDesc = "Operation could not be completed on the given database. Likely caused by attempting to modify zones in the public database."
  case .QuotaExceeded: errorDesc = "Saving a record would exceed quota."
  case .ZoneNotFound: errorDesc = "The specified zone does not exist on the server."
  case .LimitExceeded: errorDesc = "The request to the server was too large. Retry this request as a smaller batch."
  case .UserDeletedZone: errorDesc = "The user deleted this zone through the settings UI."
  }
  
  return errorDesc
}
