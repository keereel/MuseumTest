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
  
  private var tasks = [URL: [completionHandler]]()
  //private var tasks: [URL: completionHandler] = [:]
  
  private let tasksQueue = DispatchQueue(label: "ImageLoaderServiceImpl.tasks",
                                           attributes: .concurrent)
  
  deinit {
    print("DEINIT ImageLoaderService")
  }
  
  
  func fetchImage(with urlString: String, completion: @escaping completionHandler) {
    guard let url = URL(string: urlString) else {
      completion(Result.failure(DataResponseError.invalidUrl))
      return
    }
    
    tasksQueue.async(flags: .barrier) {
      
      if self.tasks.keys.contains(url) {
        print("cnt1 \(self.tasks[url]!)")
        //
        self.tasks[url]?.append(completion)
      } else {
        self.tasks[url] = [completion]
        let dataTask = self.session.dataTask(with: url, completionHandler: { [weak self] (data, response, error) in
          self?.tasksQueue.async(flags: .barrier) {
            print("cnt2 \(self?.tasks[url]!)")
            guard let completionHandlers = self?.tasks[url] else {
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
            self?.tasks[url] = nil
          }
        })
        dataTask.resume()
      }
      
    } // tasksQueue
    
  }
  
}
