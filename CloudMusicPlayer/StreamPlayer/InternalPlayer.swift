//
//  InternalPlayer.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 29.04.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import RxSwift
import AVFoundation

public typealias AssetLoadResult =
	Result<(receivedResponse: NSHTTPURLResponseProtocol?, utiType: String?, resultRequestCollection: [Int: AVAssetResourceLoadingRequestProtocol])>

public protocol InternalPlayerType {
	func play(resource: StreamResourceIdentifier) -> Observable<AssetLoadResult>
	func stop()
	func pause()
	func resume()
	var currentTime: Observable<(currentTime: CMTime?, duration: CMTime?)?> { get }
	var nativePlayer: AVPlayerProtocol? { get }
}

public class InternalPlayer {
	public var nativePlayer: AVPlayerProtocol?
	var observer: AVAssetResourceLoaderEventsObserverProtocol?
	let eventsCallback: (PlayerEvents) -> ()
	
	var currentTimeDisposable: Disposable?
	var bag: DisposeBag
	var asset: AVURLAssetProtocol?
	var playerItem: AVPlayerItemProtocol?
	var hostPlayer: RxPlayer
	
	deinit {
		stop()
	}
	
	internal init(hostPlayer: RxPlayer, eventsCallback: (PlayerEvents) -> ()) {
		self.hostPlayer = hostPlayer
		self.eventsCallback = eventsCallback
		bag = DisposeBag()
	}
}

extension InternalPlayer : InternalPlayerType {
	public var currentTime: Observable<(currentTime: CMTime?, duration: CMTime?)?> {
		return Observable.create { [weak self] observer in
			guard let object = self else {
				observer.onNext(nil); observer.onCompleted(); return NopDisposable.instance
			}
			
			return Observable<Int>.interval(1, scheduler: SerialDispatchQueueScheduler(globalConcurrentQueueQOS: DispatchQueueSchedulerQOS.Utility))
				.bindNext { _ in
					if let playerItem = object.playerItem, asset = object.asset {
						observer.onNext((currentTime: playerItem.currentTime(), duration: asset.duration))
					} else {
						observer.onNext(nil)
					}
			}
		}
	}
	
	public func play(resource: StreamResourceIdentifier) -> Observable<AssetLoadResult> {
		let asset = hostPlayer.streamPlayerUtilities.createavUrlAsset(NSURL(string: "fake://domain.com")!)
		let observer = AVAssetResourceLoaderEventsObserver()
		asset.getResourceLoader().setDelegate(observer, queue: dispatch_get_global_queue(QOS_CLASS_UTILITY, 0))
		let playerItem = hostPlayer.streamPlayerUtilities.createavPlayerItem(asset)
		
		let downloadTask = hostPlayer.downloadManager.createDownloadObservable(resource, priority: .Normal)
		
		let task = downloadTask.loadWithAsset(
			assetEvents: observer.loaderEvents,
			targetAudioFormat: resource.streamResourceContentType)
		
		play(playerItem, asset: asset, observer: observer)
		
		return task
	}
	
	internal func play(playerItem: AVPlayerItemProtocol, asset: AVURLAssetProtocol, observer: AVAssetResourceLoaderEventsObserverProtocol) {
		stop()
		
		self.asset = asset
		self.playerItem = playerItem
		self.observer = observer
		self.nativePlayer = AVPlayer(playerItem: playerItem as! AVPlayerItem)
		
		nativePlayer?.internalItemStatus.bindNext { [weak self] status in
			print("player status: \(status?.rawValue)")
			if status == AVPlayerItemStatus.ReadyToPlay {
				self?.nativePlayer?.play()
				self?.eventsCallback(.Started)
				
				if let object = self {
					NSNotificationCenter.defaultCenter().addObserver(object, selector:
						#selector(object.finishPlayingItem), name: AVPlayerItemDidPlayToEndTimeNotification, object: object.playerItem as? AVPlayerItem)
				}
			}
			}.addDisposableTo(bag)
	}
	
	func flush() {
		NSNotificationCenter.defaultCenter().removeObserver(self, name: AVPlayerItemDidPlayToEndTimeNotification, object: playerItem as? AVPlayerItem)
		nativePlayer?.replaceCurrentItemWithPlayerItem(nil)
		nativePlayer = nil
		asset = nil
		playerItem = nil
		bag = DisposeBag()
		currentTimeDisposable?.dispose()
	}
	
	public func stop() {
		flush()
		eventsCallback(.Stopped)
	}
	
	public func pause() {
		if let nativePlayer = nativePlayer {
			currentTimeDisposable?.dispose()
			nativePlayer.setPlayerRate(0.0)
			eventsCallback(.Paused)
		}
	}
	
	public func resume() {
		if let nativePlayer = nativePlayer {
			nativePlayer.setPlayerRate(1.0)
			eventsCallback(.Resumed)
		}
	}
	
	@objc func finishPlayingItem() {
		flush()
		eventsCallback(.FinishPlayingCurrentItem)
		hostPlayer.toNext(true)
	}
}