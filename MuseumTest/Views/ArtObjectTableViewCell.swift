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
  
  private let imgSize: CGFloat = 100
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
    img.backgroundColor = .yellow
    contentView.addSubview(title)
    title.backgroundColor = .green
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
  
  func configure(title: String) {
    self.title.text = title
    img.image = nil
  }
  
  func setImage(image: UIImage?) {
    if img.image == nil {
      img.image = image
    }
  }
  
}
