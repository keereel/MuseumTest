//
//  ArtObjectsViewModel.swift
//  MuseumTest
//
//  Created by Sedykh Kirill on 27.07.2020.
//  Copyright © 2020 Sedykh Kirill. All rights reserved.
//

import Foundation
import CoreData
import UIKit

protocol ArtObjectsViewModelDelegate: AnyObject {
  func onFetchCompleted(indexPaths: [IndexPath])
  func onFetchFailed(errorText: String)
}

final class ArtObjectsViewModel {
  
  private let queryString: String
  private let objectsPerPage = 10
  private let apiClient: MuseumApiClient = MuseumApiClientImpl()
  private let imageLoader: ImageLoaderService = ImageLoaderServiceImpl()
  
  private let pageEntityName: String = "PageManaged"
  private let artObjectEntityName: String = "ArtObjectManaged"
  private let imageEntityName: String = "ImageManaged"
  private var context: NSManagedObjectContext {
    CoreDataStack.shared.persistentContainer.viewContext
  }
  
  private weak var delegate: ArtObjectsViewModelDelegate?
  
  var totalObjects = 0
  
  var objects: [ArtObject] = []
  var count: Int {
    objects.count
  }
  let imageCache = NSCache<NSString, UIImage>()
  
  //let refreshInterval: Int = 300
  let refreshInterval: Int = 30
  
  private var pagesAlreadyInDataSource: [Int: Date] = [:]
  
  init(queryString: String, delegate: ArtObjectsViewModelDelegate) {
    self.queryString = queryString
    self.delegate = delegate
  }
  
  deinit {
    print("DEINIT VM")
  }
  
  
  // MARK: Fetch pages
  
  func fetch(page: Int) {
    // First of all, check, if this page already in dataSource, and it is not outdated,
    //    just return to avoid redundant coreData calls
    if let dateOfPage = pagesAlreadyInDataSource[page],
      Date() < dateOfPage.addingTimeInterval(TimeInterval(refreshInterval)) {
      print("not fetched: page \(page) no necessity")
      DispatchQueue.main.async {
        self.delegate?.onFetchCompleted(indexPaths: [])
      }
      return
    }
    
    // Then try to fetch from persistent store
    if let pageManaged = fetchFromPersistentStore(page: page),
      let lastRefreshed = pageManaged.refreshDate,
      Date() < lastRefreshed.addingTimeInterval(TimeInterval(refreshInterval)),
      let artObjectsManaged = pageManaged.artObjects?.array as? [ArtObjectManaged] {
      
      print("fetched: page \(page) from CoreData")
      let artObjects = artObjectsManaged.compactMap { artObject(with: $0) }
      // TODO debug mofifier, remove it
      let loadedObjects = artObjects.map {
        ArtObject(title: "CD \(page): \($0.objectNumber) \($0.title)",
          objectNumber: $0.objectNumber,
          webImage: $0.webImage)
      }
      //
      pagesAlreadyInDataSource[page] = lastRefreshed
      updateDataSourceAndUI(with: loadedObjects, forPageNumber: page)
      
      return
    }
    
    // And then fetch from server
    apiClient.fetchArtObjects(queryString: queryString, page: page) { (result) in
      switch result {
      case .failure(let error):
        print("ERROR: \(error.description)")
        self.delegate?.onFetchFailed(errorText: error.description)
      case .success(let collectionResponse):
        print("fetched: page \(page) from Api")
        self.fetchSuccessHandler(collectionResponse: collectionResponse)
      }
    }
  }
  
  private func fetchSuccessHandler(collectionResponse: CollectionResponse) {
    guard let page = collectionResponse.pageNumber else {
      return
    }
    // TODO debug mofifier, remove it
    let loadedObjects = collectionResponse.artObjects.map {
      ArtObject(title: "API \(page): \($0.objectNumber) \($0.title)",
        objectNumber: $0.objectNumber,
        webImage: $0.webImage)
    }
    //loadedObjects.forEach { print("\($0.webImage?.url)") }
    //
    
    // save to persistent store
    let lastUpdatedDate = Date()
    DispatchQueue.main.async {
      self.saveToPersistentStore(collectionResponse: collectionResponse, lastUpdatedDate: lastUpdatedDate)
    }
    
    self.totalObjects = collectionResponse.count
    
    pagesAlreadyInDataSource[page] = lastUpdatedDate
    updateDataSourceAndUI(with: loadedObjects, forPageNumber: page)
  }
  
  private func updateDataSourceAndUI(with artObjects: [ArtObject], forPageNumber page: Int) {
    guard artObjects.count > 0 else {
      DispatchQueue.main.async {
        self.delegate?.onFetchCompleted(indexPaths: [])
      }
      return
    }
    
    // update images
    // debug output
    //artObjects.forEach { print("\($0.webImage?.url)") }
    //
    
    // update dataSource
    let firstIndexOnPage = minIndex(onPage: page)
    let lastIndexOnPage = firstIndexOnPage + artObjects.count - 1
    for index in firstIndexOnPage...lastIndexOnPage {
      if self.objects.count - 1 < index {
        self.objects.append(artObjects[index-firstIndexOnPage])
      } else {
        self.objects[index] = artObjects[index-firstIndexOnPage]
      }
    }
    
    // update UI
    var indexPaths: [IndexPath] = []
    for index in firstIndexOnPage...lastIndexOnPage {
      indexPaths.append(IndexPath(row: index, section: 0))
    }
    DispatchQueue.main.async {
      self.delegate?.onFetchCompleted(indexPaths: indexPaths)
    }
  }
  
  
  // MARK: Fetch images
  
  func fetchImage(index: Int, completion: @escaping (Result<UIImage?, TextError>) -> Void) {
    guard index < count else {
        completion(.failure(TextError("Unexpected error")))
        return
    }
    guard let webImage = objects[index].webImage else {
      completion(.success(nil))
      return
    }
    
    // Taking from cache
    if let cachedImage = imageCache.object(forKey: NSString(string: webImage.guid)) {
      print("image for index \(index) fetched from cache: \(webImage.guid)")
      completion(.success(cachedImage))
      return
    }
    
    // Fetching from persistent store
    if let image = fetchImageFromPersistentStore(guid: webImage.guid) {
      print("image for index \(index) fetched from CoreData: \(webImage.guid)")
      imageCache.setObject(image, forKey: NSString(string: webImage.guid))
      completion(.success(image))
      return
    }
    
    // Fetching from API
    imageLoader.fetchImage(with: webImage.url) { [weak self] (result) in
      switch result {
      case .success(let data):
        print("image for index \(index) fetched from API: \(webImage.guid)")
        if let image = UIImage(data: data) {
          self?.imageCache.setObject(image, forKey: NSString(string: webImage.guid))
          DispatchQueue.main.async {
            self?.saveToPersistentStore(image: image, with: webImage.guid)
          }
          completion(.success(image))
        } else {
          completion(.failure(TextError("Invalid image data")))
        }
      case .failure(let error):
        // TODO retry?
        completion(.failure(TextError(error.description)))
      }
    }
  }
  
  private func fetchImageFromPersistentStore(guid: String) -> UIImage? {
    let fetchRequest: NSFetchRequest<ImageManaged> = NSFetchRequest(entityName: imageEntityName)
    let predicate = NSPredicate(format: "guid == %@", guid)
    fetchRequest.predicate = predicate
    
    do {
      let result = try context.fetch(fetchRequest)
      guard let imageManaged = result.first,
        let imageData = imageManaged.image,
        let image = UIImage(data: imageData)
        else {
          return nil
      }
      return image
    } catch {
      return nil
    }
  }
  
  private func saveToPersistentStore(image: UIImage, with guid: String) {
    guard let entityDescription = NSEntityDescription.entity(forEntityName: imageEntityName, in: context),
      let createdImageManaged = NSManagedObject(entity: entityDescription, insertInto: context) as? ImageManaged else {
        return
    }
    createdImageManaged.guid = guid
    //createdImageManaged.image = image.jpegData(compressionQuality: 0.9)
    createdImageManaged.image = image.pngData()
    
    CoreDataStack.shared.saveContext()
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
      return result.first
    } catch {
      return nil
    }
  }
  
  
  private func saveToPersistentStore(collectionResponse: CollectionResponse, lastUpdatedDate: Date) {
    guard let pageNumber = collectionResponse.pageNumber else {
      return
    }
    
    if let pageManaged = fetchFromPersistentStore(page: pageNumber) {
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
  
  func artObject(with artObjectManaged: ArtObjectManaged) -> ArtObject? {
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

  
  // MARK: Helpers
  
  var firstPage: Int {
    /*
    In The API page numeration starts from 0, but i found that page 0 always just duplicates page 1.
    And, respectively, count field from api response, which represents total number of artObjects on all pages, does not includes count of the page 0. For instance, when count field from api response = 16, it will be 3 pages available: page 0 with 10 elements, page 1 with 10 elements, and page 2 with 6 elements.
    So, i must ignore page number 0, and fetch pages from 1
    */
    1
  }
  var lastPage: Int {
    (totalObjects / objectsPerPage) + firstPage
  }
  
  func pageNumber(for indexPath: IndexPath) -> Int {
    return (indexPath.row / objectsPerPage) + firstPage
  }
  
  func minIndex(onPage page: Int) -> Int {
    return (page - firstPage) * self.objectsPerPage
  }
  
  func maxIndex(onPage page: Int) -> Int {
    return (page - firstPage + 1) * objectsPerPage - 1
  }
  
}
