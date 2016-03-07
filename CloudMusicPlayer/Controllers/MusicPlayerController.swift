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
	let bag = DisposeBag()
	
	override func viewDidLoad() {
		streamPlayer.currentItem.asDriver().driveNext { [unowned self] item in
			guard let item = item else {
				return
			}
			
			self.trackLabel.text = item.title
			self.artistLabel.text = item.artist
			self.albumLabel.text = item.album
			self.fullTimeLabel.text = item.durationString
			if let artwork = item.artwork {
				self.image.image = artwork
			}
			}.addDisposableTo(bag)
		
		streamPlayer.currentItem.value?.currentTime.asDriver(onErrorJustReturn: CMTime()).driveNext { [unowned self] time in
			self.currentTimeLabel.text = time.asString
			guard let dur = streamPlayer.currentItem.value?.duration?.seconds else {
				return
			}
			
			self.progressView.progress = Float(time.seconds / dur)
			}.addDisposableTo(bag)
		
		streamPlayer.status.asDriver().driveNext { [unowned self] status in
			var newButton: UIBarButtonItem?
			switch status {
					case .Paused: newButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Play, target: self, action: "mth")
					case .Playing: newButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Pause, target: self, action: "mth")
					default: break
				}
			
			if let newButton = newButton, index = self.toolbar.items?.indexOf(self.playButton) {
				self.toolbar.items?.removeAtIndex(index)
				self.toolbar.items?.insert(newButton, atIndex: index)
				self.playButton = newButton
				
				self.playButton.rx_tap.bindNext { _ in
					if streamPlayer.status.value == .Playing {
						streamPlayer.pause()
					} else if streamPlayer.status.value == .Paused {
						streamPlayer.resume()
					}
					}.addDisposableTo(self.bag)
				
			}
			}.addDisposableTo(bag)
	}
	
	deinit {
		print("MusicPlayerController deinit")
	}
}
