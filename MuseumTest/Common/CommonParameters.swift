//
//  CommonParameters.swift
//  MuseumTest
//
//  Created by Sedykh Kirill on 06.08.2020.
//  Copyright © 2020 Sedykh Kirill. All rights reserved.
//

import Foundation
import UIKit

final class CommonParameters {
  static let shared: CommonParameters = CommonParameters()
  
  let thumbnailSideSize: CGFloat = 150
  let refreshIntervalInSeconds: Int = 300
}
