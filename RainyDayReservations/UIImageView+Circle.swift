//
//  UIImageView+Circle.swift
//  RainyDayReservations
//
//  Created by Dan Coughlin on 5/14/16.
//  Copyright © 2016 GroovyTree LLC. All rights reserved.
//

import UIKit

extension UIImageView {
  
  func circleWithBorderWidth(borderWidth: CGFloat) -> UIImageView {
    self.layer.cornerRadius = self.frame.size.width / 2
    self.clipsToBounds = true
    self.layer.borderWidth = borderWidth
    self.layer.borderColor = UIColor.blueColor().CGColor
    return self
  }

}
