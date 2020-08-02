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
      return "Unable to load art objects due to network connection issues"
    case .decoding:
      return "Unable to load art objects due to invalid data received from server"
    case .query:
      return "Unable to load data due to invalid query"
    case .invalidUrl:
      return "Unable to load data due to invalid URL"
    }
  }
}
