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

class PlayListInfoController: UIViewController {
	var model: PlayListInfoModel!
	@IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var repeatButton: UIButton!
	
	var bag = DisposeBag()
	
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	override func viewWillAppear(animated: Bool) {
	}
	
	override func viewWillDisappear(animated: Bool) {
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
		
		if let track = objects[indexPath.row] {
			cell.trackTitleLabel.text = track.title
			createTaskForAddItemToPlayList(cell.showMenuButton.rx_tap, artists: [], albums: [], tracks: [track]).subscribe().addDisposableTo(cell.bag)
		}
		
		MainModel.sharedInstance.loadMetadataObjectForTrackInPlayListByIndex(indexPath.row, playList: model.playList).observeOn(MainScheduler.instance).bindNext { meta in
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
		let cell = tableView.dequeueReusableCellWithIdentifier("PlayListHeaderCell") as! PlayListCell
		cell.playListNameLabel.text = model.playList.name
		cell.itemsCountLabel?.text = "Tracks: \(model.playList.items.count)"
		if let art = model.playList.items.first?.album.artwork {
			cell.playListImage?.image = UIImage(data: art)
		}
		cell.shuffleButton?.selected = MainModel.sharedInstance.player.shuffleQueue
		cell.repeatButton?.selected = MainModel.sharedInstance.player.repeatQueue
		
		cell.playButton?.rx_tap.bindNext { [weak self] in
			guard let object = self else { return }
			MainModel.sharedInstance.playPlayList(object.model.playList)
		}.addDisposableTo(cell.bag)
		
		cell.shuffleButton?.rx_tap.observeOn(MainScheduler.instance).bindNext {
			guard let button = cell.shuffleButton else { return }
			button.selected = !button.selected
			MainModel.sharedInstance.player.shuffleQueue = button.selected
		}.addDisposableTo(cell.bag)
		
		cell.repeatButton?.rx_tap.observeOn(MainScheduler.instance).bindNext {
			guard let button = cell.repeatButton else { return }
			button.selected = !button.selected
			MainModel.sharedInstance.player.repeatQueue = button.selected
			}.addDisposableTo(cell.bag)
		
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
	func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		return getPlayListCell()
	}
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return model.playList.items.count + 1
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		return getCell(indexPath)
	}
	
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		guard indexPath.row < model.playList.items.count else { return }
		let selectedTrack = model.playList.items[indexPath.row]
		MainModel.sharedInstance.playPlayList(model.playList, startWith: selectedTrack)
	}
}