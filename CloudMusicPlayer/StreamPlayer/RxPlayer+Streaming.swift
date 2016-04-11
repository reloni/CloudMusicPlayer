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
	internal func streamContent(player: RxPlayer, contentType: ContentType? = nil, utilities: StreamPlayerUtilitiesProtocol = StreamPlayerUtilities.instance) ->
		Observable<AssetLoadResult> {
			
			let asset = utilities.createavUrlAsset(NSURL(string: "fake://domain.com")!)
			let observer = AVAssetResourceLoaderEventsObserver()
			asset.getResourceLoader().setDelegate(observer, queue: dispatch_get_global_queue(QOS_CLASS_UTILITY, 0))
			let playerItem = utilities.createavPlayerItem(asset)
			
			let scheduler = SerialDispatchQueueScheduler(globalConcurrentQueueQOS: DispatchQueueSchedulerQOS.Utility)
			
			let task = self.observeOn(scheduler).loadWithAsset(
				assetEvents: observer.loaderEvents.observeOn(scheduler),
				targetAudioFormat: contentType)
			
			player.internalPlayer.play(playerItem, asset: asset, observer: observer)
			
			return task
	}
}

extension Observable where Element : PlayerEventType {
	internal func streamContent(playerUtilities: StreamPlayerUtilitiesProtocol = StreamPlayerUtilities.instance,
	                          downloadManager: DownloadManagerType = DownloadManager(
		saveData: false, fileStorage: LocalStorage(), httpUtilities: HttpUtilities.instance)) -> Observable<AssetLoadResult> {
		
		return self.filter { e in if case .PreparingToPlay = e as! PlayerEvents { return true } else { return false } }
			.flatMap { e -> Observable<AssetLoadResult> in
				
				return Observable<AssetLoadResult>.create { observer in
					guard case let .PreparingToPlay(item) = e as! PlayerEvents else { observer.onCompleted(); return NopDisposable.instance }
					
					print("preparing \(item.streamIdentifier.streamResourceUid)")
					
					let disposable = downloadManager.getUrlDownloadTask(item.streamIdentifier)
						.streamContent(item.player, contentType: item.streamIdentifier.streamResourceContentType, utilities: playerUtilities).bindNext { e in
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
	
	public func streamContent(saveCachedData: Bool = false) -> Observable<AssetLoadResult> {
		return streamContent(StreamPlayerUtilities.instance, downloadManager:
			DownloadManager(saveData: saveCachedData, fileStorage: LocalStorage(), httpUtilities: HttpUtilities.instance))
	}
}