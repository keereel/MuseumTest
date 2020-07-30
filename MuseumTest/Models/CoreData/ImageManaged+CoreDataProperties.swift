//
//  ImageManaged+CoreDataProperties.swift
//  MuseumTest
//
//  Created by Седых Кирилл Сергеевич on 30.07.2020.
//  Copyright © 2020 Sedykh Kirill. All rights reserved.
//
//

import Foundation
import CoreData

extension ImageManaged {
  
  @nonobjc public class func fetchRequest() -> NSFetchRequest<ImageManaged> {
    return NSFetchRequest<ImageManaged>(entityName: "ImageManaged")
  }
  
  @NSManaged public var guid: String?
  @NSManaged public var image: Data?
  
}
