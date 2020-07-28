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
  
  init(queryString: String, delegate: ArtObjectsViewModelDelegate) {
    self.queryString = queryString
    self.delegate = delegate
  }
  
  func fetch(page: Int) {
    // Fetch from persistent store
    if let pageManaged = findPage(page: page),
      let lastRefreshed = pageManaged.refreshDate,
      Date() < lastRefreshed.addingTimeInterval(TimeInterval(refreshInterval)) {
      // fetched from persistent store isn't outdated, so use it instead of fetching from server
      
      // TODO refresh datasource
      //self.fetchSuccessHandler(collectionResponse: collectionResponse, saveFetched: false)
      
      return
    }
    
    // Fetch from server
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
      ArtObject(title: "\(page): \($0.objectNumber) \($0.title)", objectNumber: $0.objectNumber)
    }
    //
    
    // update dataSource
    //self.objects.append(contentsOf: artObjects)
    self.totalObjects = collectionResponse.count
    let firstIndexOnPage = minIndex(onPage: page)
    let lastIndexOnPage = maxIndex(onPage: page)
    for index in firstIndexOnPage...lastIndexOnPage {
      if self.objects.count - 1 < index {
        self.objects.append(loadedObjects[index-firstIndexOnPage])
      } else {
        self.objects[index] = loadedObjects[index-firstIndexOnPage]
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
    
    // save to persistent store
    saveToPersistentStore(collectionResponse: collectionResponse)
    //}
  }
  
  
  // MARK: CoreData
  
  func findPage(page: Int) -> PageManaged? {
    let fetchRequest: NSFetchRequest<PageManaged> = NSFetchRequest(entityName: pageEntityName)
    let pagePredicate = NSPredicate(format: "page == %i", page)
    let queryStringPredicate = NSPredicate(format: "queryString == %@", queryString)
    let compoundPredicate = NSCompoundPredicate(type: NSCompoundPredicate.LogicalType.and, subpredicates: [pagePredicate, queryStringPredicate])
    fetchRequest.predicate = compoundPredicate
    
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
  
  func saveToPersistentStore(collectionResponse: CollectionResponse) {
    guard let pageNumber = collectionResponse.pageNumber else {
      return
    }
    
    if let pageManaged = findPage(page: pageNumber) {
      pageManaged.queryString = queryString
      pageManaged.page = Int16(pageNumber)
      pageManaged.refreshDate = Date()
      print("saveToPersistentStore refreshed")
    } else {
      guard let entityDescription = NSEntityDescription.entity(forEntityName: pageEntityName, in: context),
        let createdPageManaged = NSManagedObject(entity: entityDescription, insertInto: context) as? PageManaged else {
          return
      }
      createdPageManaged.queryString = queryString
      createdPageManaged.page = Int16(pageNumber)
      createdPageManaged.refreshDate = Date()
      //createdPageManaged.artObjects
      print("saveToPersistentStore created")
    }
  
    CoreDataStack.shared.saveContext()
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
