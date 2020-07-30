//
//  TextError.swift
//  MuseumTest
//
//  Created by Седых Кирилл Сергеевич on 30.07.2020.
//  Copyright © 2020 Sedykh Kirill. All rights reserved.
//

import Foundation

struct TextError: Error {
  let description: String
  
  init(_ text: String) {
    self.description = text
  }
}
