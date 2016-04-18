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
	
	override func viewDidLoad() {
		automaticallyAdjustsScrollViewInsets = false
		playPauseButton.setTitle(rxPlayer.playing == true ? "Pause" : "Play", forState: .Normal)
		
		forwardButton.rx_tap.bindNext {
			rxPlayer.toNext()
			}.addDisposableTo(bag)
		
		backButton.rx_tap.bindNext {
			rxPlayer.toPrevious()
			}.addDisposableTo(bag)
		
		playPauseButton.rx_tap.bindNext { [unowned self] in
			if rxPlayer.playing {
				rxPlayer.pause()
				self.playPauseButton.setTitle("Play", forState: .Normal)
			} else {
				rxPlayer.resume(true)
				self.playPauseButton.setTitle("Pause", forState: .Normal)
			}
		}.addDisposableTo(bag)
		
		dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
			rxPlayer.currentItem.flatMapLatest { e -> Observable<AudioItemMetadata?> in return e?.loadMetadata() ?? Observable.just(nil) }
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
			cell.artistNameLabel.text = ""
			cell.trackTimeLabel.text = ""
			cell.trackTitleLabel.text = ""//(item.streamIdentifier as? CloudAudioResource)?.name ?? ""
			
			rxPlayer.currentItem.observeOn(MainScheduler.instance).bindNext { newCurrent in
				if item.streamIdentifier.streamResourceUid == newCurrent?.streamIdentifier.streamResourceUid {
					cell.backgroundColor = UIColor(red: 204/255, green: 255/255, blue: 253/255, alpha: 1)
				} else {
					cell.backgroundColor = UIColor.whiteColor()
				}
			}.addDisposableTo(self.bag)
			
			dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
				item.loadMetadata().observeOn(MainScheduler.instance).bindNext { meta in
					if let artwork = meta?.artwork {
						cell.albumArtImage.image = UIImage(data: artwork)
					}
					cell.artistNameLabel.text = meta?.artist
					cell.trackTimeLabel.text = meta?.duration?.asTimeString
					cell.trackTitleLabel.text = meta?.title
					
					}.addDisposableTo(self.bag)
			}
		}
		
		return cell
	}
}