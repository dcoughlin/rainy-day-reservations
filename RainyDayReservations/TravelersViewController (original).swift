//
//  TravelersViewController.swift
//  RainyDayReservations
//
//  Created by Dan Coughlin on 4/3/16.
//  Copyright © 2016 GroovyTree LLC. All rights reserved.
//

import UIKit
import CloudKit

///  Temp - for debugging
var currentTraveler : Traveler?

class TravelersViewController: UIViewController {
  
  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var tableView: UITableView!
  
  var menuItem: MenuItem?
  let backgroundQueue = NSOperationQueue()
  
  var sharedModel = Model.sharedInstance

  var activityView = UIActivityIndicatorView()
  var isAnimatingActivity = false
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    if let menuItem = menuItem {
      navigationItem.title = menuItem.caption
      imageView.image = UIImage(named: menuItem.imageName)
    }
    
    navigationItem.rightBarButtonItem = editButtonItem()
    tableView.allowsSelectionDuringEditing = true
 //   tableView.estimatedRowHeight = 120.0
 //   tableView.rowHeight = UITableViewAutomaticDimension
    
    configureInitialView()
    sharedModel.delegate = self
    sharedModel.fetchTravelers()
  }
  
  override func viewWillAppear(animated: Bool) {
    tableView.reloadData()
  }
  
  // Mark - Segue
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    let editViewController = segue.destinationViewController as? TravelerEditViewController
    
    if segue.identifier == "GotoEdit" {
      if let indexPath = tableView.indexPathForSelectedRow {
        let traveler = sharedModel.travelers[indexPath.row]
        editViewController?.traveler = traveler
      }
    }
  }
  
  // MARK: User Interface
  
  func configureInitialView() {
    addActivityIndicator()
    activityView.startAnimating()
    isAnimatingActivity = true
  }
  
  func addActivityIndicator() {
    activityView = UIActivityIndicatorView(frame: CGRectMake(0, 0, 40, 40))
    activityView.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.Gray
    activityView.center = CGPoint(x: self.view.center.x, y: self.view.center.y + 50)
    activityView.activityIndicatorViewStyle = .Gray
    activityView.hidesWhenStopped = true
    self.view.addSubview(activityView)
  }
}

extension TravelersViewController : ModelDelegate {
  
  // MARK: ModelDelegate
  
  func didUpdateModel() {
    let mainQueue = NSOperationQueue.mainQueue()
    mainQueue.addOperationWithBlock() {
      if self.isAnimatingActivity {
        self.activityView.stopAnimating()
        self.isAnimatingActivity = false
      }
      self.tableView.reloadData()
      
      if let object = self.sharedModel.travelers.first {
        // aobject.subscribe()
        currentTraveler = object
      }
    }
  }
  
  func didEncounterCKAccessError(error: NSError?) {
    showError(error, controller: self)
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
      cell.detailTextLabel?.text = nil
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
      
      sharedModel.travelers.removeAtIndex(indexPath.row)
      tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation:.Automatic)
      
    } else if editingStyle == .Insert {

      let record = CKRecord(recordType: TravelerRecordType)
      let newTraveler = Traveler(record: record , database:sharedModel.publicDB)
      sharedModel.travelers.append(newTraveler)
      tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
    }
  }

}

extension TravelersViewController : UITableViewDelegate {
  
  func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
    print("editingStyleForRowAtIndexPath: \(indexPath.row)")
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
}