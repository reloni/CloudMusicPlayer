//
//  PlayerQueueController.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 17.04.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import UIKit
import RxSwift

class PlayerQueueController: UIViewController {
	let bag = DisposeBag()
	
	@IBOutlet weak var progressBar: UIProgressView!
	@IBOutlet weak var currentTimeLabel: UILabel!
	@IBOutlet weak var fullTimeLabel: UILabel!
	@IBOutlet weak var backButton: UIButton!
	@IBOutlet weak var playPauseButton: UIButton!
	@IBOutlet weak var forwardButton: UIButton!
	@IBOutlet weak var queueTableView: UITableView!
	
	override func viewDidLoad() {
		automaticallyAdjustsScrollViewInsets = false
		playPauseButton.setTitle(rxPlayer.playing == true ? "Pause" : "Play", forState: .Normal)
		
		forwardButton.rx_tap.bindNext {
			rxPlayer.toNext(true)
			}.addDisposableTo(bag)
		
		backButton.rx_tap.bindNext {
			rxPlayer.toPrevious(true)
			}.addDisposableTo(bag)
		
		playPauseButton.rx_tap.bindNext {
			if rxPlayer.playing {
				rxPlayer.pause()
			} else {
				rxPlayer.resume(true)
			}
		}.addDisposableTo(bag)
		
//		rxPlayer.rx_observe().observeOn(MainScheduler.instance).bindNext { [weak self] e in
//			if case PlayerEvents.Started = e {
//				self?.playPauseButton.setTitle("Pause", forState: .Normal)
//			} else if case PlayerEvents.Paused = e {
//				self?.playPauseButton.setTitle("Play", forState: .Normal)
//			} else if case PlayerEvents.Stopped = e {
//				self?.playPauseButton.setTitle("Play", forState: .Normal)
//			} else if case PlayerEvents.Resumed = e {
//				self?.playPauseButton.setTitle("Pause", forState: .Normal)
//			}
//		}.addDisposableTo(bag)
		
		dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
			rxPlayer.currentItem.flatMapLatest { e -> Observable<MediaItemMetadataType?> in
				guard let e = e else { return Observable.just(nil) }
				return rxPlayer.loadMetadata(e.streamIdentifier)
				//return e?.loadMetadata() ?? Observable.just(nil)
				}.map { e -> String in
					return e?.duration?.asTimeString ?? "0: 00"
				}.observeOn(MainScheduler.instance).bindTo(self.fullTimeLabel.rx_text).addDisposableTo(self.bag)
			
			rxPlayer.currentItemTime.bindNext { [weak self] time in
				guard let time = time else { self?.currentTimeLabel.text = "0: 00"; return }
				
				dispatch_async(dispatch_get_main_queue()) { [weak self] in
					self?.currentTimeLabel.text = time.currentTime?.asString
					if let currentSec = time.currentTime?.safeSeconds, fullSec = time.duration?.safeSeconds {
						self?.progressBar.progress = Float(currentSec / fullSec)
					} else {
						self?.progressBar.progress = 0
					}
				}
			}.addDisposableTo(self.bag)
			
			rxPlayer.loadMetadataForItemsInQueue().bindNext { [weak self] meta in
				self?.queueTableView.indexPathsForVisibleRows?.forEach { indexPath in
					if rxPlayer.getItemAtPosition(indexPath.row)?.streamIdentifier.streamResourceUid == meta.resourceUid {
						dispatch_async(dispatch_get_main_queue()) {
							if let cell = self?.queueTableView.cellForRowAtIndexPath(indexPath) as? QueueTrackCell {
								self?.setCellMetadata(cell, meta: meta)
							}
						}
					}
				}
			}.addDisposableTo(self.bag)
		}
	}
	
	override func viewDidAppear(animated: Bool) {
	}
	
	func setCellMetadata(cell: QueueTrackCell, meta: MediaItemMetadataType?) {
		if let artwork = meta?.artwork {
			cell.albumArtImage.image = nil
			cell.albumArtImage.image = UIImage(data: artwork)
		}
		cell.artistNameLabel.text = meta?.artist
		cell.trackTimeLabel.text = meta?.duration?.asTimeString
		cell.trackTitleLabel.text = meta?.title
	}
	
	deinit {
		print("PlayerQueueController deinit")
	}
}

extension PlayerQueueController : UITableViewDelegate {
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		if let item = rxPlayer.getItemAtPosition(indexPath.row) {
			rxPlayer.playUrl(item.streamIdentifier, clearQueue: false)
		}

	}
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return rxPlayer.count
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("QueueTrack", forIndexPath: indexPath) as! QueueTrackCell
	
		cell.selectionStyle = .None
		
		if let item = rxPlayer.getItemAtPosition(indexPath.row) {
			if let meta = try! rxPlayer.mediaLibrary.getMetadataObjectByUid(item.streamIdentifier) {
				setCellMetadata(cell, meta: meta)
			} else {
				cell.albumArtImage.image = nil
				cell.artistNameLabel.text = nil
				cell.trackTimeLabel.text = nil
				cell.trackTitleLabel.text = (item.streamIdentifier as? CloudAudioResource)?.name ?? ""
			}
			
			cell.bag = DisposeBag()
			rxPlayer.currentItem.bindNext { [unowned cell] newCurrent in
				dispatch_async(dispatch_get_main_queue()) {
					if item.streamIdentifier.streamResourceUid == newCurrent?.streamIdentifier.streamResourceUid {
						cell.backgroundColor = UIColor(red: 204/255, green: 255/255, blue: 253/255, alpha: 1)
					} else {
						cell.backgroundColor = UIColor.whiteColor()
					}
				}
			}.addDisposableTo(cell.bag)
		}
		
		return cell
	}
	
	func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
	}
	
	func tableView(tableView: UITableView, didEndDisplayingCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
	}
	
	func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
	}
}