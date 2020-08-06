//
//  ArtObjectTableViewCell.swift
//  MuseumTest
//
//  Created by Sedykh Kirill on 26.07.2020.
//  Copyright © 2020 Sedykh Kirill. All rights reserved.
//

import Foundation
import UIKit

final class ArtObjectTableViewCell: UITableViewCell {
  
  private var img: UIImageView = UIImageView()
  private var title: UILabel = UILabel()
  var cellIndex: Int = 0
  
  private var imgSize: CGFloat {
    CommonParameters.shared.thumbnailSideSize
  }
  private let contentOffsetX: CGFloat = 20
  private let contentOffsetY: CGFloat = 10
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }
  
  deinit {
    print("DEINIT cell")
  }
  
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    
    contentView.addSubview(img)
    img.backgroundColor = .lightGray
    img.contentMode = .scaleAspectFill
    img.clipsToBounds = true
    contentView.addSubview(title)
    title.numberOfLines = 0
    
    setConstraints()
  }
  
  private func setConstraints() {
    img.translatesAutoresizingMaskIntoConstraints = false
    let imgHeightConstraint = img.heightAnchor.constraint(equalToConstant: imgSize)
    imgHeightConstraint.isActive = true
    imgHeightConstraint.priority = UILayoutPriority(999)
    img.widthAnchor.constraint(equalToConstant: imgSize).isActive = true
    img.topAnchor.constraint(equalTo: contentView.topAnchor, constant: contentOffsetY).isActive = true
    img.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -contentOffsetY).isActive = true
    img.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: contentOffsetX).isActive = true
    
    title.translatesAutoresizingMaskIntoConstraints = false
    title.leadingAnchor.constraint(equalTo: img.trailingAnchor, constant: contentOffsetX).isActive = true
    title.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -contentOffsetX).isActive = true
    title.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
  }
  
  func configure(title: String, cellIndex: Int) {
    self.title.text = title
    self.cellIndex = cellIndex
    img.image = nil
  }
  
  func setImage(image: UIImage?) {
    if img.image == nil {
      img.image = image
    }
    print("VC CELL: image setting done: \(cellIndex)")
  }
  
}
