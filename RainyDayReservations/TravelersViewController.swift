//
//  TravelersViewController.swift
//  RainyDayReservations
//
//  Created by Dan Coughlin on 4/3/16.
//  Copyright © 2016 GroovyTree LLC. All rights reserved.
//

import UIKit
import CloudKit

class TravelersViewController: UIViewController {
  
  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var tableView: UITableView!
  
  var menuItem: MenuItem?
  
  var sharedModel = Model.sharedInstance
  var sharedUser = User.sharedInstance

  var activityView : UIActivityIndicatorView?
  var isAnimatingActivity = false
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    if let menuItem = menuItem {
      navigationItem.title = menuItem.caption
      imageView.image = UIImage(named: menuItem.imageName)
    }
    
    navigationItem.rightBarButtonItem = editButtonItem()
    tableView.allowsSelectionDuringEditing = true  // Otherwise, you have to press small + cirlce to add a Traveler instead of the row
    
    startActivityIndicator()
    sharedModel.delegate = self
    sharedUser.delegate = self
    sharedUser.fetchUserID()
  }

  // Mark - Segue
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    let editViewController = segue.destinationViewController as? TravelerEditViewController
    
    if segue.identifier == "GotoDetail" {
      if let indexPath = tableView.indexPathForSelectedRow {
        let traveler = sharedModel.travelers[indexPath.row]
        editViewController?.traveler = traveler
      }
    }
  }
  
  // MARK: User Interface
  
  func addActivityIndicator() {
    if activityView == nil {
      activityView = UIActivityIndicatorView()
      activityView?.activityIndicatorViewStyle = .Gray
      activityView?.center = CGPoint(x: self.view.center.x, y: self.view.center.y)
      activityView?.hidesWhenStopped = true
      self.view.addSubview(activityView!)
    }
  }
  
  func startActivityIndicator() {
    if !self.isAnimatingActivity {
      addActivityIndicator()
      activityView?.startAnimating()
      isAnimatingActivity = true
    }
  }
  
  func stopActivityIndicator() {
    if self.isAnimatingActivity {
      dispatch_async(dispatch_get_main_queue()) {
        self.activityView?.stopAnimating()
      }
      self.isAnimatingActivity = false
    }
  }
}

extension TravelersViewController : ModelDelegate {
  
  // MARK: ModelDelegate
  
  func didUpdateModel(modelType: ModelType) {
    print("Model updated(Travelers): \(modelType)")
    self.stopActivityIndicator()
    if sharedModel.travelers.isEmpty {
      dispatch_async(dispatch_get_main_queue()) {
        self.setEditing(true, animated: true)
      }
    } else {
      dispatch_async(dispatch_get_main_queue()) {
        self.tableView.reloadData()
      }
    }
  }
  
  func didEncounterModelError(error: NSError?) {
    self.stopActivityIndicator()
    showError(error, inController: nil)  //-- Don't set controller since this can be trigger by child view controller as well
  }
}

extension TravelersViewController : UserDelegate {
  
  // MARK: UserDelegate
  
  func didUpdateUser(userType: UserType) {
    print("User updated(Travelers)): \(userType)")
    if userType == .UserID {
      sharedModel.fetchTravelersWithUserID(sharedUser.userID)
    }
  }
  
  func didEncounterUserError(error: NSError?) {
    showError(error, inController: nil)
  }
  
}

extension TravelersViewController : UITableViewDataSource {
  
  // MARK: UITableViewDataSource
  
  func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 1
  }
  
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    let adjustment = self.editing ? 1 : 0
    
    return sharedModel.travelers.count + adjustment
  }
  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    
    let cell : UITableViewCell
    
    if indexPath.row >= sharedModel.travelers.count  &&  editing {
      cell = tableView.dequeueReusableCellWithIdentifier("NewTravelerCell", forIndexPath: indexPath)
      cell.textLabel?.text = "Add Traveler"
      cell.imageView?.image = nil
    } else {
      cell = tableView.dequeueReusableCellWithIdentifier("TravelerCell") as! TravelerTableViewCell
      
      if let travelerCell = cell as? TravelerTableViewCell {
        let traveler = sharedModel.travelers[indexPath.row]
        let name = traveler.name
        travelerCell.name.text = name

        traveler.fetchPhoto {
          image in
          // All UI must be on the main thread
          dispatch_async(dispatch_get_main_queue()) {
            travelerCell.photo.circleWithBorderWidth(0.75)
            travelerCell.photo.image = image
          }
        }
      }
    }
    
    return cell
  }
  
  override func setEditing(editing: Bool, animated: Bool) {
    super.setEditing(editing, animated: animated)
    if editing {
      let indexPath = NSIndexPath(forRow: sharedModel.travelers.count, inSection: 0)
      tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
      tableView.setEditing(true, animated: true)
    } else {
      let indexPath = NSIndexPath(forRow: sharedModel.travelers.count, inSection: 0)
      tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
      tableView.setEditing(false, animated: true)
    }
  }
  
  func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
   
    if editingStyle == .Delete {
      
      let traveler = sharedModel.travelers[indexPath.row]
      sharedModel.travelers.removeAtIndex(indexPath.row)
      tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation:.Automatic)
      
      startActivityIndicator()
      sharedModel.deleteTravelerWithRecordID(traveler.record.recordID)
      
    } else if editingStyle == .Insert {

      let record = CKRecord(recordType: TravelerRecordType)
      let newTraveler = Traveler(record: record)
      newTraveler.name = "Unnamed Traveler"
      newTraveler.photo = UIImage(named: Traveler.UnknownPhotoName)
      newTraveler.primary = sharedModel.travelers.isEmpty ? true : false
      
      sharedModel.travelers.append(newTraveler)
      tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
      
      guard let userID = sharedUser.userID else {
        print(UserIDnotInitializedLogMsg)
        return
      }
      newTraveler.updateTravelerRecordWithUserID(userID)
      
      startActivityIndicator()
      sharedModel.saveTraveler(record)
    }
  }

}

extension TravelersViewController : UITableViewDelegate {
  
  // MARK: UITableViewDelegate
  
  func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
    if indexPath.row >= sharedModel.travelers.count {
      return .Insert
    } else {
      return .Delete
    }
  }
  
  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    tableView.deselectRowAtIndexPath(indexPath, animated: true)
    
    if editing && indexPath.row >= sharedModel.travelers.count {
      self.tableView(tableView, commitEditingStyle: .Insert, forRowAtIndexPath: indexPath)
    }
  }
  
  func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
    if editing && indexPath.row < sharedModel.travelers.count {
      return nil
    }
    return indexPath
  }
}