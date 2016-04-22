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
		
		rxPlayer.rx_observe().observeOn(MainScheduler.instance).bindNext { [weak self] e in
			if case PlayerEvents.Started = e {
				self?.playPauseButton.setTitle("Pause", forState: .Normal)
			} else if case PlayerEvents.Paused = e {
				self?.playPauseButton.setTitle("Play", forState: .Normal)
			} else if case PlayerEvents.Stopped = e {
				self?.playPauseButton.setTitle("Play", forState: .Normal)
			} else if case PlayerEvents.Resumed = e {
				self?.playPauseButton.setTitle("Pause", forState: .Normal)
			}
		}.addDisposableTo(bag)
		
		dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
			rxPlayer.currentItem.flatMapLatest { e -> Observable<MediaItemMetadataType?> in return e?.loadMetadata() ?? Observable.just(nil) }
				.map { e -> String in
					return e?.duration?.asTimeString ?? "0: 00"
				}.observeOn(MainScheduler.instance).bindTo(self.fullTimeLabel.rx_text).addDisposableTo(self.bag)
			
			rxPlayer.currentItemTime.observeOn(MainScheduler.instance).bindNext { [weak self] time in
				guard let time = time else { self?.currentTimeLabel.text = "0: 00"; return }
				
				self?.currentTimeLabel.text = time.currentTime?.asString
				if let currentSec = time.currentTime?.safeSeconds, fullSec = time.duration?.safeSeconds {
					self?.progressBar.progress = Float(currentSec / fullSec)
				} else {
					self?.progressBar.progress = 0
				}
				}.addDisposableTo(self.bag)
		}
	}
	
	override func viewDidAppear(animated: Bool) {
		reloadTableView()
	}
	
	func reloadTableView() {
//		queueTableView.indexPathsForVisibleRows?.forEach { indexPath in
//			if let cell = queueTableView.cellForRowAtIndexPath(indexPath) as? QueueTrackCell, item = rxPlayer.getItemAtPosition(indexPath.row) {
//				if let meta = rxPlayer.mediaLibrary.getMetadata(item.streamIdentifier) {
//					setCellMetadata(cell, meta: meta)
//				} else {
//					//dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) { [unowned cell, item] in
//						//item.loadMetadata().observeOn(MainScheduler.instance).bindNext { [unowned self, cell] meta in
//							//self.setCellMetadata(cell, meta: meta)
//						//	}.addDisposableTo(cell.bag)
//						
//					//}
//				}
//			}
//		}
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
			cell.albumArtImage.image = nil
			cell.artistNameLabel.text = nil
			cell.trackTimeLabel.text = nil
			cell.trackTitleLabel.text = (item.streamIdentifier as? CloudAudioResource)?.name ?? ""
			
			//cell.bag = DisposeBag()
			rxPlayer.currentItem.observeOn(MainScheduler.instance).bindNext { newCurrent in
				if item.streamIdentifier.streamResourceUid == newCurrent?.streamIdentifier.streamResourceUid {
					cell.backgroundColor = UIColor(red: 204/255, green: 255/255, blue: 253/255, alpha: 1)
				} else {
					cell.backgroundColor = UIColor.whiteColor()
				}
			}.addDisposableTo(cell.bag)
		}
		
		return cell
	}
	
	func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
		//print("begin display")
//		dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
//			if let item = rxPlayer.getItemAtPosition(indexPath.row), cell = cell as? QueueTrackCell {
//				//print("Begin display: \((item.streamIdentifier as? CloudAudioResource)?.name ?? "")")
//				cell.bag = DisposeBag()
//				item.loadMetadata().observeOn(MainScheduler.instance).bindNext { meta in
//					if let artwork = meta?.artwork {
//						cell.albumArtImage.image = UIImage(data: artwork)
//					}
//					cell.artistNameLabel.text = meta?.artist
//					cell.trackTimeLabel.text = meta?.duration?.asTimeString
//					cell.trackTitleLabel.text = meta?.title
//				}.addDisposableTo(cell.bag)
//			}
//		}
	}
	
	func tableView(tableView: UITableView, didEndDisplayingCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
		if let cell = cell as? QueueTrackCell {
			//print("end display: \(cell.trackTitleLabel.text)")
			cell.bag = DisposeBag()
		}
	}
	
	func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
		reloadTableView()
	}
}