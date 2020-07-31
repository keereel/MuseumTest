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
  
  private let writingQueue = DispatchQueue(label: "ImageLoaderServiceImpl.tasks.writingQueue",
                                           attributes: .concurrent)
  
  deinit {
    print("DEINIT ImageLoaderService")
  }
  
  func fetchImage(with urlString: String, completion: @escaping completionHandler) {
    guard let url = URL(string: urlString) else {
      completion(Result.failure(DataResponseError.invalidUrl))
      return
    }
    
    writingQueue.async(flags: .barrier) {
      
      if self.tasks.keys.contains(url) {
        print("cnt \(self.tasks[url]!)")
        self.tasks[url]?.append(completion)
      } else {
        self.tasks[url] = [completion]
        let dataTask = self.session.dataTask(with: url, completionHandler: { [weak self] (data, response, error) in
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
          
          print("imageLoaderService \(urlString) count \(completionHandlers.count)")
          for completionHandler in completionHandlers {
            completionHandler(.success(data))
          }
          
          self?.tasks[url] = nil
          
        })
        dataTask.resume()
      }
      
    } // disp
    
  }
  
}
