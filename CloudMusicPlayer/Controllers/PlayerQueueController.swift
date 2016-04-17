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
	
	override func viewDidLoad() {
		automaticallyAdjustsScrollViewInsets = false
	}
}

extension PlayerQueueController : UITableViewDelegate {
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {


	}
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return rxPlayer.count
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("QueueTrack", forIndexPath: indexPath) as! QueueTrackCell
	
		
		if let item = rxPlayer.getItemAtPosition(indexPath.row) {
			cell.albumArtImage.image = nil
			cell.artistNameLabel.text = ""
			cell.trackTimeLabel.text = ""
			cell.trackTitleLabel.text = ""
			
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