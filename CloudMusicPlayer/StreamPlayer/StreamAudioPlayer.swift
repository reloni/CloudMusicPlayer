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
	public var currentItem = Variable<StreamAudioItem?>(nil)
	public let status = BehaviorSubject<PlayerStatus>(value: .Stopped)
	internal let utilities: StreamPlayerUtilitiesProtocol
	internal let queue = PlayerQueue()
	internal let cache: PlayerCacheDispatcher
		
	init(saveCachedData: Bool = true, httpClient: HttpClientProtocol = HttpClient.instance,
	     utilities: StreamPlayerUtilitiesProtocol = StreamPlayerUtilities.instance) {
		self.utilities = utilities
		cache = PlayerCacheDispatcher(saveCachedData: saveCachedData, httpUtilities: httpClient.httpUtilities)
	}
	
	public func playUrl(url: StreamResourceIdentifier, customHttpHeaders: [String: String]? = nil, audioFormat: ContentType? = nil) {
		stop()

		guard let cacheItem = cache.createCacheItem(url, customHttpHeaders: customHttpHeaders, targetContentType: url.streamResourceContentType ?? audioFormat) else { return }
		let streamItem = utilities.createStreamAudioItem(self, cacheItem: cacheItem)
		
		queue.initWithNewItems([streamItem])
		playNext()
	}
	
	public func playNext() {
		guard let next = queue.toNext(), player = utilities.createAVPlayer(next.streamItem) else { return }
		internalPlayer = player
		currentItem.value = next.streamItem
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