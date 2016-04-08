//
//  RxPlayer+Dispatch.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 08.04.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import RxSwift

extension Observable where Element : PlayerEventType {
	public func dispatch(saveCachedData: Bool = false, httpUtilities: HttpUtilitiesProtocol = HttpUtilities.instance,
	                     fileStorage: LocalStorageProtocol = LocalStorage()) -> Observable<StreamTaskEvents> {
		return self.filter { e in if case .PreparingToPlay = e as! PlayerEvents { return true } else { return false } }
			.flatMap { [unowned self] e -> Observable<StreamTaskEvents> in
				if case .PreparingToPlay(let item, let targetContentType) = e as! PlayerEvents {
					guard item.streamIdentifier.streamResourceType == .HttpResource || item.streamIdentifier.streamResourceType == .HttpsResource else {
						return Observable<StreamTaskEvents>.empty()
					}
					
					guard let url = item.streamIdentifier.streamResourceUrl, urlRequest = httpUtilities.createUrlRequest(url,
						parameters: nil, headers: (item.streamIdentifier as? StreamHttpResourceIdentifier)?.streamHttpHeaders) else {
							return Observable<StreamTaskEvents>.empty()
					}
					
					func createUrlTask() -> StreamDataTaskProtocol {
						return httpUtilities.createStreamDataTask(item.streamIdentifier.streamResourceUid, request: urlRequest,
							sessionConfiguration: NSURLSession.defaultConfig,
							cacheProvider: fileStorage.createCacheProvider(item.streamIdentifier.streamResourceUid))
					}
					
					func saveData(cacheProvider: CacheProvider?) {
						if let cacheProvider = cacheProvider where saveCachedData {
							var provider = cacheProvider
							if let targetContentType = targetContentType { provider.contentMimeType = targetContentType.definition.MIME }
							fileStorage.saveToTempStorage(provider)
						}
					}
					
					return self.createObservable(createUrlTask, saveData: saveData).shareReplay(1)
				} else {
					return Observable<StreamTaskEvents>.empty()
				}
		}
	}
	
	internal func createObservable(taskCreation: () -> StreamDataTaskProtocol, saveData: (cacheProvider: CacheProvider?) -> ()) -> Observable<StreamTaskEvents> {
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
	
}
