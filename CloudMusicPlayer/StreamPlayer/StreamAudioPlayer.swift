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

public enum PlayerStatus {
	case Playing
	case Stopped
	case Paused
}

public class StreamAudioPlayer {
	private var bag = DisposeBag()
	private var internalPlayer: AVPlayer?
	public var currentItem = BehaviorSubject<StreamAudioItem?>(value: nil)
	public let status = BehaviorSubject<PlayerStatus>(value: .Stopped)
	internal let utilities: StreamPlayerUtilitiesProtocol
	internal let queue: PlayerQueue
	internal let cacheDispatcher: PlayerCacheDispatcherProtocol
		
	internal init(utilities: StreamPlayerUtilitiesProtocol = StreamPlayerUtilities.instance, queue: PlayerQueue, cacheDispatcher: PlayerCacheDispatcherProtocol) {
		self.utilities = utilities
		self.cacheDispatcher = cacheDispatcher
		self.queue = queue
		
		bindToQueue(queue.queueEvents)
	}
	
	internal convenience init(saveCachedData: Bool, repeatQueue: Bool, httpUtilities: HttpUtilitiesProtocol,
	            playerUtilities: StreamPlayerUtilitiesProtocol) {
		self.init(utilities: playerUtilities, queue: PlayerQueue(repeatQueue: repeatQueue), cacheDispatcher: PlayerCacheDispatcher(saveCachedData: saveCachedData, httpUtilities: httpUtilities))
	}
	
	public convenience init(allowSaveCachedData saveCachedData: Bool = true, repeatQueue: Bool = false, httpUtilities: HttpUtilitiesProtocol = HttpUtilities.instance) {
		self.init(saveCachedData: saveCachedData, repeatQueue: repeatQueue, httpUtilities: httpUtilities, playerUtilities: StreamPlayerUtilities.instance)
	}
	
	internal func bindToQueue(queueEvents: Observable<PlayerQueueEvents>) {
		queue.queueEvents.bindNext { [unowned self] result in
			if case PlayerQueueEvents.CurrentItemChanged(let newItem) = result where newItem != nil {
				self.currentItem.onNext(newItem?.streamItem)
				self.playCurrent()
			}
		}.addDisposableTo(bag)
	}
	
	public func playUrl(url: StreamResourceIdentifier, createNewQueue: Bool = false, customHttpHeaders: [String: String]? = nil, audioFormat: ContentType? = nil) {
		stop()

		guard let cacheItem = cacheDispatcher.createCacheItem(url, customHttpHeaders: customHttpHeaders, targetContentType: url.streamResourceContentType ?? audioFormat) else { return }
		let streamItem = utilities.createStreamAudioItem(self, cacheItem: cacheItem)
		
		if createNewQueue {
			queue.initWithNewItems([streamItem])
			playNext()
		} else {
			queue.current = queue.addLast(streamItem)
		}
	}
	
	public func playNext() {
		queue.toNext()
	}
	
	internal func playCurrent() {
		guard let current = queue.current, player = utilities.createAVPlayer(current.streamItem) else { return }
		internalPlayer = player
		internalPlayer?.rx_observe(AVPlayerItemStatus.self, "status").subscribeNext { [weak self] status in
			if let strong = self {
				print("player status: \(status?.rawValue)")
				if status == .ReadyToPlay {
					strong.internalPlayer?.play()
					strong.status.onNext(.Playing)
				}
			}
			}.addDisposableTo(self.bag)
	}
	
	public func pause() {
		internalPlayer?.rate = 0.0
		status.onNext(.Paused)
	}
	
	public func resume() {
		internalPlayer?.rate = 1.0
		status.onNext(.Playing)
	}

	public func stop() {
		internalPlayer?.replaceCurrentItemWithPlayerItem(nil)
		internalPlayer = nil
		status.onNext(.Stopped)
	}
}