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
  
  private var errorIsBeingDisplayedNow: Bool = false
  private var errorMessagesQueue: [String] = []
  private var recentlyDisplayedErrors: [String: Date] = [:]
  private let sameErrorDisplayingInterval: Int = 10
  
  // this timer is just checks if refresh is needed, but refreshing mechanism is in viewModel and refreshing occurs according to refresh interval - 5 mins
  private weak var autoRefreshTimer: Timer?
  private let checkIsRefreshNeededInterval = 20
  
  init(queryString: String) {
    super.init(nibName: nil, bundle: nil)
    let vm = ArtObjectsViewModel(queryString: queryString, delegate: self)
    self.viewModel = vm
    self.autoRefreshTimer = Timer.scheduledTimer(timeInterval: TimeInterval(checkIsRefreshNeededInterval),
                                      target: self,
                                      selector: #selector(autoRefreshTimerFires(_:)),
                                      userInfo: nil,
                                      repeats: true)
  }
  
  deinit {
    print("DEINIT VC")
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    autoRefreshTimer?.invalidate()
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

// MARK: UITableViewDelegate
extension ArtObjectsViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    if previousWillDisplayIndexPath.row < indexPath.row {
      if indexPath.row > viewModel.maxIndex(onPage: viewModel.pageNumber(for: indexPath)) - 3
        && !isBeingUpdatedNow {
          isBeingUpdatedNow = true
          viewModel.fetch(page: viewModel.pageNumber(for: indexPath) + 1)
      }
    } else if previousWillDisplayIndexPath.row > indexPath.row {
      if indexPath.row < viewModel.minIndex(onPage: viewModel.pageNumber(for: indexPath)) + 3
        && !isBeingUpdatedNow
        && viewModel.pageNumber(for: indexPath) != viewModel.firstPage {
          isBeingUpdatedNow = true
          viewModel.fetch(page: viewModel.pageNumber(for: indexPath) - 1)
      }
    }
    previousWillDisplayIndexPath = indexPath
  }
}

// MARK: UITableViewDataSource
extension ArtObjectsViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return viewModel.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as? ArtObjectTableViewCell else {
      return UITableViewCell()
    }
    if cell.cellIndex == indexPath.row && indexPath.row != 0 {
      return cell
    }
    
    let artObject = viewModel.artObject(for: indexPath)
    cell.configure(title: artObject.title, cellIndex: indexPath.row)
    
    viewModel.fetchImage(index: indexPath.row) { [weak self] (result) in
      DispatchQueue.main.async {
        var cellToSetImage = cell
        if cellToSetImage.cellIndex != indexPath.row {
          let indexPathForCellToSetImage = IndexPath(row: indexPath.row, section: 0)
          guard let tmpcell = tableView.cellForRow(at: indexPathForCellToSetImage) as? ArtObjectTableViewCell else {
            return
          }
          cellToSetImage = tmpcell
        }
        
        switch result {
        case .success(let image):
          cellToSetImage.setImage(image: image)
        case .failure(let error):
          self?.showError(withText: error.description)
        }
      }
    }
    
    return cell
  }
}

// MARK: ViewModel Delegate
extension ArtObjectsViewController: ArtObjectsViewModelDelegate {
  func onFetchCompleted(indexPaths: [IndexPath]) {
    UIView.performWithoutAnimation {
      tableView.beginUpdates()
      indexPaths.forEach { (indexPath) in
        if indexPath.row > tableView.numberOfRows(inSection: 0) - 1 {
          tableView.insertRows(at: [indexPath], with: .none)
        }
      }
      tableView.endUpdates()
    }
    isBeingUpdatedNow = false
  }
  
  func onFetchFailed(errorText: String) {
    isBeingUpdatedNow = false
    showError(withText: errorText)
  }
}

// MARK: Show errors
extension ArtObjectsViewController {
  private func showError(withText errorText: String) {
    DispatchQueue.main.async {
      if let sameErrorLastDate = self.recentlyDisplayedErrors[errorText],
        Date() < sameErrorLastDate.addingTimeInterval(TimeInterval(self.sameErrorDisplayingInterval)) {
        return
      }
      
      guard !self.errorIsBeingDisplayedNow else {
        if self.errorMessagesQueue.firstIndex(of: errorText) == nil {
          self.errorMessagesQueue.append(errorText)
        }
        return
      }
      
      self.errorIsBeingDisplayedNow = true
      self.recentlyDisplayedErrors[errorText] = Date()
      
      let alert = UIAlertController(title: nil, message: errorText, preferredStyle: .alert)
      
      let action: UIAlertAction = UIAlertAction(title: "OK", style: .default) { [weak self] _ in
        guard let self = self else {
          return
        }
        self.errorIsBeingDisplayedNow = false
        if self.errorMessagesQueue.count > 0 {
          self.showError(withText: self.errorMessagesQueue[0])
          self.errorMessagesQueue.remove(at: 0)
        }
      }
      alert.addAction(action)
      
      self.present(alert, animated: true)
    }
  }
}

// MARK: Timer
extension ArtObjectsViewController {
  @objc private func autoRefreshTimerFires(_ timer: Timer) {
    guard let visibleIndexPaths = tableView.indexPathsForVisibleRows,
    let minIndexPath = visibleIndexPaths.min(),
    let maxIndexPath = visibleIndexPaths.max() else {
      return
    }
    
    let minPage = viewModel.pageNumber(for: minIndexPath)
    let maxPage = viewModel.pageNumber(for: maxIndexPath)
    for pageNum in minPage...maxPage {
      viewModel.fetch(page: pageNum)
    }
  }
}
