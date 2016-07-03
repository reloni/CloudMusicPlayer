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
	
	func getLastItemCell(text: String, itemsCount: uint, indexPath: NSIndexPath) -> LastItemCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("LastItemCell", forIndexPath: indexPath) as! LastItemCell
		cell.itemsCount = UInt(itemsCount)
		cell.titleText = text
		cell.refreshTitle()
		return cell
	}

	
	func getTrackCell(track: TrackType, indexPath: NSIndexPath, mainModel: MainModel) -> TrackCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("TrackCell", forIndexPath: indexPath) as! TrackCell
				
		cell.trackCurrentTimeProgressStackViewHeightConstraint?.constant = CGFloat(integerLiteral: 0)
		
		let syncTrack = track.synchronize()
		cell.trackTitleLabel.text = syncTrack.title
		
		let trackUid = syncTrack.uid
		cell.storageStatusImage?.image = mainModel.player.downloadManager.fileStorage.getItemState(trackUid).getImage()
		
		mainModel.loadMetadataObjectForTrackByUid(trackUid)
			.subscribeOn(ConcurrentDispatchQueueScheduler.utility).observeOn(MainScheduler.instance)
			.bindNext { [weak cell] meta in
				guard let cell = cell else { return }
				guard let meta = meta else { cell.trackTitleLabel.text = "Unknown"; return }
				
				cell.durationLabel.text = meta.duration?.asTimeString
				if let album = meta.album, artist = meta.artist {
					cell.albumAndArtistLabel?.text = "\(album) - \(artist)"
				}
				if let artwork = meta.artwork, image = UIImage(data: artwork) {
					cell.albumArtworkImage?.image = image
				}
			}.addDisposableTo(cell.bag)
		
		return cell
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

extension UIAlertAction {
	static func mediaActionsTrackDefaultDeleteAction(trackUid: String, model: MainModel) -> UIAlertAction {
		return UIAlertAction(title: "Delete", style: .Default) { _ in
			model.player.downloadManager.fileStorage.deleteItem(trackUid)
		}
	}
	
	static func mediaActionsTrackDefaultSaveAction(trackUid: String, model: MainModel) -> UIAlertAction {
		return UIAlertAction(title: "Save", style: .Default) { _ in
			model.player.downloadManager.fileStorage.moveToPermanentStorage(trackUid)
		}
	}
	
	static func mediaActionsTrackDefaultDeleteFromCacheAction(trackUid: String, model: MainModel) -> UIAlertAction {
		return UIAlertAction(title: "Delete from cache", style: .Default) { _ in
			model.player.downloadManager.fileStorage.deleteItem(trackUid)
		}
	}
	
	static func mediaActionsTrackDefaultDownloadAction(trackUid: String, model: MainModel) -> UIAlertAction {
		return UIAlertAction(title: "Download", style: .Default) { _ in
			
		}
	}
	
	static func mediaActionsPlayContainer(container: TrackContainerType, mainModel: MainModel) -> UIAlertAction {
		return UIAlertAction(title: "Paly", style: .Default) { _ in
			mainModel.play(container)
		}
	}
	
	static func mediaActionsCancel(handler: ((UIAlertAction) -> Void)? = nil) -> UIAlertAction {
		return UIAlertAction(title: "Cancel", style: .Cancel, handler: handler)
	}
	
	static func mediaActionsAddAlbumToPlayList(album: AlbumType, presentator: UIViewController, mainModel: MainModel) -> UIAlertAction {
		return UIAlertAction(title: "Add to playlist", style: .Default) { _ in
			let selectController = ViewControllers.addItemsToPlayListController.getController() as! AddItemsToPlayListController
			selectController.model = AddItemsToPlayListModel(mainModel: mainModel, artists: [], albums: [album], tracks: [])
			presentator.presentViewController(selectController, animated: true, completion: nil)
		}
	}
	
	static func mediaActionsAddArtistToPlayList(artist: ArtistType, presentator: UIViewController, mainModel: MainModel) -> UIAlertAction {
		return UIAlertAction(title: "Add to playlist", style: .Default) { _ in
			let selectController = ViewControllers.addItemsToPlayListController.getController() as! AddItemsToPlayListController
			selectController.model = AddItemsToPlayListModel(mainModel: mainModel, artists: [artist], albums: [], tracks: [])
			presentator.presentViewController(selectController, animated: true, completion: nil)
		}
	}
	
	static func mediaActionsAddTrackToPlayList(track: TrackType, presentator: UIViewController, mainModel: MainModel) -> UIAlertAction {
		return UIAlertAction(title: "Add to playlist", style: .Default) { _ in
			let selectController = ViewControllers.addItemsToPlayListController.getController() as! AddItemsToPlayListController
			selectController.model = AddItemsToPlayListModel(mainModel: mainModel, artists: [], albums: [], tracks: [track])
			presentator.presentViewController(selectController, animated: true, completion: nil)
		}
	}
}