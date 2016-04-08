//
//  StreamPlayerCacheManager.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 01.04.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import RxSwift

public protocol PlayerCacheDispatcherProtocol {
	var saveCachedData: Bool  { get }
	var localFileStorage: LocalStorageProtocol { get }
	//func createLoadTask(identifier: StreamResourceIdentifier, urlRequest: NSMutableURLRequestProtocol) -> Observable<StreamTaskEvents>
	//func createCacheItem(identifier: StreamResourceIdentifier, customHttpHeaders: [String: String]?, targetContentType: ContentType?) -> CacheItem?
	func createStreamTask(identifier: StreamResourceIdentifier, targetContentType: ContentType?) -> Observable<StreamTaskEvents>?
	func createStreamTask(identifier: StreamResourceIdentifier, customHttpHeaders: [String: String]?, targetContentType: ContentType?)
		-> Observable<StreamTaskEvents>?
}

public class PlayerCacheDispatcher {
	public let localFileStorage: LocalStorageProtocol
	internal let httpUtilities: HttpUtilitiesProtocol
	public let saveCachedData: Bool
	internal let runningTasks = [String: StreamDataTaskProtocol]()
	private let bag = DisposeBag()
	
	internal init(saveCachedData: Bool = false, httpUtilities: HttpUtilitiesProtocol = HttpUtilities.instance,
	              fileStorage: LocalStorageProtocol = LocalStorage(),
	              playerState: Observable<PlayerState>? = nil, queueEvents: Observable<PlayerQueueEvents>? = nil) {
		self.saveCachedData = saveCachedData
		self.httpUtilities = httpUtilities
		self.localFileStorage = fileStorage
	}
	
	internal func bindToEvents(playerState: Observable<PlayerState>? = nil, queueEvents: Observable<PlayerQueueEvents>? = nil) {
		
	}
}

extension PlayerCacheDispatcher : PlayerCacheDispatcherProtocol {
	public func createStreamTask(identifier: StreamResourceIdentifier, targetContentType: ContentType?) -> Observable<StreamTaskEvents>? {
		return createStreamTask(identifier, customHttpHeaders: nil, targetContentType: targetContentType)
	}
	
	public func createStreamTask(identifier: StreamResourceIdentifier, customHttpHeaders: [String : String]?, targetContentType: ContentType?) -> Observable<StreamTaskEvents>? {
		if identifier.streamResourceType == .HttpResource || identifier.streamResourceType == .HttpsResource {
			guard let url = identifier.streamResourceUrl, urlRequest = httpUtilities.createUrlRequest(url, parameters: nil, headers: customHttpHeaders) else {
				return nil
			}
			
			func createUrlTask() -> StreamDataTaskProtocol {
				return httpUtilities.createStreamDataTask(identifier.streamResourceUid, request: urlRequest,
				                                              sessionConfiguration: NSURLSession.defaultConfig,
				                                              cacheProvider: localFileStorage.createCacheProvider(identifier.streamResourceUid))
			}
			
			func saveData(cacheProvider: CacheProvider?) {
				if let cacheProvider = cacheProvider where saveCachedData {
					var provider = cacheProvider
					if let targetContentType = targetContentType { provider.contentMimeType = targetContentType.definition.MIME }
					self.localFileStorage.saveToTempStorage(provider)
				}
			}
			
			return createObservable(createUrlTask, saveData: saveData)
		} else { return nil }
	}
	
	internal func createObservable(taskCreation: () -> StreamDataTaskProtocol, saveData: (cacheProvider: CacheProvider?) -> ()) -> Observable<StreamTaskEvents> {
		return Observable.create { observer in
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
		}.shareReplay(1)
	}
}