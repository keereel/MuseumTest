//
//  ImageLoaderService.swift
//  MuseumTest
//
//  Created by Седых Кирилл Сергеевич on 30.07.2020.
//  Copyright © 2020 Sedykh Kirill. All rights reserved.
//

import Foundation

final class ImageLoaderService {
  
  private let session: URLSession = URLSession(configuration: .default)
  
  typealias completionHandler = (Result<Data, DataResponseError>) -> Void
  
  private var tasks = [URL: [completionHandler]]()
  
  func fetchImage(with urlString: String, completion: @escaping completionHandler) {
    guard let url = URL(string: urlString) else {
      completion(Result.failure(DataResponseError.invalidUrl))
      return
    }
    
    if tasks.keys.contains(url) {
      tasks[url]?.append(completion)
    } else {
      tasks[url] = [completion]
      let dataTask = session.dataTask(with: url, completionHandler: { [weak self] (data, response, error) in
        DispatchQueue.main.async {
          
          guard let completionHandlers = self?.tasks[url] else {
            return
          }
          guard let data = data else {
            for completionHandler in completionHandlers {
              completionHandler(Result.failure(DataResponseError.network))
            }
            return
          }
          
          for completionHandler in completionHandlers {
            completionHandler(.success(data))
          }
          
        }
      })
      dataTask.resume()
    }
  }
  
}
