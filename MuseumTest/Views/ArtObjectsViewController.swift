//
//  ArtObjectsViewController.swift
//  MuseumTest
//
//  Created by Sedykh Kirill on 25.07.2020.
//  Copyright © 2020 Sedykh Kirill. All rights reserved.
//

import Foundation
import UIKit

final class ArtObjectsViewController: UIViewController {
  
  private var tableView: UITableView = UITableView()
  private let cellId: String = "Cell"
  private var previousWillDisplayIndexPath: IndexPath = IndexPath(row: 0, section: 0)
  
  private var viewModel: ArtObjectsViewModel!
  private var isBeingUpdatedNow: Bool = false
  
  init(queryString: String) {
    super.init(nibName: nil, bundle: nil)
    let vm = ArtObjectsViewModel(queryString: queryString, delegate: self)
    self.viewModel = vm
  }
  
  deinit {
    print("DEINIT VC")
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
  
    view.backgroundColor = .lightGray
    
    view.addSubview(tableView)
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
    tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
    tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
    
    // tableView setup
    tableView.dataSource = self
    tableView.delegate = self
    tableView.register(ArtObjectTableViewCell.self, forCellReuseIdentifier: cellId)
    
    isBeingUpdatedNow = true
    viewModel.fetch(page: viewModel.firstPage)
  }
  
}

extension ArtObjectsViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    if previousWillDisplayIndexPath.row < indexPath.row {
      //print("MOVE FORWARD")
      if indexPath.row > viewModel.maxIndex(onPage: viewModel.pageNumber(for: indexPath)) - 3
        && !isBeingUpdatedNow
        //&& viewModel.pageNumber(for: indexPath) != viewModel.lastPage
        {
          print("load next page \(viewModel.pageNumber(for: indexPath) + 1)")
          isBeingUpdatedNow = true
          viewModel.fetch(page: viewModel.pageNumber(for: indexPath) + 1)
      }
    } else if previousWillDisplayIndexPath.row > indexPath.row {
      //print("MOVE BACKWARD")
      if indexPath.row < viewModel.minIndex(onPage: viewModel.pageNumber(for: indexPath)) + 3
        && !isBeingUpdatedNow
        && viewModel.pageNumber(for: indexPath) != viewModel.firstPage {
          print("load prev page \(viewModel.pageNumber(for: indexPath) - 1)")
          isBeingUpdatedNow = true
          viewModel.fetch(page: viewModel.pageNumber(for: indexPath) - 1)
      }
    }
    previousWillDisplayIndexPath = indexPath
  }
}

extension ArtObjectsViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return viewModel.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as? ArtObjectTableViewCell else {
      return UITableViewCell()
    }
    
    cell.configure(title: viewModel.objects[indexPath.row].title)
    print("VC: cellForRowAt:\(indexPath.row)")
    viewModel.fetchImage(index: indexPath.row) { (result) in
      //DispatchQueue.main.async {
        switch result {
        case .success(let image):
          cell.setImage(image: image)
          print("VC: cellForRowAt:\(indexPath.row) image set")
        case .failure(let error):
          // TODO error
          print("VC: image loading error: \(error.description)")
        }
      //}
    }
    
    return cell
  }
}

extension ArtObjectsViewController: ArtObjectsViewModelDelegate {
  func onFetchCompleted(indexPaths: [IndexPath]) {
    //
    print("VC: onFetchCompleted viewModel.count \(viewModel.count)")
    print("VC: onFetchCompleted tableView.numberOfRows: \(tableView.numberOfRows(inSection: 0))")
    print("VC: onFetchCompleted indexPaths \(indexPaths)")
    //
    
    UIView.performWithoutAnimation {
      tableView.beginUpdates()
      indexPaths.forEach { (indexPath) in
        //print("  tableView.numberOfRows = \(tableView.numberOfRows(inSection: 0))")
        if indexPath.row > tableView.numberOfRows(inSection: 0) - 1 {
          print("VC: onFetchCompleted insert: \(indexPath.row)")
          tableView.insertRows(at: [indexPath], with: .none)
        } else {
          //print("VC: onFetchCompleted reload: \(indexPath.row)")
          //tableView.reloadRows(at: [indexPath], with: .none)
        }
      }
      tableView.endUpdates()
    }
    isBeingUpdatedNow = false
  }
  
  func onFetchFailed(errorText: String) {
    // TODO alert
    print("!!! FETCH FAILED: \(errorText)")
    isBeingUpdatedNow = false
  }
}
