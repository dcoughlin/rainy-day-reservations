//
//  MenuItem.swift
//  RainyDayReservations
//
//  Created by Dan Coughlin on 3/30/16.
//  Copyright © 2016 GroovyTree LLC. All rights reserved.
//

import UIKit


// MARK: Global Constants

enum MenuAction : Int {
  case BookFlight
  case ChangeFlight
  case Travelers
  case Agent
}

class MenuItem {
  var caption: String
  var action: MenuAction
  var imageName: String
  var image: UIImage
  var active: Bool
  
  init(caption: String, action: MenuAction, imageName: String, image: UIImage, active: Bool) {
    self.caption = caption
    self.action = action
    self.imageName = imageName
    self.image = image
    self.active = active
  }
  
  convenience init(dict: NSDictionary) {
    let caption = dict["Caption"]  as? String
    let rawAction = dict["Action"] as? Int
    let menuAction =  MenuAction(rawValue: rawAction!)
    let imageName = dict["Photo"] as? String
    let image = UIImage(named: imageName!)?.decompressedImage
    let active = (dict["Active"] as? Int) == 1 ? true : false
    
    self.init(caption: caption!, action: menuAction!, imageName: imageName!, image: image!, active: active)
  }
  
  class func allMenuItems() -> [MenuItem] {
    var menuItems = [MenuItem]()
    if let URL = NSBundle.mainBundle().URLForResource("MenuItems", withExtension: "plist") {
      if let menuItemsPlistArray = NSArray(contentsOfURL: URL) {
        for dict in menuItemsPlistArray {
          let menuItem = MenuItem(dict: dict as! NSDictionary)
          if menuItem.active {
            menuItems.append(menuItem)
          }
        }
      }
    }
    return menuItems
  }
}
