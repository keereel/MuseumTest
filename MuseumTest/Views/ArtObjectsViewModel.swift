//
//  ArtObjectsViewModel.swift
//  MuseumTest
//
//  Created by Sedykh Kirill on 27.07.2020.
//  Copyright © 2020 Sedykh Kirill. All rights reserved.
//

import Foundation
import CoreData

protocol ArtObjectsViewModelDelegate: AnyObject {
  func onFetchCompleted(indexPaths: [IndexPath])
  func onFetchFailed(errorText: String)
}

final class ArtObjectsViewModel {
  
  private weak var delegate: ArtObjectsViewModelDelegate?
  private let queryString: String
  private let apiClient: MuseumApiClient = MuseumApiClient()
  
  private let pageEntityName: String = "PageManaged"
  private let artObjectEntityName: String = "ArtObjectManaged"
  private var context: NSManagedObjectContext {
    CoreDataStack.shared.persistentContainer.viewContext
  }
  
  //private let fetchSuccessHandlerQueue = DispatchQueue(label: "fetchSuccessHandlerQueue", qos: .default, attributes: .concurrent)
  
  //var currentPage: Int = 0
  //var firstIndexOnPage: Int = 0
  //var lastIndexOnPage: Int = 0
  
  var totalObjects = 0
  
  var objects: [ArtObject] = []
  var count: Int {
    objects.count
  }
  //let refreshInterval: Int = 300
  let refreshInterval: Int = 30
  
  private var pagesAlreadyInDataSource: [Int: Date] = [:]
  
  init(queryString: String, delegate: ArtObjectsViewModelDelegate) {
    self.queryString = queryString
    self.delegate = delegate
  }
  
  func fetch(page: Int) {
    // First of all, is it outdated
    // TODO stopped here pagesAlreadyInDataSource
    //let dateOfPage =
    
    // First of all, try to fetch from persistent store
    if let pageManaged = fetchFromPersistentStore(page: page),
      let lastRefreshed = pageManaged.refreshDate,
      Date() < lastRefreshed.addingTimeInterval(TimeInterval(refreshInterval)),
      let artObjectsManaged = pageManaged.artObjects?.array as? [ArtObjectManaged] {
      
      print("fetched: page \(page) from CoreData")
      let artObjects = artObjectsManaged.compactMap { artObject(with: $0) }
      // TODO debug mofifier, remove it
      let loadedObjects = artObjects.map {
        ArtObject(title: "CD \(page): \($0.objectNumber) \($0.title)", objectNumber: $0.objectNumber)
      }
      //
      updateDataSourceAndUI(with: loadedObjects, forPageNumber: page)
      
      return
    }
    
    // Then, fetch from server
    apiClient.fetchArtObjects(queryString: queryString, page: page) { (result) in
      switch result {
      case .failure(let error):
        //
        print("ERROR: \(error.description)")
        //
        self.delegate?.onFetchFailed(errorText: error.description)
      case .success(let collectionResponse):
        /*
        print("collection.count \(collection.count)")
        collection.artObjects.forEach { (artObject) in
          print("artObject \(artObject)")
        }
        */
        print("fetched: page \(page) from Api")
        self.fetchSuccessHandler(collectionResponse: collectionResponse)
      }
    }
  
  }
  
  private func fetchSuccessHandler(collectionResponse: CollectionResponse) {
    //fetchSuccessHandlerQueue.async(flags: .barrier) {
    
    guard let page = collectionResponse.pageNumber else {
      return
    }
    // TODO debug mofifier, remove it
    let loadedObjects = collectionResponse.artObjects.map {
      ArtObject(title: "API \(page): \($0.objectNumber) \($0.title)", objectNumber: $0.objectNumber)
    }
    //
    
    // save to persistent store
    saveToPersistentStore(collectionResponse: collectionResponse)
    
    self.totalObjects = collectionResponse.count
    
    updateDataSourceAndUI(with: loadedObjects, forPageNumber: page)
 
    //}
  }
  
  private func updateDataSourceAndUI(with artObjects: [ArtObject], forPageNumber page: Int) {
    // update dataSource
    let firstIndexOnPage = minIndex(onPage: page)
    let lastIndexOnPage = maxIndex(onPage: page)
    for index in firstIndexOnPage...lastIndexOnPage {
      if self.objects.count - 1 < index {
        self.objects.append(artObjects[index-firstIndexOnPage])
      } else {
        self.objects[index] = artObjects[index-firstIndexOnPage]
      }
    }
    //self.firstIndexOnPage = page * self.apiClient.objectsPerPage
    //self.lastIndexOnPage = (page+1) * self.apiClient.objectsPerPage - 1
    //self.currentPage = page
    //print("loaded page: \(self.currentPage)")
    //print("FOP: \(self.firstIndexOnPage)")
    //print("LOP: \(self.lastIndexOnPage)")
    
    // update UI
    var indexPaths: [IndexPath] = []
    for index in firstIndexOnPage...lastIndexOnPage {
      indexPaths.append(IndexPath(row: index, section: 0))
    }
    DispatchQueue.main.async {
      self.delegate?.onFetchCompleted(indexPaths: indexPaths)
    }
  }
  
  
  // MARK: CoreData
  
  private func fetchFromPersistentStore(page: Int) -> PageManaged? {
    let fetchRequest: NSFetchRequest<PageManaged> = NSFetchRequest(entityName: pageEntityName)
    let pagePredicate = NSPredicate(format: "page == %i", page)
    let queryStringPredicate = NSPredicate(format: "queryString == %@", queryString)
    let compound = NSCompoundPredicate(type: .and, subpredicates: [pagePredicate, queryStringPredicate])
    fetchRequest.predicate = compound
    
    do {
      let result = try context.fetch(fetchRequest)
      // dbg
      print("for page \(page) queryString \(queryString) found: \(result.count)")
      /*
      result.forEach { (res) in
        print("--page: \(res.page)")
        print("--queryString: \(res.queryString)")
        print("--refreshDate: \(res.refreshDate)")
      }
      */
      //
      return result.first
    } catch {
      return nil
    }
  }
  
  
  private func saveToPersistentStore(collectionResponse: CollectionResponse) {
    guard let pageNumber = collectionResponse.pageNumber else {
      return
    }
    
    if let pageManaged = fetchFromPersistentStore(page: pageNumber) {
    // update page
      pageManaged.queryString = queryString
      pageManaged.page = Int16(pageNumber)
      pageManaged.refreshDate = Date()
      
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
      createdPageManaged.refreshDate = Date()
      
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
      }
    }
  }
  
  func artObject(with artObjectManaged: ArtObjectManaged) -> ArtObject? {
    guard let title = artObjectManaged.title,
      let objectNumber = artObjectManaged.objectNumber else {
        return nil
    }
    return ArtObject(title: title, objectNumber: objectNumber)
  }

  
  // MARK: Helpers
  
  var firstPage: Int {
    0
  }
  var lastPage: Int {
    totalObjects / apiClient.objectsPerPage
  }
  
  func pageNumber(for indexPath: IndexPath) -> Int {
    return indexPath.row / apiClient.objectsPerPage
  }
  
  func maxIndex(onPage page: Int) -> Int {
    return (page+1) * apiClient.objectsPerPage - 1
  }
  
  func minIndex(onPage page: Int) -> Int {
    return page * self.apiClient.objectsPerPage
  }
  
}
