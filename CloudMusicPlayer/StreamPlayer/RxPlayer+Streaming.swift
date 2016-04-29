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

//extension Observable where Element : StreamTaskEventsProtocol {
//	internal func streamContent(player: RxPlayer, contentType: ContentType? = nil) ->
//		Observable<AssetLoadResult> {
//			
//			let asset = player.streamPlayerUtilities.createavUrlAsset(NSURL(string: "fake://domain.com")!)
//			let observer = AVAssetResourceLoaderEventsObserver()
//			asset.getResourceLoader().setDelegate(observer, queue: dispatch_get_global_queue(QOS_CLASS_UTILITY, 0))
//			let playerItem = player.streamPlayerUtilities.createavPlayerItem(asset)
//			
//			let task = self.loadWithAsset(
//				assetEvents: observer.loaderEvents,
//				targetAudioFormat: contentType)
//			
//			player.internalPlayer.play(playerItem, asset: asset, observer: observer, hostPlayer: player)
//			
//			return task
//	}
//}
//
//extension Observable where Element : PlayerEventType {
//	internal func streamContent_old() -> Observable<AssetLoadResult> {
//		
//		return self.filter { e in if case .PreparingToPlay = e as! PlayerEvents { return true } else { return false } }
//			.flatMap { e -> Observable<AssetLoadResult> in
//				
//				return Observable<AssetLoadResult>.create { observer in
//					guard case let .PreparingToPlay(item) = e as! PlayerEvents else { observer.onCompleted(); return NopDisposable.instance }
//					
//					let disposable = item.player.downloadManager.createDownloadObservable(item.streamIdentifier, priority: .Normal)
//						.streamContent(item.player, contentType: item.streamIdentifier.streamResourceContentType).doOnError { observer.onError($0) }.bindNext { e in
//							observer.onNext(e)
//							observer.onCompleted()
//					}
//					
//					return AnonymousDisposable {
//						disposable.dispose()
//					}
//				}
//		}
//	}
//	
//	internal func streamContent() -> Observable<AssetLoadResult> {
//		return Observable<AssetLoadResult>.create { observer in
//			var currentStreamData: Disposable?
//			let disposable = self.filter { e in if case .PreparingToPlay = e as! PlayerEvents { return true } else { return false } }.doOnNext { e in
//				guard case let .PreparingToPlay(item) = e as! PlayerEvents else { return }
//				
//				print("start streaming")
//				currentStreamData?.dispose()
//				currentStreamData = item.player.downloadManager.createDownloadObservable(item.streamIdentifier, priority: .Normal)
//					.streamContent(item.player, contentType: item.streamIdentifier.streamResourceContentType).doOnNext { observer.onNext($0) }.subscribe()
//				}.subscribe()
//			
//			return AnonymousDisposable {
//				print("stream content disposed")
//				disposable.dispose()
//				currentStreamData?.dispose()
//			}
//		}
//	}
//}