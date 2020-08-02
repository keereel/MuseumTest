//
//  MuseumApiClient.swift
//  MuseumTest
//
//  Created by Sedykh Kirill on 25.07.2020.
//  Copyright © 2020 Sedykh Kirill. All rights reserved.
//

import Foundation
import Network

protocol MuseumApiClient {
  typealias completionHandler = (Result<CollectionResponse, DataResponseError>) -> Void
  
  func fetchArtObjects(queryString: String, page: Int, completion: @escaping completionHandler)
}

final class MuseumApiClientImpl: MuseumApiClient {
  
  struct PageDataTask: Hashable {
    let queryString: String
    let page: Int
  }
  
  private let apiKey = "ipNvjG2r"
  
  private var basePath: String {
    "https://www.rijksmuseum.nl/api/nl/collection?key=\(apiKey)"
  }
  
  private let session: URLSession
  
  private let monitor: NWPathMonitor
  
  private var suspendedTasks: [PageDataTask: completionHandler] = [:]
  private let suspendedTasksQueue = DispatchQueue(label: "MuseumApiClientImpl.suspendedTasks",
                                           attributes: .concurrent)
  
  init(session: URLSession = URLSession.shared) {
    self.session = session
    self.monitor = NWPathMonitor()
    setupNetworkMonitor()
  }
  
  deinit {
    print("DEINIT MuseumApiClient")
    monitor.cancel()
  }
  
  
  func fetchArtObjects(queryString: String, page: Int, completion: @escaping completionHandler) {
    
    let urlString = basePath + "&p=\(page)&q=\(queryString)"
    print("urlString \(urlString)")
    guard let url = URL(string: urlString) else {
      completion(Result.failure(DataResponseError.query))
      self.removeTaskFromSuspended(queryString: queryString, page: page)
      return
    }
    
    let urlRequest = URLRequest(url: url)
    
    let dataTask = session.dataTask(with: urlRequest) { (data, response, error) in
      guard let httpResponse = response as? HTTPURLResponse,
        httpResponse.hasSuccessStatusCode,
        let data = data else {
          completion(Result.failure(DataResponseError.network))
          // add tasks to suspended if no network
          print("ERROR: MuseumApiClient network status: \(self.monitor.currentPath.status)")
          if self.monitor.currentPath.status != .satisfied {
            self.addTaskToSuspended(queryString: queryString, page: page, completion: completion)
          }
          
          return
      }
      
      guard var decodedResponse = try? JSONDecoder().decode(CollectionResponse.self, from: data) else {
        completion(Result.failure(DataResponseError.decoding))
        self.removeTaskFromSuspended(queryString: queryString, page: page)
        return
      }
      
      decodedResponse.query = queryString
      decodedResponse.pageNumber = page
      completion(Result.success(decodedResponse))
      self.removeTaskFromSuspended(queryString: queryString, page: page)
    }
    
    dataTask.resume()
    
  }
  
  
  private func setupNetworkMonitor() {
    monitor.pathUpdateHandler = { [weak self] path in
      if path.status == .satisfied {
        print("Network status changed: Connected")
        self?.suspendedTasks.forEach { (task, completion) in
          self?.fetchArtObjects(queryString: task.queryString, page: task.page, completion: completion)
        }
      } else {
        print("Network status changed: No connection")
      }
    }
    
    let queue = DispatchQueue(label: "MuseumApiClient.networkMonitor")
    monitor.start(queue: queue)
  }
  
  private func addTaskToSuspended(queryString: String, page: Int, completion: @escaping completionHandler) {
    suspendedTasksQueue.async(flags: .barrier) {
      self.suspendedTasks[PageDataTask(queryString: queryString, page: page)] = completion
      print("MuseumApiClient: suspendedTask added, count \(self.suspendedTasks.count)")
    }
  }
  
  private func removeTaskFromSuspended(queryString: String, page: Int) {
    suspendedTasksQueue.async(flags: .barrier) {
      self.suspendedTasks[PageDataTask(queryString: queryString, page: page)] = nil
      print("MuseumApiClient: suspendedTask removed, count \(self.suspendedTasks.count)")
    }
  }
  
}
