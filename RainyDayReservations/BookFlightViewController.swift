//
//  BookFlightViewController.swift
//  RainyDayReservations
//
//  Created by Dan Coughlin on 4/3/16.
//  Copyright © 2016 GroovyTree LLC. All rights reserved.
//

import UIKit
import CloudKit

class BookFlightViewController: UIViewController {
  
  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var tableView: UITableView!
  
  @IBOutlet weak var primaryTravelerImageView: UIImageView!
  @IBOutlet weak var primaryTravelerLabel: UILabel!
  
  var menuItem: MenuItem?
   
  var sharedModel = Model.sharedInstance
  var sharedUser = User.sharedInstance
  
  var isPrimaryTraveler = false
  var primaryTravelerIndex = 0
  
  var activityView : UIActivityIndicatorView?
  var isAnimatingActivity = false
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    if let menuItem = menuItem {
      navigationItem.title = menuItem.caption
      imageView.image = UIImage(named: menuItem.imageName)
    }
  }
  
  override func viewWillAppear(animated: Bool) {
    startActivityIndicator()
    sharedModel.delegate = self
    sharedUser.delegate = self
    
    if sharedModel.travelers.isEmpty {
      sharedUser.fetchUserID()
    } else {
      setPrimaryTraveler()
    }
    
    if sharedModel.flights.isEmpty {
      sharedModel.fetchFlights()
    } else {
      stopActivityIndicator()
    }
  }
  
  func bookReservationWithFlight(flight: Flight, traveler: Traveler) {
    startActivityIndicator()
    sharedModel.saveReservation(traveler.record.recordID,
                                flightRecordID: flight.record.recordID,
                                userRecordID: sharedUser.userID)
  }
  
  func setPrimaryTraveler() {
    if let primaryIndex = self.sharedModel.isPrimaryTraveler() {
      self.primaryTravelerLabel.text = "\(self.sharedModel.travelers[primaryIndex].name)"
      self.primaryTravelerIndex = primaryIndex
      self.isPrimaryTraveler = true
      
      self.sharedModel.travelers[primaryIndex].fetchPhoto {
        image in
        // All UI must be on the main thread
        dispatch_async(dispatch_get_main_queue()) {
          self.primaryTravelerImageView.circleWithBorderWidth(0.75)
          self.primaryTravelerImageView.image = image
        }
      }
    } else {
      self.primaryTravelerLabel.text = "Not defined."
    }
  }
  
  // MARK: Action Alerts
  
  func showReservationBookedAlert() {
    let title = "Success!"
    let message = "Reservation is now booked."
    let okButtonTitle = "OK"
    
    let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
    
    let okAction = UIAlertAction(title: okButtonTitle, style: .Default) { _ in }
    alertController.addAction(okAction)
    
    presentViewController(alertController, animated: true, completion: nil)
  }
  
  func showBookingAlertWithFlight(flight: Flight, traveler: Traveler) {
    let title = "Book Reservation"
    let message = "Book flight \(flight.flightName).\nFor traveler: \(traveler.name)."
    let cancelButtonTitle = "Cancel"
    let bookButtonTitle = "Book It"
    
    let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
    
    let cancelAction = UIAlertAction(title: cancelButtonTitle, style: .Cancel) { _ in }
    let bookFlightAction = UIAlertAction(title: bookButtonTitle, style: .Default) { _ in
      self.bookReservationWithFlight(flight, traveler: traveler)
    }
    
    alertController.addAction(cancelAction)
    alertController.addAction(bookFlightAction)
    
    presentViewController(alertController, animated: true, completion: nil)
  }
  
  func showNoPrimaryTravlerAlert() {
    let title = "No Primary Traveler"
    let message = "A primary traveler must be defined to book a flight."
    let okButtonTitle = "OK"
    
    let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
    
    let okAction = UIAlertAction(title: okButtonTitle, style: .Default) { _ in }
    alertController.addAction(okAction)
    
    presentViewController(alertController, animated: true, completion: nil)
  }
  
  func showNoFlightsAlert() {
    let title = "No Flights"
    let message = "The are currently no flights loaded.\nUse Agent Access to load a filght list."
    let okButtonTitle = "OK"
    
    let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
    
    let okAction = UIAlertAction(title: okButtonTitle, style: .Default) { _ in }
    alertController.addAction(okAction)
    
    presentViewController(alertController, animated: true, completion: nil)
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
      self.activityView?.stopAnimating()
      self.isAnimatingActivity = false
    }
  }
}

extension BookFlightViewController : ModelDelegate {
  
  // MARK: ModelDelegate

  func didUpdateModel(modelType: ModelType) {
    print("Model updated(Book): \(modelType)")
    switch modelType {
    case .Traveler:
      self.setPrimaryTraveler()
      self.tableView.reloadData()
    case .Flight:
      if sharedModel.flights.isEmpty {
        self.stopActivityIndicator()
        showNoFlightsAlert()
      } else {
        self.tableView.reloadData()
        self.stopActivityIndicator()
      }
    case .Reservation:
      self.stopActivityIndicator()
      showReservationBookedAlert()
    }
  }
  
  func didEncounterModelError(error: NSError?) {
    self.stopActivityIndicator()
    showError(error, inController: nil)
  }
}

extension BookFlightViewController : UserDelegate {

  func didUpdateUser(userType: UserType) {
    print("User updated(Book): \(userType)")
    if userType == .UserID {
      sharedModel.fetchTravelersWithUserID(sharedUser.userID)
    }
  }
  
  func didEncounterUserError(error: NSError?) {
    showError(error, inController: nil)
  }
  
}

extension BookFlightViewController : UITableViewDelegate {
  
  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    if isPrimaryTraveler {
      let flight = sharedModel.flights[indexPath.row]
      let traveler = sharedModel.travelers[primaryTravelerIndex]
      showBookingAlertWithFlight(flight, traveler: traveler )
    } else {
      showNoPrimaryTravlerAlert()
    }
  }
}

extension BookFlightViewController : UITableViewDataSource {
  
  // MARK: UITableViewDataSource
  
  func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 1
  }
  
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return sharedModel.flights.count
  }
  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let flightCell = tableView.dequeueReusableCellWithIdentifier("FlightCell") as! FlightTableViewCell
    
    let flight = sharedModel.flights[indexPath.row]
    flightCell.flightDescription.text = flight.description
    flightCell.flightDate.text = flight.flightDateTimeDescription
    flightCell.flightDuration.text = flight.flightDurationDescription
    flightCell.flightUpdated.text = flight.flightUpdated ? "UPDATED" : ""
    
    return flightCell
  }
}
