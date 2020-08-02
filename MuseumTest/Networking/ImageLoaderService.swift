//
//  ImageLoaderService.swift
//  MuseumTest
//
//  Created by Седых Кирилл Сергеевич on 30.07.2020.
//  Copyright © 2020 Sedykh Kirill. All rights reserved.
//

import Foundation
import Network

protocol ImageLoaderService {
  typealias completionHandler = (Result<Data, DataResponseError>) -> Void
  
  func fetchImage(with urlString: String, completion: @escaping completionHandler)
}

final class ImageLoaderServiceImpl: ImageLoaderService {
  
  private let session: URLSession = URLSession(configuration: .default)
  
  private let monitor: NWPathMonitor = NWPathMonitor()
  
  private var suspendedTasks: [String: completionHandler] = [:]
  private let suspendedTasksQueue = DispatchQueue(label: "ImageLoaderServiceImpl.suspendedTasks",
                                           attributes: .concurrent)
  
  //private var tasksWithArray = [URL: [completionHandler]]()
  private var tasks: [URL: completionHandler] = [:]
  private let tasksQueue = DispatchQueue(label: "ImageLoaderServiceImpl.tasks",
                                           attributes: .concurrent)
  
  init() {
    setupNetworkMonitor()
  }
  
  deinit {
    print("DEINIT ImageLoaderService")
    monitor.cancel()
  }
    
  
  // with one task for each url
  func fetchImage(with urlString: String, completion: @escaping completionHandler) {
    guard let url = URL(string: urlString) else {
      completion(Result.failure(DataResponseError.invalidUrl))
      removeTaskFromSuspended(urlString: urlString)
      return
    }
    
    tasksQueue.async(flags: .barrier) {

      // Check, is this task suspended. If it is, we need to run it anyway
      var taskIsSuspended = false
      if self.suspendedTasks.keys.contains(urlString) {
        taskIsSuspended = true
      }
      
      if self.tasks.keys.contains(url) && !taskIsSuspended {
        // just refresh completion handler
        self.tasks[url] = completion
      } else {
        // run request
        self.tasks[url] = completion
        let dataTask = self.session.dataTask(with: url, completionHandler: { [weak self] (data, response, error) in
          
          self?.tasksQueue.async(flags: .barrier) {
            guard let data = data else {
              completion(Result.failure(DataResponseError.network))
              // add tasks to suspended if no network
              if self?.monitor.currentPath.status != .satisfied {
                self?.addTaskToSuspended(urlString: urlString, completion: completion)
              }
              return
            }
            
            // perform handler related with this image
            completion(.success(data))
            self?.removeTaskFromSuspended(urlString: urlString)
            
            // remove loaded image and its handler from tasks
            self?.tasks[url] = nil
          }
          
        })
        dataTask.resume()
      }
      
    } // tasksQueue
    
  }
  
  
  private func setupNetworkMonitor() {
    monitor.pathUpdateHandler = { [weak self] path in
      if path.status == .satisfied {
        self?.suspendedTasksQueue.async(flags: .barrier) {
          self?.suspendedTasks.forEach { (urlString, completion) in
            self?.fetchImage(with: urlString, completion: completion)
          }
        }
      }
    }
    let queue = DispatchQueue(label: "ImageLoaderServiceImpl.networkMonitor")
    monitor.start(queue: queue)
  }
  
  private func addTaskToSuspended(urlString: String, completion: @escaping completionHandler) {
    suspendedTasksQueue.async(flags: .barrier) {
      self.suspendedTasks[urlString] = completion
    }
  }
  
  private func removeTaskFromSuspended(urlString: String) {
    suspendedTasksQueue.async(flags: .barrier) {
      self.suspendedTasks[urlString] = nil
    }
  }
  
}
