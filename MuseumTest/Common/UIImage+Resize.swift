//
//  UIImage+Resize.swift
//  MuseumTest
//
//  Created by Sedykh Kirill on 06.08.2020.
//  Copyright © 2020 Sedykh Kirill. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
  class func resize(image: UIImage, minimalPartOfSize: CGFloat) -> UIImage {
    let size = image.size
      
    let ratio = size.height / size.width
    
    var newSize: CGSize
    if size.height < size.width {
      newSize = CGSize(width: minimalPartOfSize/ratio, height: minimalPartOfSize)
    } else {
      newSize = CGSize(width: minimalPartOfSize, height: minimalPartOfSize*ratio)
    }
 
    let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
    
    UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
    image.draw(in: rect)
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return newImage!
  }
}

