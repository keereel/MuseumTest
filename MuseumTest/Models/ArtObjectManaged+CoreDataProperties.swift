//
//  ArtObjectManaged+CoreDataProperties.swift
//  MuseumTest
//
//  Created by Седых Кирилл Сергеевич on 27.07.2020.
//  Copyright © 2020 Sedykh Kirill. All rights reserved.
//
//

import Foundation
import CoreData


extension ArtObjectManaged {

  @nonobjc public class func fetchRequest() -> NSFetchRequest<ArtObjectManaged> {
    return NSFetchRequest<ArtObjectManaged>(entityName: "ArtObjectManaged")
  }
  
  @NSManaged public var title: String?
  @NSManaged public var objectNumber: String?
  @NSManaged public var page: PageManaged?
  @NSManaged public var imageUrl: String?
  @NSManaged public var imageGuid: String?

}
