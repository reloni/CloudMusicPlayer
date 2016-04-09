//
//  RxPlayer+Streaming.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 08.04.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import RxSwift

extension Observable where Element : StreamTaskEventsProtocol {
	public func streamContent(contentType: ContentType? = nil, utilities: StreamPlayerUtilitiesProtocol = StreamPlayerUtilities.instance) ->
		Observable<(receivedResponse: NSHTTPURLResponseProtocol?, utiType: String?, resultRequestCollection: [Int: AVAssetResourceLoadingRequestProtocol])> {
			
			let asset = utilities.createavUrlAsset(NSURL(string: "fake://domain.com")!)
			let observer = AVAssetResourceLoaderEventsObserver()
			asset.getResourceLoader().setDelegate(observer, queue: dispatch_get_global_queue(QOS_CLASS_UTILITY, 0))
			let playerItem = utilities.createavPlayerItem(asset)
			
			let scheduler = SerialDispatchQueueScheduler(globalConcurrentQueueQOS: DispatchQueueSchedulerQOS.Utility)
			
			let task = self.observeOn(scheduler).loadWithAsset(
				assetEvents: observer.loaderEvents.observeOn(scheduler),
				targetAudioFormat: contentType)
			
			GlobalPlayerHolder.instance.initialize(playerItem, asset: asset, observer: observer)
			
			return task
	}
}

public typealias DispatchResult =
	(receivedResponse: NSHTTPURLResponseProtocol?, utiType: String?, resultRequestCollection: [Int: AVAssetResourceLoadingRequestProtocol])

extension Observable where Element : PlayerEventType {
	public func streamContent(saveCachedData: Bool = false, httpUtilities: HttpUtilitiesProtocol = HttpUtilities.instance,
	                     fileStorage: LocalStorageProtocol = LocalStorage(),
	                     playerUtilities: StreamPlayerUtilitiesProtocol = StreamPlayerUtilities.instance) -> Observable<DispatchResult> {
		return self.filter { e in if case .PreparingToPlay = e as! PlayerEvents { return true } else { return false } }
			.flatMap { [unowned self] e -> Observable<DispatchResult> in
				
				return Observable<DispatchResult>.create { observer in
					guard case let .PreparingToPlay(item, targetContentType) = e as! PlayerEvents else { observer.onCompleted(); return NopDisposable.instance }
					
					print("preparing \(item.streamIdentifier.streamResourceUid)")
					
					guard item.streamIdentifier.streamResourceType == .HttpResource || item.streamIdentifier.streamResourceType == .HttpsResource else {
						observer.onCompleted()
						return NopDisposable.instance
					}
					
					
					guard let url = item.streamIdentifier.streamResourceUrl, urlRequest = httpUtilities.createUrlRequest(url,
						parameters: nil, headers: (item.streamIdentifier as? StreamHttpResourceIdentifier)?.streamHttpHeaders) else {
							observer.onCompleted()
							return NopDisposable.instance
					}
					
					
					func createUrlTask() -> StreamDataTaskProtocol {
						return httpUtilities.createStreamDataTask(item.streamIdentifier.streamResourceUid, request: urlRequest,
							sessionConfiguration: NSURLSession.defaultConfig,
							cacheProvider: fileStorage.createCacheProvider(item.streamIdentifier.streamResourceUid))
					}
					
					
					func saveData(cacheProvider: CacheProvider?) {
						if let cacheProvider = cacheProvider where saveCachedData {
							var provider = cacheProvider
							if let targetContentType = targetContentType {
								provider.contentMimeType = targetContentType.definition.MIME
							} else if let internalContentType = item.streamIdentifier.streamResourceContentType {
								provider.contentMimeType = internalContentType.definition.MIME
							}
							
							fileStorage.saveToTempStorage(provider)
						}
					}
					
					
					func createObservable(taskCreation: () -> StreamDataTaskProtocol, saveData: (cacheProvider: CacheProvider?) -> ()) -> Observable<StreamTaskEvents> {
						return Observable<StreamTaskEvents>.create { observer in
							let task = taskCreation()
							let disposable = task.taskProgress.bindNext { result in
								observer.onNext(result)
								
								if case .Success(let provider) = result {
									saveData(cacheProvider: provider)
									observer.onCompleted()
								} else if case .Error = result {
									observer.onCompleted()
								}
							}
							
							task.resume()
							
							return AnonymousDisposable {
								task.cancel()
								disposable.dispose()
							}
						}
					}
					
					let disposable = createObservable(createUrlTask, saveData: saveData).shareReplay(1)
						.streamContent(targetContentType ?? item.streamIdentifier.streamResourceContentType, utilities: playerUtilities).bindNext { e in
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
}