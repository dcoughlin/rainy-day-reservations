//
//  AnnotatedMenuCell.swift
//  RainyDayReservations
//
//  Created by Dan Coughlin on 3/30/16.
//  Copyright © 2016 GroovyTree LLC. All rights reserved.
//

import UIKit

class AnnotatedMenuCell : UICollectionViewCell {
  
  @IBOutlet private weak var imageView: UIImageView!
  @IBOutlet private weak var captionLabel: UILabel!
  
  var menuItem: MenuItem? {
    didSet {
      if let menuItem = menuItem {
        imageView.image = menuItem.image
        captionLabel.text = menuItem.caption
      }
    }
  }
}
