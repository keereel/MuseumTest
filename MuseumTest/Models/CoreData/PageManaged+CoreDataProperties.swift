//
//  PageManaged+CoreDataProperties.swift
//  MuseumTest
//
//  Created by Седых Кирилл Сергеевич on 27.07.2020.
//  Copyright © 2020 Sedykh Kirill. All rights reserved.
//
//

import Foundation
import CoreData


extension PageManaged {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PageManaged> {
        return NSFetchRequest<PageManaged>(entityName: "PageManaged")
    }

    @NSManaged public var page: Int16
    @NSManaged public var queryString: String?
    @NSManaged public var refreshDate: Date?
    @NSManaged public var artObjects: NSOrderedSet?

}

// MARK: Generated accessors for artObjects
extension PageManaged {

    @objc(insertObject:inArtObjectsAtIndex:)
    @NSManaged public func insertIntoArtObjects(_ value: ArtObjectManaged, at idx: Int)

    @objc(removeObjectFromArtObjectsAtIndex:)
    @NSManaged public func removeFromArtObjects(at idx: Int)

    @objc(insertArtObjects:atIndexes:)
    @NSManaged public func insertIntoArtObjects(_ values: [ArtObjectManaged], at indexes: NSIndexSet)

    @objc(removeArtObjectsAtIndexes:)
    @NSManaged public func removeFromArtObjects(at indexes: NSIndexSet)

    @objc(replaceObjectInArtObjectsAtIndex:withObject:)
    @NSManaged public func replaceArtObjects(at idx: Int, with value: ArtObjectManaged)

    @objc(replaceArtObjectsAtIndexes:withArtObjects:)
    @NSManaged public func replaceArtObjects(at indexes: NSIndexSet, with values: [ArtObjectManaged])

    @objc(addArtObjectsObject:)
    @NSManaged public func addToArtObjects(_ value: ArtObjectManaged)

    @objc(removeArtObjectsObject:)
    @NSManaged public func removeFromArtObjects(_ value: ArtObjectManaged)

    @objc(addArtObjects:)
    @NSManaged public func addToArtObjects(_ values: NSOrderedSet)

    @objc(removeArtObjects:)
    @NSManaged public func removeFromArtObjects(_ values: NSOrderedSet)

}
