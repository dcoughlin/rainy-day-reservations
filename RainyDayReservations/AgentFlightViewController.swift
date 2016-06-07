//
//  AgentFlightViewController.swift
//  RainyDayReservations
//
//  Created by Dan Coughlin on 4/3/16.
//  Copyright © 2016 GroovyTree LLC. All rights reserved.
//

import UIKit

class AgentViewController: UIViewController {
  
  @IBOutlet weak var imageView: UIImageView!
  
  var menuItem: MenuItem?

  var sharedModel = Model.sharedInstance
  var sharedUser = User.sharedInstance
  var modelType : ModelType = .Flight
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    if let menuItem = menuItem {
      navigationItem.title = menuItem.caption
      imageView.image = UIImage(named: menuItem.imageName)
    }
    
    sharedModel.delegate = self
    sharedUser.delegate = self
  }
  
  override func viewWillAppear(animated: Bool) {
    sharedModel.delegate = self
  }

  
  @IBAction func addFlightsFromPlist(sender: AnyObject) {
    sharedModel.flights.removeAll()  //-- Force reload of flights
    sharedModel.seedFlightsFromPlist("Flights")
  }
  
  @IBAction func deleteAllFlights(sender: AnyObject) {
    sharedModel.deleteFlights()
  }
 
  @IBAction func deleteAllTravelers(sender: AnyObject) {
    sharedModel.deleteTravelersWithUserID(tempRecordID)  
    modelType = .Traveler(mode: .Delete)
    sharedUser.fetchUserID()
  }
  
  @IBAction func deleteAllReservations(sender: AnyObject) {
    sharedModel.deleteReservationsWithUserID(tempRecordID)
    modelType = .Reservation(mode: .Delete)
    sharedUser.fetchUserID()
  }
  
}

extension AgentViewController : ModelDelegate {
  
  // MARK: ModelDelegate
  
  func didUpdateModel(modelType: ModelType) {
    print("Model updated(Agent): \(modelType)")
  }
  
  func didEncounterModelError(error: NSError?) { 
    showError(error, inController: nil)
  }
}

extension AgentViewController : UserDelegate {
  
  func didUpdateUser(userType: UserType) {
    print("User updated(Master): \(userType)")
    if userType == .UserID {
      switch modelType {
        case .Traveler:
          sharedModel.deleteTravelersWithUserID(sharedUser.userID)
        case .Reservation:
          sharedModel.deleteReservationsWithUserID(sharedUser.userID)
        default:
          print("Error: Unhandled model type: \(modelType)")
      }
    }
  }
  
  func didEncounterUserError(error: NSError?) {
    showError(error, inController: nil)
  }
}

