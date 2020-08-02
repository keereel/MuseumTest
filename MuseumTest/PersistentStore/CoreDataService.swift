//
//  CoreDataService.swift
//  MuseumTest
//
//  Created by Седых Кирилл Сергеевич on 01.08.2020.
//  Copyright © 2020 Sedykh Kirill. All rights reserved.
//

import Foundation
import UIKit
import CoreData

protocol PersistentStore {
  // MARK: Pages
  func fetch(page: Int, queryString: String, secondsToExpire: Int) -> (artObjects: [ArtObject], lastRefresh: Date)?
  func save(queryString: String, collectionResponse: CollectionResponse, lastUpdatedDate: Date)
  // MARK: Images
  func fetchImage(guid: String) -> UIImage?
  func save(image: UIImage, with guid: String)
}

final class CoreDataService: PersistentStore {
  
  private let pageEntityName: String = "PageManaged"
  private let artObjectEntityName: String = "ArtObjectManaged"
  private let imageEntityName: String = "ImageManaged"
  private var context: NSManagedObjectContext {
    CoreDataStack.shared.persistentContainer.viewContext
  }
  private var privateContext: NSManagedObjectContext {
    CoreDataStack.shared.privateContext
  }
  
  deinit {
    print("DEINIT CoreDataService")
  }
  
  // MARK: Pages
  
  func fetch(page: Int, queryString: String, secondsToExpire: Int) -> (artObjects: [ArtObject], lastRefresh: Date)? {
    guard let pageManaged = fetch(page: page, queryString: queryString),
      let lastRefresh = pageManaged.refreshDate,
      Date() < lastRefresh.addingTimeInterval(TimeInterval(secondsToExpire)),
      let artObjectsManaged = pageManaged.artObjects?.array as? [ArtObjectManaged] else {
        return nil
    }
    print("fetched: page \(page) from CoreData")
    let artObjects = artObjectsManaged.compactMap { artObject(with: $0) }
    
    return (artObjects: artObjects, lastRefresh: lastRefresh)
  }
  
  private func fetch(page: Int, queryString: String) -> PageManaged? {
    let fetchRequest: NSFetchRequest<PageManaged> = NSFetchRequest(entityName: pageEntityName)
    let pagePredicate = NSPredicate(format: "page == %i", page)
    let queryStringPredicate = NSPredicate(format: "queryString == %@", queryString)
    let compound = NSCompoundPredicate(type: .and, subpredicates: [pagePredicate, queryStringPredicate])
    fetchRequest.predicate = compound
    
    do {
      let result = try context.fetch(fetchRequest)
      return result.first
    } catch {
      return nil
    }
  }
  
  func save(queryString: String, collectionResponse: CollectionResponse, lastUpdatedDate: Date) {
    guard let pageNumber = collectionResponse.pageNumber else {
      return
    }
    
    if let pageManaged = fetch(page: pageNumber, queryString: queryString) {
    // update page
      pageManaged.queryString = queryString
      pageManaged.page = Int16(pageNumber)
      pageManaged.refreshDate = lastUpdatedDate
      
      pageManaged.artObjects?.forEach {
          guard let artObjectManaged = $0 as? ArtObjectManaged else { return }
          context.delete(artObjectManaged)
      }
      createArtObjectsManaged(with: collectionResponse.artObjects, forPage: pageManaged)
      
      print("saveToPersistentStore update")
    
    } else {
    // create page
      guard let entityDescription = NSEntityDescription.entity(forEntityName: pageEntityName, in: context),
        let createdPageManaged = NSManagedObject(entity: entityDescription, insertInto: context) as? PageManaged else {
          return
      }
      createdPageManaged.queryString = queryString
      createdPageManaged.page = Int16(pageNumber)
      createdPageManaged.refreshDate = lastUpdatedDate
      
      createArtObjectsManaged(with: collectionResponse.artObjects, forPage: createdPageManaged)
      
      print("saveToPersistentStore created")
    
    }
  
    CoreDataStack.shared.saveContext()
  }
  
  private func createArtObjectsManaged(with artObjects: [ArtObject], forPage pageManaged: PageManaged) {
    for artObject in artObjects {
      if let entityDescription = NSEntityDescription.entity(forEntityName: artObjectEntityName, in: context),
        let createdArtObjectManaged = NSManagedObject(entity: entityDescription, insertInto: context) as? ArtObjectManaged {
        
        createdArtObjectManaged.title = artObject.title
        createdArtObjectManaged.objectNumber = artObject.objectNumber
        createdArtObjectManaged.page = pageManaged
        if let webImage = artObject.webImage {
          createdArtObjectManaged.imageGuid = webImage.guid
          createdArtObjectManaged.imageUrl = webImage.url
        }
        
      }
    }
  }
  
  private func artObject(with artObjectManaged: ArtObjectManaged) -> ArtObject? {
    guard let title = artObjectManaged.title,
      let objectNumber = artObjectManaged.objectNumber else {
        return nil
    }
    
    var webImage: WebImage?
    if let imageGuid = artObjectManaged.imageGuid,
      let imageUrl = artObjectManaged.imageUrl {
      webImage = WebImage(guid: imageGuid, url: imageUrl)
    }
    return ArtObject(title: title, objectNumber: objectNumber, webImage: webImage)
  }
  
  
  // MARK: Images
  
  func fetchImage(guid: String) -> UIImage? {
    var img: UIImage? = nil
    
    context.performAndWait {
      let fetchRequest: NSFetchRequest<ImageManaged> = NSFetchRequest(entityName: imageEntityName)
      let predicate = NSPredicate(format: "guid == %@", guid)
      fetchRequest.predicate = predicate
      
      do {
        let result = try context.fetch(fetchRequest)
        if let imageManaged = result.first,
          let imageData = imageManaged.image,
          let image = UIImage(data: imageData) {
          img = image
        }
      } catch {
        print("ERROR: CoreDataService context load image: \(error)")
      }
    }
    
    return img
  }
  
  func save(image: UIImage, with guid: String) {
    privateContext.perform {
      guard let entityDescription = NSEntityDescription.entity(forEntityName: self.imageEntityName, in: self.privateContext),
        let createdImageManaged = NSManagedObject(entity: entityDescription, insertInto: self.privateContext) as? ImageManaged else {
          return
      }
      createdImageManaged.guid = guid
      createdImageManaged.image = image.jpegData(compressionQuality: 0.9)
      
      if self.privateContext.hasChanges {
        do {
          try self.privateContext.save()
        } catch {
          print("ERROR: CoreDataService privateContext save image: \(error)")
        }
      }
    }
  }
  
}
