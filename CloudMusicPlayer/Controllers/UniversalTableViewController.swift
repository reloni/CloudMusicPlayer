//
//  UniversalTableViewController.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 21.06.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import UIKit
import RxSwift
import AVFoundation

class UniversalTableViewController: UIViewController {
	@IBOutlet weak var tableView: UITableView!
	var tableDataSource: UITableViewDataSource?
	var tableDelegate: UITableViewDelegate?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.
		if let tableDataSource = tableDataSource {
			tableView.dataSource = tableDataSource
		}
		
		if let tableDelegate = tableDelegate {
			tableView.delegate = tableDelegate
		}
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	func subscribeTrackCellToDefaultEvents(cell: TrackCell, trackUid: String, containerUid: String, mainModel: MainModel) {
		mainModel.player.downloadManager.fileStorage.itemStateChanged.bindNext { [weak cell] result in
			guard let cell = cell where result.uid == trackUid else { return }
			
			DispatchQueue.async(.MainQueue) {
				cell.storageStatusImage?.image = result.to.getImage()
			}
		}.addDisposableTo(cell.bag)
		
		mainModel.player.downloadManager.fileStorage.storageCleared.observeOn(MainScheduler.instance).bindNext { [weak cell] _ in
			cell?.storageStatusImage?.image = CacheState.notExisted.getImage()
		}.addDisposableTo(cell.bag)
		
		let concurrentScheduler = ConcurrentDispatchQueueScheduler.utility
		
		mainModel.player.currentItem.subscribeOn(concurrentScheduler)
			.observeOn(MainScheduler.instance).flatMapLatest { [weak cell] item -> Observable<Bool> in
				guard let cell = cell else { return Observable.empty() }
				
				let animate = {
					UIView.animateWithDuration(0.9, delay: 0, usingSpringWithDamping: 0.2,
						initialSpringVelocity: 10.0, options: [.CurveEaseOut], animations: {
							cell.layoutIfNeeded()
						}, completion: nil)
				}
				
				if let item = item where trackUid == item.streamIdentifier.streamResourceUid && containerUid == mainModel.currentPlayingContainerUid {
					if cell.trackCurrentTimeProgressStackViewHeightConstraint?.constant != ViewConstants.trackProgressBarHeight {
						cell.trackCurrentTimeProgressStackViewHeightConstraint?.constant = ViewConstants.trackProgressBarHeight
						animate()
					}
					return Observable.just(true)
				} else {
					if cell.trackCurrentTimeProgressStackViewHeightConstraint?.constant != 0 {
						cell.trackCurrentTimeProgressStackViewHeightConstraint?.constant = CGFloat(integerLiteral: 0)
						animate()
					}
					return Observable.just(false)
				}
			}.observeOn(concurrentScheduler)
			.flatMapLatest { isCurrent -> Observable<(currentTime: CMTime?, duration: CMTime?)?> in
				if isCurrent {
					return MainModel.sharedInstance.player.currentItemTime
				} else {
					return Observable.just(nil)
				}
			}.observeOn(MainScheduler.instance).bindNext { [weak cell] time in
				guard let cell = cell else { return }
				
				guard let time = time, currentSec = time.currentTime?.safeSeconds, fullSec = time.duration?.safeSeconds else {
					cell.trackCurrentTimeProgressView?.setProgress(0, animated: true)
					return
				}
				
				cell.trackCurrentTimeProgressView?.setProgress(Float(currentSec / fullSec), animated: true)
			}.addDisposableTo(cell.bag)
	}
}
