//
//  MusicPlayerController.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 07.03.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import AVFoundation

class MusicPlayerController: UIViewController {
	@IBOutlet weak var fullTimeLabel: UILabel!
	@IBOutlet weak var progressView: UIProgressView!
	@IBOutlet weak var currentTimeLabel: UILabel!
	@IBOutlet weak var image: UIImageView!
	@IBOutlet weak var forwardButton: UIBarButtonItem!
	@IBOutlet weak var playButton: UIBarButtonItem!
	@IBOutlet weak var rewindButton: UIBarButtonItem!
	
	@IBOutlet weak var albumLabel: UILabel!
	@IBOutlet weak var trackLabel: UILabel!
	@IBOutlet weak var artistLabel: UILabel!
	
	@IBOutlet weak var toolbar: UIToolbar!
	var bag: DisposeBag = DisposeBag()
	let reactivePauseButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Pause, target: nil, action: nil)
	let reactivePlayButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Play, target: nil, action: nil)
	
	var disposables = [Disposable]()
	
	override func viewDidLoad() {
		bind()
		
//		reactivePlayButton.rx_tap.bindNext {
//			guard let state = streamPlayer.getCurrentState() else { return }
//			switch state {
//			case .Playing: streamPlayer.pause()
//			case .Paused: streamPlayer.resume()
//			default: break
//			}
//		}.addDisposableTo(bag)
//		
//		reactivePauseButton.rx_tap.bindNext {
//			guard let state = streamPlayer.getCurrentState() else { return }
//			switch state {
//			case .Playing: streamPlayer.pause()
//			case .Paused: streamPlayer.resume()
//			default: break
//			}
//		}.addDisposableTo(bag)
		
//		streamPlayer.currentItem.flatMapLatest { e -> Observable<(metadata: AudioItemMetadata?, duration: String?)?> in
//			return Observable.just((metadata: e?.metadata, duration: e?.durationString))
//			}.asDriver(onErrorJustReturn: nil).driveNext { [unowned self] result in
//				self.trackLabel.text = result?.metadata?.title
//				self.artistLabel.text = result?.metadata?.artist
//				self.albumLabel.text = result?.metadata?.album
//				self.fullTimeLabel.text = result?.duration
//				if let artwork = result?.metadata?.artwork {
//					self.image.image = UIImage(data: artwork)
//				}
//			}.addDisposableTo(bag)
//		
//		//streamPlayer.currentItem.flatMapLatest { e -> Observable<CMTime> in return e?.currentTime ?? Observable.just(CMTimeMake(0, 1)) }
//		// .map { e in return e.asString }.asDriver(onErrorJustReturn: "0: 00").drive(currentTimeLabel.rx_text).addDisposableTo(bag)
//		
//		streamPlayer.currentItem.flatMapLatest { e -> Observable<(currentTime: CMTime, duration: CMTime?)> in
//			return e?.currentTime ?? Observable.just((CMTimeMake(0, 1), nil)) }
//		 .asDriver(onErrorJustReturn: (CMTimeMake(0, 1), nil)).driveNext { [unowned self] e in
//			self.currentTimeLabel.text = e.currentTime.asString
//			guard let sec = e.currentTime.safeSeconds, duration = e.duration?.safeSeconds else { return }
//			self.progressView.progress = Float(sec / duration)
//		}.addDisposableTo(bag)
		
		//streamPlayer.currentItem.bindNext { e in print(e?.cacheItem.resourceIdentifier.streamResourceUid)}.dispose()
		
//		streamPlayer.playerState.asDriver(onErrorJustReturn: .Stopped).driveNext { [unowned self] e in
//			var newButton: UIBarButtonItem?
//			switch e {
//			case .Paused: newButton = self.reactivePlayButton
//			case .Playing: newButton = self.reactivePauseButton
//			default: break
//			}
//			
//			if let newButton = newButton, index = self.toolbar.items?.indexOf(self.playButton) {
//				self.toolbar.items?.removeAtIndex(index)
//				self.toolbar.items?.insert(newButton, atIndex: index)
//				self.playButton = newButton
//			}
//		}.addDisposableTo(bag)
		
//		rxPlayer.currentItemMetadata.asDriver(onErrorJustReturn: nil).driveNext { [weak self] meta in
//			guard let meta = meta else { return }
//			
//			self?.trackLabel.text = meta.title
//			self?.artistLabel.text = meta.artist
//			self?.albumLabel.text = meta.album
//			if let artwork = meta.artwork {
//				self?.image.image = UIImage(data: artwork)
//			}
//		}.addDisposableTo(bag)
//		
//		rxPlayer.currentItemDuration.asDriver(onErrorJustReturn: nil).driveNext { [weak self] duration in
//			self?.fullTimeLabel.text = duration?.asString
//		}.addDisposableTo(bag)
		
		//rxPlayer.current?.loadMetadata().asDriver(onErrorJustReturn: nil).driveNext { [weak self] meta in
			//guard let meta = meta else { return }
			
			//self?.trackLabel.text = meta.title
			//self?.artistLabel.text = meta.artist
			//self?.albumLabel.text = meta.album
			//if let artwork = meta.artwork {
			//	self?.image.image = UIImage(data: artwork)
			//}
		//}.addDisposableTo(bag)
	}
	
	func bind() {
		dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {			
//			rxPlayer.currentItem.flatMapLatest { e -> Observable<MediaItemMetadataType?> in
//				//return e?.loadMetadata() ?? Observable.just(nil)
//				guard let e = e else { return Observable.just(nil) }
//				return rxPlayer.loadMetadata(e.streamIdentifier)
//				}.observeOn(MainScheduler.instance).bindNext { [weak self] meta in
//					print("new metadata")
//					guard let meta = meta else { return }
//					
//					self?.trackLabel.text = meta.title
//					self?.artistLabel.text = meta.artist
//					self?.albumLabel.text = meta.album
//					if let artwork = meta.artwork {
//						self?.image.image = UIImage(data: artwork)
//					}
//					self?.fullTimeLabel.text = meta.duration?.asTimeString
//			}.addDisposableTo(self.bag)
			
			MainModel.sharedInstance.player.currentItemTime.observeOn(MainScheduler.instance).bindNext { [weak self] time in
				guard let time = time else { self?.currentTimeLabel.text = "0: 00"; return }
				
				self?.currentTimeLabel.text = time.currentTime?.asString
				if let currentSec = time.currentTime?.safeSeconds, fullSec = time.duration?.safeSeconds {
					self?.progressView.progress = Float(currentSec / fullSec)
				} else {
					self?.progressView.progress = 0
				}
			}.addDisposableTo(self.bag)
			
			self.forwardButton.rx_tap.bindNext {
				MainModel.sharedInstance.player.toNext()
			}.addDisposableTo(self.bag)
		}
	}
	
	deinit {
		print("MusicPlayerController deinit")
	}
}
