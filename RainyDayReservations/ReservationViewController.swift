//
//  ChangeFlightViewController.swift
//  RainyDayReservations
//
//  Created by Dan Coughlin on 4/3/16.
//  Copyright © 2016 GroovyTree LLC. All rights reserved.
//

import UIKit
import CloudKit

class ReservationViewController: UIViewController {
  
  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var tableView: UITableView!
  
  var menuItem: MenuItem?
  
  var sharedModel = Model.sharedInstance
  var sharedUser = User.sharedInstance
  
  var reservationTravelers = [Traveler]()
  var reservationFlights = [Flight]()
  
  var activityView : UIActivityIndicatorView?
  var isAnimatingActivity = false
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    if let menuItem = menuItem {
      navigationItem.title = menuItem.caption
      imageView.image = UIImage(named: menuItem.imageName)
    }
  
    startActivityIndicator()
    sharedModel.delegate = self
    sharedUser.delegate = self
    sharedUser.fetchUserID()
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
  
  func showNoReservationsAlert() {
    let title = "No Reservations"
    let message = "The are currently no reservations booked."
    let okButtonTitle = "OK"
    
    let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
    
    let okAction = UIAlertAction(title: okButtonTitle, style: .Default) { _ in }
    alertController.addAction(okAction)
    
    presentViewController(alertController, animated: true, completion: nil)
  }
}

extension ReservationViewController : ModelDelegate {
  
  // MARK: ModelDelegate
  
  func didUpdateModel(modelType: ModelType) {
    print("Model updated(Reservation): \(modelType)")
    
    switch modelType {
      case .Reservation:
        if sharedModel.reservations.isEmpty {
          stopActivityIndicator()
          dispatch_async(dispatch_get_main_queue()) {
            self.showNoReservationsAlert()
          }
        } else {
          if sharedModel.travelers.isEmpty {
            sharedModel.fetchTravelersWithUserID(sharedUser.userID)
          } else {
            reservationTravelers = sharedModel.reservations.map { sharedModel.travelerWithReference($0.travelerRef!) }
            if sharedModel.flights.isEmpty {
              sharedModel.fetchFlights()
            } else {
              reservationFlights = sharedModel.reservations.map { sharedModel.flightWithReference($0.flightRef!) }
              dispatch_async(dispatch_get_main_queue()) {
                self.tableView.reloadData()
              }
              self.stopActivityIndicator()
            }
          }
        }
    case .Traveler:
      reservationTravelers = sharedModel.reservations.map { sharedModel.travelerWithReference($0.travelerRef!) }
      if sharedModel.flights.isEmpty {
        sharedModel.fetchFlights()
      } else {
        reservationFlights = sharedModel.reservations.map { sharedModel.flightWithReference($0.flightRef!) }
        dispatch_async(dispatch_get_main_queue()) {
          self.tableView.reloadData()
        }
        stopActivityIndicator()
      }
    case .Flight:
      reservationFlights = sharedModel.reservations.map { sharedModel.flightWithReference($0.flightRef!) }
      dispatch_async(dispatch_get_main_queue()) {
        self.tableView.reloadData()
      }
      self.stopActivityIndicator()
    }
  }
  
  func didEncounterModelError(error: NSError?) {
    self.stopActivityIndicator()
    showError(error, inController: nil)
  }
}

extension ReservationViewController : UserDelegate {
  
  func didUpdateUser(userType: UserType) {
    print("User updated(Reservation): \(userType)")
    if userType == .UserID {
       sharedModel.fetchReservationsForWithUserID(sharedUser.userID)
    }
  }
  
  func didEncounterUserError(error: NSError?) {
    showError(error, inController: nil)
  }

}

extension ReservationViewController : UITableViewDataSource {
  
  // MARK: UITableViewDataSource
  
  func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 1
  }
  
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return sharedModel.reservations.count
  }
  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("ReservationCell") as! ReservationTableViewCell
    
    if !reservationTravelers.isEmpty {
      let travelerName = reservationTravelers[indexPath.row].name
      cell.travelerNameLabel.text = travelerName
    }
    
    if !reservationFlights.isEmpty {
      let flight = reservationFlights[indexPath.row]
      cell.flightDescriptionLabel.text = flight.description
      cell.flightDateTimeLabel.text = flight.flightDateTimeDescription
      cell.flightDurationLabel.text = flight.flightDurationDescription
    }
    
    return cell
  }
}
