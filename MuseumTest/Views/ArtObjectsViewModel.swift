//
//  ArtObjectsViewModel.swift
//  MuseumTest
//
//  Created by Sedykh Kirill on 27.07.2020.
//  Copyright © 2020 Sedykh Kirill. All rights reserved.
//

import Foundation
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
  private let persistentStore: PersistentStore = CoreDataService()
  
  private weak var delegate: ArtObjectsViewModelDelegate?
  
  var totalObjects = 0
  
  private var objects: [ArtObject] = []
  var count: Int {
    objects.count
  }
  private let imageCache = NSCache<NSString, UIImage>()
  private var pagesAlreadyInDataSource: [Int: Date] = [:]
 
  private let objectsQueue = DispatchQueue(label: "ArtObjectsViewModel.objectsWritingQueue", attributes: .concurrent)
  
  private var refreshInterval: Int {
    CommonParameters.shared.refreshIntervalInSeconds
  }
  
  
  init(queryString: String, delegate: ArtObjectsViewModelDelegate) {
    self.queryString = queryString
    self.delegate = delegate
  }
  
  deinit {
    print("DEINIT VM")
  }
  
  func artObject(for indexPath: IndexPath) -> ArtObject {
    return artObject(for: indexPath.row)
  }
  
  private func artObject(for index: Int) -> ArtObject {
    objectsQueue.sync(flags: .barrier) {
      return objects[index]
    }
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
    if let fetchResult = persistentStore.fetch(page: page,
                                              queryString: queryString,
                                              secondsToExpire: refreshInterval) {
      // TODO debug mofifier, remove it
      let loadedObjects = fetchResult.artObjects.enumerated().map {
        ArtObject(title: "CD \(page): \((page-1)*objectsPerPage+$0) \($1.objectNumber) \($1.title)",
          objectNumber: $1.objectNumber,
          webImage: $1.webImage)
      }
      //
      pagesAlreadyInDataSource[page] = fetchResult.lastRefresh
      updateDataSourceAndUI(with: loadedObjects, forPageNumber: page)
      
      return
    }
    
    // And then fetch from server
    apiClient.fetchArtObjects(queryString: queryString, page: page) { [weak self] (result) in
      switch result {
      case .failure(let error):
        print("ERROR: \(error.description)")
        self?.delegate?.onFetchFailed(errorText: error.description)
      case .success(let collectionResponse):
        print("fetched: page \(page) from Api")
        self?.fetchSuccessHandler(collectionResponse: collectionResponse)
      }
    }
  }
  
  private func fetchSuccessHandler(collectionResponse: CollectionResponse) {
    guard let page = collectionResponse.pageNumber else {
      return
    }
    // TODO debug mofifier, remove it
    let loadedObjects = collectionResponse.artObjects.enumerated().map {
      ArtObject(title: "API \(page): \((page-1)*objectsPerPage+$0) \($1.objectNumber) \($1.title)",
        objectNumber: $1.objectNumber,
        webImage: $1.webImage)
    }
    //loadedObjects.forEach { print("\($0.webImage?.url)") }
    //
    
    // save to persistent store
    let lastUpdatedDate = Date()
    DispatchQueue.main.async {
      self.persistentStore.save(queryString: self.queryString, collectionResponse: collectionResponse, lastUpdatedDate: lastUpdatedDate)
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
    
    // update dataSource
    let firstIndexOnPage = minIndex(onPage: page)
    let lastIndexOnPage = firstIndexOnPage + artObjects.count - 1
    objectsQueue.sync(flags: .barrier) {
      for index in firstIndexOnPage...lastIndexOnPage {
        if self.objects.count - 1 < index {
          self.objects.append(artObjects[index-firstIndexOnPage])
        } else {
          self.objects[index] = artObjects[index-firstIndexOnPage]
        }
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
  
  // fetching images in privateContext - performance is the same as when fetching images in viewContext
  /*
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
    
    // Fetching from persistent store then from api
    //fetchImageFromPersistentStore(guid: webImage.guid, completion: fetchFromPersistentStoreCompletion)
    //let fetchFromPersistentStoreCompletion: (UIImage?) -> Void = { fetchedImage in
    
    // Fetching from persistent store
    fetchImageFromPersistentStore(guid: webImage.guid) { fetchedImage in
      if let image = fetchedImage {
        print("image for index \(index) fetched from CoreData: \(webImage.guid)")
        self.imageCache.setObject(image, forKey: NSString(string: webImage.guid))
        completion(.success(image))
        return
      }
      
      // Fetching from API
      print("image for index \(index) TO fetch from API: \(webImage.guid)")
      self.imageLoader.fetchImage(with: webImage.url) { [weak self] (result) in
        switch result {
        case .success(let data):
          print("image for index \(index) fetched from API: \(webImage.guid)")
          if let image = UIImage(data: data) {
            self?.imageCache.setObject(image, forKey: NSString(string: webImage.guid))
            self?.saveToPersistentStore(image: image, with: webImage.guid)
            completion(.success(image))
          } else {
            completion(.failure(TextError("Invalid image data")))
          }
        case .failure(let error):
          completion(.failure(TextError(error.description)))
        }
      }
    }
  
  }
  */
  
  func fetchImage(index: Int, completion: @escaping (Result<UIImage?, TextError>) -> Void) {
    guard index < count else {
        completion(.failure(TextError("Unexpected error")))
        return
    }
    guard let webImage = artObject(for: index).webImage else {
      completion(.success(nil))
      return
    }
    
    // Taking from cache
    if let cachedImage = imageCache.object(forKey: NSString(string: webImage.guid)) {
      print("image for index \(index) fetched from cache: \(webImage.url)")
      completion(.success(cachedImage))
      return
    }
    
    // Fetching from persistent store
    if let image = persistentStore.fetchImage(guid: webImage.guid) {
      print("image for index \(index) fetched from CoreData: \(webImage.url)")
      imageCache.setObject(image, forKey: NSString(string: webImage.guid))
      completion(.success(image))
      return
    }
    
    // Fetching from API
    print("image for index \(index) TO fetch from API: \(webImage.url)")
    imageLoader.fetchImage(with: webImage.url) { [weak self] (result) in
      switch result {
      case .success(let data):
        print("image for index \(index) fetched from API: \(webImage.url)")
        if let image = UIImage(data: data) {
          //let newSize = CGSize(width: image.size.width/4, height: image.size.height/4)
          //let resizedImage = image.resized(to: newSize)
          //let resizedImage = UIImage.scale(image: image, by: 0.2)!
          let resizedImage = UIImage.resize(image: image, minimalPartOfSize: CommonParameters.shared.thumbnailSideSize)
          self?.imageCache.setObject(resizedImage, forKey: NSString(string: webImage.guid))
          self?.persistentStore.save(image: resizedImage, with: webImage.guid)
          completion(.success(resizedImage))
        } else {
          completion(.failure(TextError("Unable to load image")))
        }
      case .failure(let error):
        completion(.failure(TextError(error.description)))
      }
    }
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
