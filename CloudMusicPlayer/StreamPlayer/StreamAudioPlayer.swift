//
//  StreamPlayer.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 01.03.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import AVFoundation
import RxSwift
import RxCocoa

public class StreamAudioPlayer {
	private var bag = DisposeBag()
	public let allowCaching: Bool
	private var internalPlayer: AVPlayer?
	private var currentItem: StreamAudioItem?
	public var customHttpHeaders: [String: String]?
		
	init(allowCaching: Bool = true) {
		self.allowCaching = allowCaching
	}
	
	public func play(url: String) -> StreamAudioItem? {
		stop()
		
		let newAudioItem = StreamAudioItem(player: self, url: url)
		
		guard let playerItem = newAudioItem.playerItem else {
			currentItem = nil
			return nil
		}
		
		currentItem = newAudioItem
		internalPlayer = AVPlayer(playerItem: playerItem)
		
		internalPlayer?.rx_observe(AVPlayerItemStatus.self, "status").subscribeNext { [weak self] status in
			if let strong = self {
				print("player status: \(status?.rawValue)")
				if status == .ReadyToPlay {
					strong.internalPlayer?.play()
				}
			}
			}.addDisposableTo(self.bag)

		
		return currentItem
	}
	
	public func pause() {
		internalPlayer?.rate = 0.0
	}
	
	public func resume() {
		internalPlayer?.rate = 1.0
	}

	public func stop() {
		internalPlayer?.replaceCurrentItemWithPlayerItem(nil)
		internalPlayer = nil
	}
}