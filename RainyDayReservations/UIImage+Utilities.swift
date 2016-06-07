//
//  UIImage+Decompression.swift
//  RainyDayReservations
//
//  Created by Dan Coughlin on 3/30/16.
//  Copyright © 2016 GroovyTree LLC. All rights reserved.
//

import UIKit

extension UIImage {
  
  var  decompressedImage: UIImage {
    UIGraphicsBeginImageContextWithOptions(size, true, 0)
    drawAtPoint(CGPointZero)
    let decompressedImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return decompressedImage
  }
  
  func imageWithSize(size:CGSize) -> UIImage
  {
    var scaledImageRect = CGRect.zero;
    
    let aspectWidth:CGFloat = size.width / self.size.width;
    let aspectHeight:CGFloat = size.height / self.size.height;
    let aspectRatio:CGFloat = max(aspectWidth, aspectHeight);  // Switch MAX to MIN for aspect fit instead of fill.
    
    scaledImageRect.size.width = self.size.width * aspectRatio;
    scaledImageRect.size.height = self.size.height * aspectRatio;
    scaledImageRect.origin.x = (size.width - scaledImageRect.size.width) / 2.0;
    scaledImageRect.origin.y = (size.height - scaledImageRect.size.height) / 2.0;
    
    UIGraphicsBeginImageContextWithOptions(size, false, 0);
    
    self.drawInRect(scaledImageRect);
    
    let scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return scaledImage;
  }
  
  private func generateUniqueFileURL() -> NSURL {
    let fileManager = NSFileManager.defaultManager()
    let fileArray: NSArray = fileManager.URLsForDirectory(.CachesDirectory, inDomains: .UserDomainMask)
    let fileURL = fileArray.lastObject?.URLByAppendingPathComponent(NSUUID().UUIDString).URLByAppendingPathExtension("jpg")
    
    if let filePath = fileArray.lastObject {
      if !fileManager.fileExistsAtPath(filePath.path) {
        do {
          try fileManager.createDirectoryAtPath(filePath as! String, withIntermediateDirectories: true, attributes: nil)
        } catch _ {
        }
      }
    }
    
    return fileURL!
  }
  
  func cacheImageDataLocally() -> NSURL {
    let imageData = UIImageJPEGRepresentation(self, 0.80)
    let url = generateUniqueFileURL()
    imageData?.writeToURL(url, atomically: true)
    return url
  }

}

