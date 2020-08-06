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
  
  /*
  class func resize(image: UIImage, targetSize: CGSize) -> UIImage {
    let size = image.size
    
    let widthRatio  = targetSize.width  / image.size.width
    let heightRatio = targetSize.height / image.size.height
    
    var newSize: CGSize
    if widthRatio > heightRatio {
      newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
    } else {
      newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
    }
    
    let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
    
    UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
    image.draw(in: rect)
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return newImage!
  }
  
  class func scale(image: UIImage, by scale: CGFloat) -> UIImage? {
    let size = image.size
    let scaledSize = CGSize(width: size.width * scale, height: size.height * scale)
    return UIImage.resize(image: image, targetSize: scaledSize)
  }
  */
}

