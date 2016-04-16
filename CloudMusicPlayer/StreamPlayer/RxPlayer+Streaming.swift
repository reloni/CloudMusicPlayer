//
//  RxPlayer+Streaming.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 08.04.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import RxSwift

public typealias AssetLoadResult =
	(receivedResponse: NSHTTPURLResponseProtocol?, utiType: String?, resultRequestCollection: [Int: AVAssetResourceLoadingRequestProtocol])

extension Observable where Element : StreamTaskEventsProtocol {
	internal func streamContent(player: RxPlayer, contentType: ContentType? = nil) ->
		Observable<AssetLoadResult> {
			
			let asset = player.streamPlayerUtilities.createavUrlAsset(NSURL(string: "fake://domain.com")!)
			let observer = AVAssetResourceLoaderEventsObserver()
			asset.getResourceLoader().setDelegate(observer, queue: dispatch_get_global_queue(QOS_CLASS_UTILITY, 0))
			let playerItem = player.streamPlayerUtilities.createavPlayerItem(asset)
			
			let scheduler = SerialDispatchQueueScheduler(globalConcurrentQueueQOS: DispatchQueueSchedulerQOS.Utility)
			
			let task = self.observeOn(scheduler).loadWithAsset(
				assetEvents: observer.loaderEvents.observeOn(scheduler),
				targetAudioFormat: contentType)
			
			player.internalPlayer.play(playerItem, asset: asset, observer: observer, loadMetadata: true)
			
			return task
	}
}

extension Observable where Element : PlayerEventType {
	internal func streamContent() -> Observable<AssetLoadResult> {
		
		return self.filter { e in if case .PreparingToPlay = e as! PlayerEvents { return true } else { return false } }
			.flatMap { e -> Observable<AssetLoadResult> in
				
				return Observable<AssetLoadResult>.create { observer in
					guard case let .PreparingToPlay(item) = e as! PlayerEvents else { observer.onCompleted(); return NopDisposable.instance }
					
					print("preparing \(item.streamIdentifier.streamResourceUid)")
					
					let disposable = item.player.downloadManager.createDownloadObservable(item.streamIdentifier, checkInPendingTasks: true)
						.streamContent(item.player, contentType: item.streamIdentifier.streamResourceContentType).bindNext { e in
							observer.onNext(e)
							observer.onCompleted()
					}
					
					return AnonymousDisposable {
						print("Dispatch dispoding")
						disposable.dispose()
					}
				}
		}
	}
	
//	public func streamContent(saveCachedData: Bool = false) -> Observable<AssetLoadResult> {
//		if !DownloadManager.isInitialized {
//			DownloadManager.initWithInstance(DownloadManager(saveData: saveCachedData,
//				fileStorage: LocalNsUserDefaultsStorage(loadData: saveCachedData), httpUtilities: HttpUtilities.instance))
//		}
//		
//		return streamContent(StreamPlayerUtilities.instance, downloadManager: DownloadManager.instance)
//	}
}