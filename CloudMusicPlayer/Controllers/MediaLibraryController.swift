//
//  MediaLibraryController.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 18.05.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class MediaLibraryController: UIViewController {
	//let model = MediaLibraryModel(player: rxPlayer)
	
	@IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var segment: UISegmentedControl!
	@IBOutlet weak var addItemsBarButton: UIBarButtonItem!
	@IBOutlet weak var processingMetadataItemsCountLabel: UILabel!
	@IBOutlet weak var processingMetadataItemsView: UIView!
	@IBOutlet weak var activityIndicator: UIActivityIndicatorView!
	@IBOutlet weak var cancelMetadataLoadButton: UIButton!
	
	var bag = DisposeBag()
	
	override func viewDidLoad() {
		//processingMetadataItemsView.hidden = true
	}
	
	override func viewWillAppear(animated: Bool) {
		segment.rx_value.bindNext { [weak self] _ in
			self?.tableView.reloadData()
			}.addDisposableTo(bag)
		
		addItemsBarButton.rx_tap.bindNext { [weak self] in
			guard let object = self else { return }
			if case 0...2 = object.segment.selectedSegmentIndex {
				let destinationController = ViewControllers.addToMediaLibraryNavigationController.getController() //as! AddToMediaLibraryNavigationController
				object.presentViewController(destinationController, animated: true, completion: nil)
			} else if object.segment.selectedSegmentIndex == 3 {
				object.showNewAlbumNameAlert()
			}
			}.addDisposableTo(bag)
		
		MainModel.sharedInstance.isMetadataLoadInProgressSubject.subscribeOn(SerialDispatchQueueScheduler(globalConcurrentQueueQOS: DispatchQueueSchedulerQOS.Utility))
			.bindNext { [weak self] progress in
				if progress == self?.processingMetadataItemsView.hidden {
					dispatch_async(dispatch_get_main_queue()) {
						UIView.animateWithDuration(0.5, animations: { self?.processingMetadataItemsView.hidden = !progress })
					}
				}
				if progress {
					self?.activityIndicator.startAnimating()
				} else {
					self?.activityIndicator.stopAnimating()
				}
			}.addDisposableTo(bag)
		
		cancelMetadataLoadButton.rx_tap.bindNext {
			MainModel.sharedInstance.cancelMetadataLoading()
			}.addDisposableTo(bag)
		
		tableView.reloadData()
	}
	
	override func viewWillDisappear(animated: Bool) {
		bag = DisposeBag()
	}
	
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "ShowPlayListInfo" && segment.selectedSegmentIndex == 3 {
			guard let index = tableView.indexPathForSelectedRow, playList = MainModel.sharedInstance.playLists?[index.row] else { return }
			guard let controller = segue.destinationViewController as? PlayListInfoController else { return }
			controller.model = PlayListInfoModel(playList: playList)
		}
	}
	
	func showNewAlbumNameAlert() {
		let alert = UIAlertController(title: "Enter play list name", message: nil, preferredStyle: .Alert)
		alert.addTextFieldWithConfigurationHandler {
			$0.placeholder = "Play list name"
		}
		let ok = UIAlertAction(title: "OK", style: .Default) { [weak self] _ in
			if let newPlayListName = alert.textFields?.first?.text {
				do {
					try MainModel.sharedInstance.player.mediaLibrary.createPlayList(newPlayListName)
					self?.tableView.reloadData()
				} catch { }
			}
		}
		let cancel = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
		alert.addAction(cancel)
		alert.addAction(ok)
		alert.view.setNeedsLayout()
		presentViewController(alert, animated: true, completion: nil)
	}
	
	func getItemsForSegment() -> Int {
		switch (segment.selectedSegmentIndex) {
		case 0: return MainModel.sharedInstance.artists?.count ?? 0
		case 1: return MainModel.sharedInstance.albums?.count ?? 0
		case 2: return MainModel.sharedInstance.tracks?.count ?? 0
		case 3: return MainModel.sharedInstance.playLists?.count ?? 0
		default: fatalError("Unknown segment index")
		}
	}
	
	func getCell(indexPath: NSIndexPath) -> UITableViewCell {
		switch (segment.selectedSegmentIndex) {
		case 0: return getArtistCell(indexPath)
		case 1: return getAlbumCell(indexPath)
		case 2: return getTrackCell(indexPath)
		case 3: return getPlayListCell(indexPath)
		default: fatalError("Unknown segment index")
		}
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
	
	
	func getArtistCell(indexPath: NSIndexPath) -> UITableViewCell {
		let objects = MainModel.sharedInstance.artists
		if let objects = objects where indexPath.row == objects.count {
			let cell = tableView.dequeueReusableCellWithIdentifier("LastItemCell", forIndexPath: indexPath) as! LastItemCell
			cell.itemsCount = UInt(objects.count)
			cell.titleText = "Artists"
			cell.refreshTitle()
			return cell
		}
		
		let cell = tableView.dequeueReusableCellWithIdentifier("ArtistCell", forIndexPath: indexPath) as! ArtistCell
		
		if let artist = objects?[indexPath.row] {
			cell.artistNameLabel.text = artist.name
			cell.albumCountLabel.text = "Albums: \(artist.albums.count)"
			createTaskForAddItemToPlayList(cell.showMenuButton.rx_tap, artists: [artist], albums: [], tracks: []).subscribe().addDisposableTo(cell.bag)
		} else {
			cell.artistNameLabel.text = "Unknown"
		}
		
		return cell
	}
	
	func getAlbumCell(indexPath: NSIndexPath) -> UITableViewCell {
		let objects = MainModel.sharedInstance.albums
		if let objects = objects where indexPath.row == objects.count {
			let cell = tableView.dequeueReusableCellWithIdentifier("LastItemCell", forIndexPath: indexPath) as! LastItemCell
			cell.itemsCount = UInt(objects.count)
			cell.titleText = "Albums"
			cell.refreshTitle()
			return cell
		}
		
		let cell = tableView.dequeueReusableCellWithIdentifier("AlbumCell", forIndexPath: indexPath) as! AlbumCell
		
		if let album = objects?[indexPath.row] {
			cell.albumNameLabel.text = album.name
			createTaskForAddItemToPlayList(cell.showMenuButton.rx_tap, artists: [], albums: [album], tracks: []).subscribe().addDisposableTo(cell.bag)
		} 
		
		MainModel.sharedInstance.loadMetadataObjectByAlbumIndex(indexPath.row).observeOn(MainScheduler.instance).bindNext { meta in
			guard let meta = meta else { cell.albumNameLabel.text = "Unknown"; return }
			
			cell.artistNameLabel.text = meta.artist
			if let artwork = meta.artwork, image = UIImage(data: artwork) {
				cell.albumArtworkImage.image = image
			}
		}.addDisposableTo(cell.bag)
		
		return cell
	}
	
	func getTrackCell(indexPath: NSIndexPath) -> UITableViewCell {
		let objects = MainModel.sharedInstance.tracks
		if let objects = objects where indexPath.row == objects.count {
			let cell = tableView.dequeueReusableCellWithIdentifier("LastItemCell", forIndexPath: indexPath) as! LastItemCell
			cell.itemsCount = UInt(objects.count)
			cell.titleText = "Tracks"
			cell.refreshTitle()
			return cell
		}
		
		let cell = tableView.dequeueReusableCellWithIdentifier("TrackCell", forIndexPath: indexPath) as! TrackCell
		
		if let track = objects?[indexPath.row] {
			cell.trackTitleLabel.text = track.title
			createTaskForAddItemToPlayList(cell.showMenuButton.rx_tap, artists: [], albums: [], tracks: [track]).subscribe().addDisposableTo(cell.bag)
		}
		
		MainModel.sharedInstance.loadMetadataObjectByTrackIndex(indexPath.row).observeOn(MainScheduler.instance).bindNext { meta in
			guard let meta = meta else { cell.trackTitleLabel.text = "Unknown"; return }
			
			if let album = meta.album, artist = meta.artist {
				cell.albumAndArtistLabel?.text = "\(album) - \(artist)"
			}
			if let artwork = meta.artwork, image = UIImage(data: artwork) {
				cell.albumArtworkImage?.image = image
			}
		}.addDisposableTo(cell.bag)

		return cell
	}
	
	func getPlayListCell(indexPath: NSIndexPath) -> UITableViewCell {
		let objects = MainModel.sharedInstance.playLists
		if let objects = objects where indexPath.row == objects.count {
			let cell = tableView.dequeueReusableCellWithIdentifier("LastItemCell", forIndexPath: indexPath) as! LastItemCell
			cell.itemsCount = UInt(objects.count)
			cell.titleText = "Play lists"
			cell.refreshTitle()
			return cell
		}
		
		let cell = tableView.dequeueReusableCellWithIdentifier("PlayListCell", forIndexPath: indexPath) as! PlayListCell
		
		if let pl = objects?[indexPath.row] ?? nil {
			cell.playListNameLabel.text = pl.name
		} else {
			cell.playListNameLabel.text = "Unknown"
		}
		
		return cell
	}
}

extension MediaLibraryController : UITableViewDelegate {
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return getItemsForSegment() + 1
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		return getCell(indexPath)
	}
}

extension MediaLibraryController : UITableViewDataSource {
	func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
		if segment.selectedSegmentIndex == 3 {
			if indexPath.row != MainModel.sharedInstance.playLists?.count {
				return UITableViewCellEditingStyle.Delete
			}
		}
		
		return UITableViewCellEditingStyle.None
	}
	
	func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
		if editingStyle == .Delete && segment.selectedSegmentIndex == 3 {
			if let pl = MainModel.sharedInstance.playLists?[indexPath.row] {
				try! MainModel.sharedInstance.player.mediaLibrary.deletePlayList(pl)
				tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
			}
		}
	}
}