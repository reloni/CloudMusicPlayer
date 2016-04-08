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
		reactivePlayButton.rx_tap.bindNext {
			guard let state = streamPlayer.getCurrentState() else { return }
			switch state {
			case .Playing: streamPlayer.pause()
			case .Paused: streamPlayer.resume()
			default: break
			}
		}.addDisposableTo(bag)
		
		reactivePauseButton.rx_tap.bindNext {
			guard let state = streamPlayer.getCurrentState() else { return }
			switch state {
			case .Playing: streamPlayer.pause()
			case .Paused: streamPlayer.resume()
			default: break
			}
		}.addDisposableTo(bag)
		
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
		
		streamPlayer.playerState.asDriver(onErrorJustReturn: .Stopped).driveNext { [unowned self] e in
			var newButton: UIBarButtonItem?
			switch e {
			case .Paused: newButton = self.reactivePlayButton
			case .Playing: newButton = self.reactivePauseButton
			default: break
			}
			
			if let newButton = newButton, index = self.toolbar.items?.indexOf(self.playButton) {
				self.toolbar.items?.removeAtIndex(index)
				self.toolbar.items?.insert(newButton, atIndex: index)
				self.playButton = newButton
			}
		}.addDisposableTo(bag)
	}
	
	deinit {
		print("MusicPlayerController deinit")
	}
}
