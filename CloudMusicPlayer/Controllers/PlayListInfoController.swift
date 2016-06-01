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
	@IBOutlet weak var playListNameLabel: UILabel!
	@IBOutlet weak var playButton: UIButton!
	@IBOutlet weak var addBarButton: UIBarButtonItem!
	@IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var shuffleButton: UIButton!
	@IBOutlet weak var repeatButton: UIButton!
	@IBOutlet weak var downloadButton: UIButton!
	@IBOutlet weak var menuButton: UIButton!
	
	var bag = DisposeBag()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		playListNameLabel.text = model.playList.name
	}
	
	override func viewWillAppear(animated: Bool) {
		playButton.rx_tap.bindNext { [weak self] in
			guard let object = self else { return }
			MainModel.sharedInstance.player.playPlayList(object.model.playList)
		}.addDisposableTo(bag)
	}
	
	override func viewWillDisappear(animated: Bool) {
		bag = DisposeBag()
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
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return model.playList.items.count
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		//let cell = tableView.dequeueReusableCellWithIdentifier("TrackCell", forIndexPath: indexPath) as! TrackCell
		//cell.trackTitleLabel.text = model.playList.items[indexPath.row]?.title
		//return cell
		return getTrackCell(indexPath)
	}
}