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
	var bag: DisposeBag! = DisposeBag()
	
	override func viewDidLoad() {
		bag = DisposeBag()
		
		streamPlayer.currentItem.flatMapLatest { e -> Observable<(metadata: AudioItemMetadata?, duration: String?)?> in
			return Observable.just((metadata: e?.metadata, duration: e?.durationString))
			}.asDriver(onErrorJustReturn: nil).driveNext { result in
				self.trackLabel.text = result?.metadata?.title
				self.artistLabel.text = result?.metadata?.artist
				self.albumLabel.text = result?.metadata?.album
				self.fullTimeLabel.text = result?.duration
				if let artwork = result?.metadata?.artwork {
					self.image.image = UIImage(data: artwork)
				}
			}.addDisposableTo(bag)
		
		streamPlayer.currentItem.flatMapLatest { e -> Observable<CMTime> in return e?.currentTime ?? Observable.just(CMTimeMake(0, 1)) }
			.map { e in return e.asString }.asDriver(onErrorJustReturn: "0:00").drive(currentTimeLabel.rx_text).addDisposableTo(bag)
		
//		streamPlayer.currentItem.asDriver(onErrorJustReturn: nil).driveNext { [unowned self] item in
//			guard let item = item else {
//				return
//			}
//			
//			self.trackLabel.text = item.metadata?.title
//			self.artistLabel.text = item.metadata?.artist
//			self.albumLabel.text = item.metadata?.album
//			self.fullTimeLabel.text = item.durationString
//			if let artwork = item.metadata?.artwork {
//				self.image.image = UIImage(data: artwork)
//			}
//			
//			item.currentTime.asDriver(onErrorJustReturn: CMTime()).driveNext { [unowned self] time in
//				self.currentTimeLabel.text = time.asString
//				guard let dur = item.duration?.seconds else {
//					return
//				}
//				
//				self.progressView.progress = Float(time.seconds / dur)
//			}.addDisposableTo(self.bag)
//			
//		}.addDisposableTo(bag)
		
		
//		streamPlayer.playerState.asDriver(onErrorJustReturn: .Stopped).driveNext { [unowned self] status in
//			var newButton: UIBarButtonItem?
//			switch status {
//					case .Paused: newButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Play, target: nil, action: nil)
//					case .Playing: newButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Pause, target: nil, action: nil)
//					default: break
//				}
//			
//			if let newButton = newButton, index = self.toolbar.items?.indexOf(self.playButton) {
//				self.toolbar.items?.removeAtIndex(index)
//				self.toolbar.items?.insert(newButton, atIndex: index)
//				self.playButton = newButton
//				
//				self.playButton.rx_tap.bindNext {
//					guard let state = streamPlayer.getCurrentState() else { return }
//					switch state {
//					case .Playing: streamPlayer.pause()
//					case .Paused: streamPlayer.resume()
//					default: break
//					}
//				}.addDisposableTo(self.bag)
//				
//			}
//		}.addDisposableTo(bag)
	}
	
	deinit {
		bag = nil
		print("MusicPlayerController deinit")
	}
}
