//
//  PlayListInfoController.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 21.05.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import AVFoundation

class PlayListInfoController: UIViewController {
	var model: PlayListInfoModel!
	//@IBOutlet weak var tableView: UITableView!
	var tableViewController: UniversalTableViewController!

	var bag = DisposeBag()

	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(animated)
		bag = DisposeBag()
	}
	
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		guard let controller = segue.destinationViewController as? UniversalTableViewController
			where segue.identifier == Segues.playListInfoControllerEmbeddedTable.rawValue else { return }
		
		tableViewController = controller
		tableViewController.tableDelegate = self
		tableViewController.tableDataSource = self
	}
	
	func getCell(indexPath: NSIndexPath) -> UITableViewCell {
		let objects = model.playList.items
		if  indexPath.row == objects.count {
			let cell = tableViewController.tableView.dequeueReusableCellWithIdentifier("LastItemCell", forIndexPath: indexPath) as! LastItemCell
			cell.itemsCount = UInt(objects.count)
			cell.titleText = "Tracks"
			cell.refreshTitle()
			return cell
		}
		
		let cell = tableViewController.tableView.dequeueReusableCellWithIdentifier("TrackCell", forIndexPath: indexPath) as! TrackCell
		cell.trackCurrentTimeProgressStackViewHeightConstraint?.constant = CGFloat(integerLiteral: 0)
		
		guard let track = objects[indexPath.row] else { return cell }
		
		cell.trackTitleLabel.text = track.title
		
		cell.showMenuButton.rx_tap.bindNext { [weak self] in
			guard let object = self else { return }
			let alert = object.createMenu(track)
			alert.view.setNeedsLayout()
			object.presentViewController(alert, animated: true, completion: nil)
		}.addDisposableTo(cell.bag)
		
		let trackUid = track.uid
		cell.storageStatusImage?.image = model.mainModel.player.downloadManager.fileStorage.getItemState(trackUid).getImage()
		
		tableViewController.subscribeTrackCellToDefaultEvents(cell, trackUid: trackUid, containerUid: model.playList.uid, mainModel: model.mainModel)
		
		model.mainModel.loadMetadataObjectForTrackInPlayListByIndex(indexPath.row, playList: model.playList)
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
	
	func getPlayListCell() -> UITableViewCell {
		let cell = tableViewController.tableView.dequeueReusableCellWithIdentifier("PlayListHeaderCell") as! PlayListCell
		cell.playListNameLabel.text = model.playList.name
		cell.itemsCountLabel?.text = "Tracks: \(model.playList.items.count)"
		cell.playButton?.selected = model.checkPlayListPlaying()
		if let art = model.playList.items.first?.album.artwork {
			cell.playListImage?.image = UIImage(data: art)
		}
		cell.shuffleButton?.selected = MainModel.sharedInstance.player.shuffleQueue
		cell.repeatButton?.selected = MainModel.sharedInstance.player.repeatQueue
		
		cell.shuffleButton?.rx_tap.observeOn(MainScheduler.instance).bindNext { [weak cell] in
			guard let button = cell?.shuffleButton else { return }
			button.selected = !button.selected
			MainModel.sharedInstance.player.shuffleQueue = button.selected
		}.addDisposableTo(cell.bag)
		
		cell.repeatButton?.rx_tap.observeOn(MainScheduler.instance).bindNext { [weak cell] in
			guard let button = cell?.repeatButton else { return }
			button.selected = !button.selected
			MainModel.sharedInstance.player.repeatQueue = button.selected
			}.addDisposableTo(cell.bag)
		
		cell.playButton?.rx_tap.observeOn(MainScheduler.instance).bindNext { [weak self] in
			guard let object = self else { return }
			object.model.mainModel.togglePlayer(object.model.playList)
		}.addDisposableTo(cell.bag)
		
		if let playButton = cell.playButton {
			model.playing.asDriver(onErrorJustReturn: false).drive(playButton.rx_selected).addDisposableTo(cell.bag)
		}
		
		return cell
	}
	
	func createMenu(forTrack: TrackType) -> UIAlertController {
		let trackUid = forTrack.synchronize().uid
		
		let alert = UIAlertController(title: "Choose action", message: nil, preferredStyle: .ActionSheet)
		
		switch model.mainModel.player.downloadManager.fileStorage.getItemState(trackUid) {
		case .inPermanentStorage: alert.addAction(UIAlertAction(title: "Delete", style: .Default, handler: { [weak self] _ in
			self?.model.mainModel.player.downloadManager.fileStorage.deleteItem(trackUid)
				}))
		case .inTempStorage:
			alert.addAction(UIAlertAction(title: "Save", style: .Default, handler: { [weak self] _ in
			self?.model.mainModel.player.downloadManager.fileStorage.moveToPermanentStorage(trackUid)
				}))
			
			alert.addAction(UIAlertAction(title: "Delete from cache", style: .Default, handler: { [weak self] _ in
				self?.model.mainModel.player.downloadManager.fileStorage.deleteItem(trackUid)
				}))
		case .notExisted: alert.addAction(UIAlertAction(title: "Download", style: .Default, handler: { _ in
			print("download")
				}))
		}
		
		let cancel = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
		alert.addAction(cancel)

		return alert
	}
}

extension PlayListInfoController : UITableViewDataSource { }

extension PlayListInfoController : UITableViewDelegate {
	func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return ViewConstants.playListHeaderHeight
	}
	
	func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		return getPlayListCell()
	}
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return model.playList.items.count + 1
	}
	
	func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		if indexPath.row == model.playList.items.count {
			return ViewConstants.itemsCountCellHeight
		} else {
			return ViewConstants.commonCellHeight
		}
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		return getCell(indexPath)
	}
	
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		guard indexPath.row < model.playList.items.count else { return }
		let selectedTrack = model.playList.items[indexPath.row]

		model.mainModel.togglePlayer(model.playList, track: selectedTrack)
	}
}