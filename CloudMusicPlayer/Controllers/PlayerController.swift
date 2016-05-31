//
//  PlayerController.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 29.05.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import UIKit
import RxSwift

class PlayerController: UIViewController {
	@IBOutlet weak var trackProgressSlider: UISlider!
	@IBOutlet weak var volumeSlider: UISlider!
	@IBOutlet weak var currentTimeLabel: UILabel!
	@IBOutlet weak var fullTimeLabel: UILabel!
	@IBOutlet weak var trackTitleLabel: UILabel!
	@IBOutlet weak var albumAndArtistLabel: UILabel!
	@IBOutlet weak var albumArtImage: UIImageView!
	@IBOutlet weak var revindButton: UIButton!
	@IBOutlet weak var playPauseButton: UIButton!
	@IBOutlet weak var forwardButton: UIButton!
	@IBOutlet weak var shuffleButton: UIButton!
	@IBOutlet weak var repeatButton: UIButton!
	
	var bag = DisposeBag()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		trackProgressSlider.setThumbImage(UIImage(named: "Slider thumb"), forState: .Normal)
		volumeSlider.setThumbImage(UIImage(named: "Slider thumb"), forState: .Normal)
		
		playPauseButton.selected = MainModel.sharedInstance.player.playing
		currentTimeLabel.text = "--:--"
		fullTimeLabel.text = "--:--"
		
		
	}
	
	override func viewWillAppear(animated: Bool) {
		playPauseButton.selected = MainModel.sharedInstance.player.playing
		forwardButton.rx_tap.bindNext {
			MainModel.sharedInstance.player.toNext(true)
			}.addDisposableTo(bag)
		
		revindButton.rx_tap.bindNext {
			MainModel.sharedInstance.player.toPrevious(true)
			}.addDisposableTo(bag)
		
		playPauseButton.rx_tap.bindNext {
			if MainModel.sharedInstance.player.playing {
				MainModel.sharedInstance.player.pause()
			} else {
				MainModel.sharedInstance.player.resume(true)
			}
			}.addDisposableTo(bag)
		
		MainModel.sharedInstance.player.currentItem.flatMapLatest { e -> Observable<Result<MediaItemMetadataType?>> in
			guard let e = e else { return Observable.empty() }
			return MainModel.sharedInstance.player.loadMetadata(e.streamIdentifier)
			//return e?.loadMetadata() ?? Observable.just(nil)
			}.map { result -> MediaItemMetadataType? in
				if case Result.success(let box) = result { return box.value } else { return nil }
			}.observeOn(MainScheduler.instance).bindNext { [weak self] meta in
				guard let object = self, meta = meta else { return }
				object.fullTimeLabel.text = meta.duration?.asTimeString
				object.trackTitleLabel.text = meta.title
				if let art = meta.artwork {
					object.albumArtImage.image = UIImage(data: art)
				}
				guard let artist = meta.artist, album = meta.album else { return }
				object.albumAndArtistLabel.text = "\(album) - \(artist)"
				
		}.addDisposableTo(bag)
			//}.observeOn(MainScheduler.instance).bindTo(self.fullTimeLabel.rx_text).addDisposableTo(self.bag)
		
		MainModel.sharedInstance.player.currentItemTime.observeOn(MainScheduler.instance).bindNext { [weak self] time in
			guard let time = time else { self?.currentTimeLabel.text = "--:--"; return }
			
			//dispatch_async(dispatch_get_main_queue()) { [weak self] in
				self?.currentTimeLabel.text = time.currentTime?.asString
				if let currentSec = time.currentTime?.safeSeconds, fullSec = time.duration?.safeSeconds {
					self?.trackProgressSlider.setValue(Float(currentSec / fullSec), animated: true)
				} else {
					self?.trackProgressSlider.value = 0
				}
			//}
		}.addDisposableTo(self.bag)
		
		MainModel.sharedInstance.player.playerEvents.observeOn(MainScheduler.instance).bindNext { [weak self] e in
			if case PlayerEvents.Started = e {
				self?.playPauseButton.selected = true
			} else if case PlayerEvents.Paused = e {
				self?.playPauseButton.selected = false
			} else if case PlayerEvents.Stopped = e {
				self?.playPauseButton.selected = false
			} else if case PlayerEvents.Resumed = e {
				self?.playPauseButton.selected = true
			}
			}.addDisposableTo(bag)
	}
	
	override func viewWillDisappear(animated: Bool) {
		bag = DisposeBag()
	}
}