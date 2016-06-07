//
//  MenuViewController.swift
//  RainyDayReservations
//
//  Created by Dan Coughlin on 3/30/16.
//  Copyright © 2016 GroovyTree LLC. All rights reserved.
//

import UIKit

// MARK: Local Constants

private let reservationSegueId = "MasterToReservation"
private let bookSegueId   = "MasterToBook"
private let travelersSegueId = "MasterToTravelers"
private let agentSegueId = "MasterToAgent"

class MenuViewController: UICollectionViewController {
  
  private var menuItems = MenuItem.allMenuItems()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let frame_width = CGRectGetWidth(collectionView!.frame)
    let itemWidth = (frame_width / 2)-1
    let layout = collectionViewLayout as? UICollectionViewFlowLayout
    layout?.itemSize = CGSize(width: itemWidth, height: itemWidth)
  }
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    switch segue.identifier! {
    case bookSegueId:
      let detailViewController = segue.destinationViewController as! BookFlightViewController
      detailViewController.menuItem = sender as? MenuItem
    case reservationSegueId:
      let detailViewController = segue.destinationViewController as! ReservationViewController
      detailViewController.menuItem = sender as? MenuItem
    case travelersSegueId:
      let detailViewController = segue.destinationViewController as! TravelersViewController
      detailViewController.menuItem = sender as? MenuItem
    case agentSegueId:
      let detailViewController = segue.destinationViewController as! AgentViewController
      detailViewController.menuItem = sender as? MenuItem
    default:
      fatalError("Undefined seque id:\(segue.identifier!)")
    }
  }
}

extension MenuViewController {
  
  // MARK: UICollectionViewDataSource
  
  override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
    return 1
  }
  
  override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return menuItems.count
  }
  
  override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCellWithReuseIdentifier("AnnotatedMenuCell", forIndexPath: indexPath) as? AnnotatedMenuCell
    cell?.menuItem = menuItems[indexPath.item]
    return cell!
  }
  
  // MARK: UICollectionViewDelegate
  
  override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {

    let menuItem = menuItems[indexPath.item]
    switch menuItem.action {
    case .BookFlight:
      performSegueWithIdentifier(bookSegueId, sender: menuItem)
    case .ChangeFlight:
      performSegueWithIdentifier(reservationSegueId, sender: menuItem)
    case .Travelers:
      performSegueWithIdentifier(travelersSegueId, sender: menuItem)
    case .Agent:
       performSegueWithIdentifier(agentSegueId, sender: menuItem)
    }
  }
}

