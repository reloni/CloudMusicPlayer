//
//  MediaLibraryController.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 18.05.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import UIKit
import RxSwift

class MediaLibraryController: UIViewController {
	@IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var segment: UISegmentedControl!
	
	let bag = DisposeBag()
	
	override func viewDidLoad() {
		automaticallyAdjustsScrollViewInsets = false
		segment.rx_value.bindNext { [weak self] _ in
			self?.tableView.reloadData()
		}.addDisposableTo(bag)
	}
	
	func getItemsForSegment() -> Int {
		switch (segment.selectedSegmentIndex) {
		case 0: return (try? rxPlayer.mediaLibrary.getArtists().count) ?? 0
		case 1: return (try? rxPlayer.mediaLibrary.getAlbums().count) ?? 0
		case 2: return (try? rxPlayer.mediaLibrary.getTracks().count) ?? 0
		case 3: return (try? rxPlayer.mediaLibrary.getPlayLists().count) ?? 0
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
	
	func getArtistCell(indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("ArtistCell", forIndexPath: indexPath) as! ArtistCell
		
		if let artist = (try? rxPlayer.mediaLibrary.getArtists()[indexPath.row]) ?? nil {
			cell.artistNameLabel.text = artist.name
			cell.albumCountLabel.text = "Albums: \(artist.albums.count)"
		} else {
			cell.artistNameLabel.text = "Unknown"
		}
		
		return cell
	}
	
	func getAlbumCell(indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("AlbumCell", forIndexPath: indexPath) as! AlbumCell
		
		if let album = (try? rxPlayer.mediaLibrary.getAlbums()[indexPath.row]) ?? nil {
			cell.albumNameLabel.text = album.name
		} else {
			cell.albumNameLabel.text = "Unknown"
		}
		
		return cell
	}
	
	func getTrackCell(indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("TrackCell", forIndexPath: indexPath) as! TrackCell
		
		if let track = (try? rxPlayer.mediaLibrary.getTracks()[indexPath.row]) ?? nil {
			cell.trackTitleLabel.text = track.title
		} else {
			cell.trackTitleLabel.text = "Unknown"
		}
		
		return cell
	}
	
	func getPlayListCell(indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("PlayListCell", forIndexPath: indexPath) as! PlayListCell
		
		if let pl = (try? rxPlayer.mediaLibrary.getPlayLists()[indexPath.row]) ?? nil {
			cell.playListNameLabel.text = pl.name
		} else {
			cell.playListNameLabel.text = "Unknown"
		}
		
		return cell
	}
}

extension MediaLibraryController : UITableViewDelegate {
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return getItemsForSegment()
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		return getCell(indexPath)
	}
}