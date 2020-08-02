//
//  ImageLoaderService.swift
//  MuseumTest
//
//  Created by Седых Кирилл Сергеевич on 30.07.2020.
//  Copyright © 2020 Sedykh Kirill. All rights reserved.
//

import Foundation

protocol ImageLoaderService {
  typealias completionHandler = (Result<Data, DataResponseError>) -> Void
  func fetchImage(with urlString: String, completion: @escaping completionHandler)
}

final class ImageLoaderServiceImpl: ImageLoaderService {
  
  private let session: URLSession = URLSession(configuration: .default)
  
  //private var tasksWithArray = [URL: [completionHandler]]()
  private var tasks: [URL: completionHandler] = [:]
  
  private let tasksQueue = DispatchQueue(label: "ImageLoaderServiceImpl.tasks",
                                           attributes: .concurrent)
  
  deinit {
    print("DEINIT ImageLoaderService")
  }
  
  
  // with one task for each url
  func fetchImage(with urlString: String, completion: @escaping completionHandler) {
    guard let url = URL(string: urlString) else {
      completion(Result.failure(DataResponseError.invalidUrl))
      return
    }
    
    tasksQueue.async(flags: .barrier) {
      
      if self.tasks.keys.contains(url) {
        self.tasks[url] = completion
      } else {
        self.tasks[url] = completion
        let dataTask = self.session.dataTask(with: url, completionHandler: { [weak self] (data, response, error) in
          self?.tasksQueue.async(flags: .barrier) {
            guard let data = data else {
              //print("ERROR imageLoaderService \(urlString)")
              completion(Result.failure(DataResponseError.network))
              return
            }
            
            // perform handler related with this image
            completion(.success(data))
            
            // remove loaded image and its handler from tasks
            self?.tasks[url] = nil
          }
        })
        dataTask.resume()
      }
      
    } // tasksQueue
    
  }
  
  /*
  // with array of tasks for each url
  func _fetchImage(with urlString: String, completion: @escaping completionHandler) {
    guard let url = URL(string: urlString) else {
      completion(Result.failure(DataResponseError.invalidUrl))
      return
    }
    
    tasksQueue.async(flags: .barrier) {
      
      if self.tasksWithArray.keys.contains(url) {
        print("cnt1 \(self.tasksWithArray[url]!)")
        //
        self.tasksWithArray[url]?.append(completion)
      } else {
        self.tasksWithArray[url] = [completion]
        let dataTask = self.session.dataTask(with: url, completionHandler: { [weak self] (data, response, error) in
          self?.tasksQueue.async(flags: .barrier) {
            print("cnt2 \(self?.tasksWithArray[url]!)")
            guard let completionHandlers = self?.tasksWithArray[url] else {
              return
            }
            guard let data = data else {
              print("ERROR imageLoaderService \(urlString) count \(completionHandlers.count)")
              for completionHandler in completionHandlers {
                completionHandler(Result.failure(DataResponseError.network))
              }
              return
            }
            
            // perform all handlers related with this image
            print("imageLoaderService \(urlString) count \(completionHandlers.count)")
            for completionHandler in completionHandlers {
              completionHandler(.success(data))
            }
            
            // remove loaded image and its handlers from tasks
            self?.tasksWithArray[url] = nil
          }
        })
        dataTask.resume()
      }
      
    } // tasksQueue
    
  }
 */
  
}
