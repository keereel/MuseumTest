//
//  DataResponseError.swift
//  MuseumTest
//
//  Created by Sedykh Kirill on 25.07.2020.
//  Copyright © 2020 Sedykh Kirill. All rights reserved.
//

import Foundation

enum DataResponseError: Error {
  case network
  case decoding
  case query
  case invalidUrl
  
  var description: String {
    switch self {
    case .network:
      return "An error occurred while fetching data"
    case .decoding:
      return "An error occurred while decoding data"
    case .query:
      return "Incorrect query"
    case .invalidUrl:
      return "Invalid URL"
    }
  }
}
