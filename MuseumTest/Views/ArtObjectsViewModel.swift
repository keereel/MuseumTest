//
//  ArtObjectsViewModel.swift
//  MuseumTest
//
//  Created by Sedykh Kirill on 27.07.2020.
//  Copyright © 2020 Sedykh Kirill. All rights reserved.
//

import Foundation

protocol ArtObjectsViewModelDelegate: AnyObject {
  func onFetchCompleted(indexPaths: [IndexPath])
  func onFetchFailed(errorText: String)
}

final class ArtObjectsViewModel {
  
  private weak var delegate: ArtObjectsViewModelDelegate?
  private let queryString: String
  private let apiClient: MuseumApiClient = MuseumApiClient()
  
  private let fetchSuccessHandlerQueue = DispatchQueue(label: "fetchSuccessHandlerQueue", qos: .default, attributes: .concurrent)
  
  //var currentPage: Int = 0
  //var firstIndexOnPage: Int = 0
  //var lastIndexOnPage: Int = 0
  var totalObjects = 0
  
  var objects: [ArtObject] = []
  var count: Int {
    objects.count
  }
  
  init(queryString: String, delegate: ArtObjectsViewModelDelegate) {
    self.queryString = queryString
    self.delegate = delegate
  }
 
  func fetch(page: Int) {
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
    // test
    let loadedObjects = collectionResponse.artObjects.map {
      ArtObject(title: "\(page): \($0.objectNumber) \($0.title)", objectNumber: $0.objectNumber)
    }
    //
    //self.objects.append(contentsOf: artObjects)
    
    // update dataSource
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
    //}
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
