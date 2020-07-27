//
//  ViewController.swift
//  MuseumTest
//
//  Created by Sedykh Kirill on 25.07.2020.
//  Copyright © 2020 Sedykh Kirill. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

  private var textField: UITextField = UITextField()
  private var showButton: UIButton = UIButton()
  
  //let apiClient: MuseumApiClient = MuseumApiClient()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    view.addSubview(textField)
    textField.borderStyle = .roundedRect
    textField.tintColor = .darkGray
    textField.text = "Rembrand"
    
    view.addSubview(showButton)
    showButton.backgroundColor = .darkGray
    showButton.tintColor = .white
    showButton.setTitle("Show results", for: .normal)
    showButton.addTarget(self, action: #selector(showButtonTapped(sender:)), for: .touchUpInside)
    
    setConstraints()
    
    // TODO move to aoVC
    /*
    apiClient.fetchArtObjects(queryString: "Rembrand") { (result) in
      switch result {
      case .failure(let error):
        print("ERROR: \(error.description)")
      case .success(let collection):
        print("collection.count \(collection.count)")
        collection.artObjects.forEach { (artObject) in
          print("artObject \(artObject)")
        }

      }
    }
    */
    
  }
  
  private func setConstraints() {
    let textFieldHeight: CGFloat = 40
    let buttonHeight: CGFloat = 44
    
    textField.translatesAutoresizingMaskIntoConstraints = false
    textField.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.5).isActive = true
    textField.heightAnchor.constraint(equalToConstant: textFieldHeight).isActive = true
    textField.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    textField.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -0.65*textFieldHeight).isActive = true
    
    showButton.translatesAutoresizingMaskIntoConstraints = false
    showButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.5).isActive = true
    showButton.heightAnchor.constraint(equalToConstant: buttonHeight).isActive = true
    showButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    showButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 0.65*buttonHeight).isActive = true
  }
  
  
  @objc func showButtonTapped(sender: UIButton) {
    guard let queryString = textField.text else {
      // TODO alert please enter string
      return
    }
    //let artObjectsVM = ArtObjectsViewModel(queryString: queryString)
    //let artObjectsVC = ArtObjectsViewController(viewModel: artObjectsVM)
    let artObjectsVC = ArtObjectsViewController(queryString: queryString)
    self.navigationController?.pushViewController(artObjectsVC, animated: true)
  }

}
