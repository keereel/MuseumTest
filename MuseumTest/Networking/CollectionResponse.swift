//
//  CollectionResponse.swift
//  MuseumTest
//
//  Created by Sedykh Kirill on 25.07.2020.
//  Copyright © 2020 Sedykh Kirill. All rights reserved.
//

import Foundation

struct CollectionResponse: Decodable {
  var query: String?
  var pageNumber: Int?
  let count: Int
  let artObjects: [ArtObject]
}
