//
//  ArtObject.swift
//  MuseumTest
//
//  Created by Sedykh Kirill on 26.07.2020.
//  Copyright © 2020 Sedykh Kirill. All rights reserved.
//

import Foundation

struct ArtObject: Decodable {
  let title: String
  let objectNumber: String
  let webImage: WebImage?
  
  init(title: String,
       objectNumber: String,
       webImage: WebImage?) {
    self.title = title
    self.objectNumber = objectNumber
    self.webImage = webImage
  }
}
