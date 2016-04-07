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
	public func createCacheItem(identifier: StreamResourceIdentifier, customHttpHeaders: [String: String]? = nil, targetContentType: ContentType? = nil) -> CacheItem? {
		guard let url = identifier.streamResourceUrl, urlRequest = httpUtilities.createUrlRequest(url, parameters: nil, headers: customHttpHeaders) else {
			return nil
		}

		return UrlCacheItem(identifier: identifier, cacheDispatcher: self, urlRequest: urlRequest, targetContentType: targetContentType)
	}
	
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

public protocol CacheItem {
	var cacheDispatcher: PlayerCacheDispatcherProtocol { get }
	var resourceIdentifier: StreamResourceIdentifier { get }
	var targetContentType: ContentType? { get }
	//func getLoadTask() -> Observable<StreamTaskEvents>
}

public class UrlCacheItem : CacheItem {
	internal let urlRequest: NSMutableURLRequestProtocol
	public let targetContentType: ContentType?
	public let cacheDispatcher: PlayerCacheDispatcherProtocol
	public let resourceIdentifier: StreamResourceIdentifier
	
	public init(identifier: StreamResourceIdentifier, cacheDispatcher: PlayerCacheDispatcherProtocol,
	            urlRequest: NSMutableURLRequestProtocol, targetContentType: ContentType? = nil) {
		self.urlRequest = urlRequest
		self.cacheDispatcher = cacheDispatcher
		self.targetContentType = targetContentType
		self.resourceIdentifier = identifier
	}
	
	//public func getLoadTask() -> Observable<StreamTaskEvents> {
	//	return cacheDispatcher.createLoadTask(resourceIdentifier, urlRequest: urlRequest).map { e in
	//		if case .Success(let provider) = e where self.cacheDispatcher.saveCachedData && provider != nil {
	//			var cacheProvider = provider
	//			if let targetContentType = self.targetContentType { cacheProvider?.contentMimeType = targetContentType.definition.MIME }
	//			self.cacheDispatcher.localFileStorage.saveToTempStorage(cacheProvider!)
	//		}
	//		return e
	//	}
	//}
	
	deinit {
		print("cache item deinit")
	}
}