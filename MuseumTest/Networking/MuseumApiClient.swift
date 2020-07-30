//
//  MuseumApiClient.swift
//  MuseumTest
//
//  Created by Sedykh Kirill on 25.07.2020.
//  Copyright © 2020 Sedykh Kirill. All rights reserved.
//

import Foundation

protocol MuseumApiClient {
  typealias completionHandler = (Result<CollectionResponse, DataResponseError>) -> Void
  func fetchArtObjects(queryString: String, page: Int, completion: @escaping completionHandler)
}

final class MuseumApiClientImpl: MuseumApiClient {
  
  // key ipNvjG2r
  // https://www.rijksmuseum.nl/api/nl/collection?key=ipNvjG2r&involvedMaker=Rembrandt+van+Rijn
  // https://www.rijksmuseum.nl/api/nl/collection?key=ipNvjG2r&involvedMaker=Johannes+Vermeer
  // https://www.rijksmuseum.nl/api/nl/collection?key=ipNvjG2r&q=Rembrand
  //
  // https://data.rijksmuseum.nl/
  //
  // rembrandt van rijn
  // johannes vermeer
  
  private let apiKey = "ipNvjG2r"
  
  private var basePath: String {
    "https://www.rijksmuseum.nl/api/nl/collection?key=\(apiKey)"
  }
  
  private let session: URLSession
  
  init(session: URLSession = URLSession.shared) {
    self.session = session
  }
  
  deinit {
    print("DEINIT MuseumApiClient")
  }
  
  func fetchArtObjects(queryString: String, page: Int, completion: @escaping completionHandler) {
    
    let urlString = basePath + "&p=\(page)&q=\(queryString)"
    print("urlString \(urlString)")
    guard let url = URL(string: urlString) else {
      completion(Result.failure(DataResponseError.query))
      return
    }
    
    let urlRequest = URLRequest(url: url)
    
    let dataTask = session.dataTask(with: urlRequest) { (data, response, error) in
      guard let httpResponse = response as? HTTPURLResponse,
        httpResponse.hasSuccessStatusCode,
        let data = data else {
          completion(Result.failure(DataResponseError.network))
          return
      }
      
      guard var decodedResponse = try? JSONDecoder().decode(CollectionResponse.self, from: data) else {
        completion(Result.failure(DataResponseError.decoding))
        return
      }
      
      decodedResponse.query = queryString
      decodedResponse.pageNumber = page
      completion(Result.success(decodedResponse))
    }
    
    dataTask.resume()
    
  }
  
}
