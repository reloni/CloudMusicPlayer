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

public enum PlayerState {
	case Playing//(StreamAudioItem)
	case Stopped
	case Paused
	case Preparing//(StreamAudioItem)
}

public class StreamAudioPlayer {
	private var bag = DisposeBag()
	private var internalPlayer: AVPlayerProtocol?
	//internal var currentItemSubject = BehaviorSubject<StreamAudioItem?>(value: nil)
	internal let stateSubject = BehaviorSubject<PlayerState>(value: .Stopped)
	internal let utilities: StreamPlayerUtilitiesProtocol
	internal let queue: PlayerQueue
	internal let cacheDispatcher: PlayerCacheDispatcherProtocol
	internal var observer: AVAssetResourceLoaderEventsObserver!
	var asset: AVURLAssetProtocol!
	var playerItem: AVPlayerItemProtocol!
	var disp: Disposable?
	
	public var playerState: Observable<PlayerState> {
		return self.stateSubject.shareReplay(1)
	}
	
	//public var currentItem: Observable<StreamAudioItem?>  {
	//	return self.currentItemSubject.shareReplay(1)
	//}
		
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
				//self.currentItemSubject.onNext(newItem?.streamIdentifier.streamResourceUid)
				self.playCurrent()
			}
		}.addDisposableTo(bag)
	}
	
	public func playUrl(url: StreamResourceIdentifier, createNewQueue: Bool = false, customHttpHeaders: [String: String]? = nil, audioFormat: ContentType? = nil) {
		stop()

		//guard let cacheItem = cacheDispatcher.createCacheItem(url, customHttpHeaders: customHttpHeaders, targetContentType: url.streamResourceContentType ?? audioFormat) else { return }
		//let streamIdentifier.streamResourceUid = utilities.createStreamAudioItem(self, cacheItem: cacheItem)
		
		if createNewQueue {
			queue.initWithNewItems([url])
			playNext()
		} else {
			queue.current = queue.addLast(url)
		}
	}
	
	public func playNext() {
		queue.toNext()
	}
	
//	internal lazy var urlAsset: AVURLAssetProtocol? = { [unowned self] in
//		return self.player.utilities.createavUrlAsset(self.fakeUrl)
//		}()
//	
//	public lazy var playerItem: AVPlayerItemProtocol? = { [unowned self] in
//		guard let asset = self.urlAsset else { return nil }
//		asset.getResourceLoader().setDelegate(self.observer, queue: dispatch_get_global_queue(QOS_CLASS_UTILITY, 0))
//		return self.player.utilities.createavPlayerItem(asset)
//		}()
	
	internal func playCurrent() {
		guard let current = queue.current else { return }
		
		disp?.dispose()
		
		//stateSubject.onNext(.Preparing(current.streamIdentifier.streamResourceUid))
		observer = AVAssetResourceLoaderEventsObserver()
		asset = utilities.createavUrlAsset(NSURL(string: "fake://domain.com")!)
		
		asset.getResourceLoader().setDelegate(observer, queue: dispatch_get_global_queue(QOS_CLASS_UTILITY, 0))
		playerItem = utilities.createavPlayerItem(asset)
		
		let scheduler = SerialDispatchQueueScheduler(globalConcurrentQueueQOS: DispatchQueueSchedulerQOS.Utility)
		disp = cacheDispatcher.createStreamTask(current.streamIdentifier, targetContentType: ContentType.mp3)?.observeOn(scheduler)
			.loadWithAsset(assetEvents: observer.loaderEvents.observeOn(scheduler), targetAudioFormat: ContentType.mp3).subscribe()
		
		internalPlayer = AVPlayer(playerItem: playerItem as! AVPlayerItem) as AVPlayerProtocol
		
		stateSubject.onNext(.Preparing)
		//internalPlayer = player
		internalPlayer?.internalItemStatus.subscribeNext { [weak self] status in
			if let strong = self {
				print("player status: \(status?.rawValue)")
				if status == .ReadyToPlay {
					strong.internalPlayer?.play()
					//guard let currentStreamItem = strong.queue.current?.streamIdentifier.streamResourceUid else { return }
					//strong.stateSubject.onNext(.Playing(currentStreamItem))
					strong.stateSubject.onNext(.Playing)
				}
			}
		}.addDisposableTo(self.bag)
	}
	
	public func pause() {
		internalPlayer?.rate = 0.0
		stateSubject.onNext(.Paused)
	}
	
	public func resume() {
		//guard let currentStreamItem = queue.current?.streamIdentifier.streamResourceUid else { return }
		internalPlayer?.rate = 1.0
		//stateSubject.onNext(.Playing(currentStreamItem))
		stateSubject.onNext(.Playing)
	}

	public func stop() {
		internalPlayer?.replaceCurrentItemWithPlayerItem(nil)
		internalPlayer = nil
		stateSubject.onNext(.Stopped)
	}
	
	public func getCurrentState() -> PlayerState? {
		return try? stateSubject.value()
	}
}