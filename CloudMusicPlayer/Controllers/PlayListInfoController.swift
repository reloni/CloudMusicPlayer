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
	@IBOutlet weak var tableView: UITableView!

	var bag = DisposeBag()

	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(animated)
		bag = DisposeBag()
	}
	
	func getCell(indexPath: NSIndexPath) -> UITableViewCell {
		let objects = model.playList.items
		if  indexPath.row == objects.count {
			let cell = tableView.dequeueReusableCellWithIdentifier("LastItemCell", forIndexPath: indexPath) as! LastItemCell
			cell.itemsCount = UInt(objects.count)
			cell.titleText = "Tracks"
			cell.refreshTitle()
			return cell
		}
		
		let cell = tableView.dequeueReusableCellWithIdentifier("TrackCell", forIndexPath: indexPath) as! TrackCell
		cell.trackCurrentTimeProgressStackViewHeightConstraint?.constant = CGFloat(integerLiteral: 0)
		
		guard let track = objects[indexPath.row] else { return cell }
		
		cell.trackTitleLabel.text = track.title
		createTaskForAddItemToPlayList(cell.showMenuButton.rx_tap, artists: [], albums: [], tracks: [track]).subscribe().addDisposableTo(cell.bag)
		
		
		MainModel.sharedInstance.loadMetadataObjectForTrackInPlayListByIndex(indexPath.row, playList: model.playList).observeOn(MainScheduler.instance)
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
		
		MainModel.sharedInstance.player.currentItem.observeOn(MainScheduler.instance).flatMapLatest { [weak self, weak cell] item -> Observable<Bool> in
			guard let cell = cell, object = self else { return Observable.empty() }
			
			let animate = {
				UIView.animateWithDuration(0.9, delay: 0, usingSpringWithDamping: 0.2,
					initialSpringVelocity: 10.0, options: [.CurveEaseOut], animations: {
						cell.layoutIfNeeded()
					}, completion: nil)
			}
			
			if let item = item where track.uid == item.streamIdentifier.streamResourceUid && object.model.playList.uid == object.model.mainModel.currentPlayingContainerUid {
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
			}.observeOn(ConcurrentDispatchQueueScheduler(globalConcurrentQueueQOS: DispatchQueueSchedulerQOS.Utility))
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
		
		return cell
	}
	
	func getPlayListCell() -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("PlayListHeaderCell") as! PlayListCell
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
	
	func createTaskForAddItemToPlayList(event: ControlEvent<Void>, artists: [ArtistType], albums: [AlbumType], tracks: [TrackType]) -> Observable<Void> {
		return event.doOnNext { [unowned self] in
			let alert = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
			let addToPlayList = UIAlertAction(title: "Add to playlist", style: .Default) { [weak self] _ in
				let selectController = ViewControllers.addItemsToPlayListController.getController() as! AddItemsToPlayListController
				selectController.model = AddItemsToPlayListModel(mainModel: MainModel.sharedInstance, artists: artists, albums: albums, tracks: tracks)
				self?.presentViewController(selectController, animated: true, completion: nil)
			}
			let cancel = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
			alert.addAction(addToPlayList)
			alert.addAction(cancel)
			self.presentViewController(alert, animated: true, completion: nil)
		}
	}
}

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