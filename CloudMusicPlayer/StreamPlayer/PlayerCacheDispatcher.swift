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
	func createLoadTask(identifier: StreamResourceIdentifier, urlRequest: NSMutableURLRequestProtocol) -> Observable<StreamTaskEvents>
	func createCacheItem(identifier: StreamResourceIdentifier, customHttpHeaders: [String: String]?, targetContentType: ContentType?) -> CacheItem?
}

public class PlayerCacheDispatcher {
	internal let localFileStorage: LocalStorageProtocol
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
	
	public func createLoadTask(identifier: StreamResourceIdentifier, urlRequest: NSMutableURLRequestProtocol) -> Observable<StreamTaskEvents> {
		return Observable.create { [unowned self] observer in
			let task = self.httpUtilities.createStreamDataTask(identifier.streamResourceUid, request: urlRequest,
				sessionConfiguration: NSURLSession.defaultConfig,
				cacheProvider: self.localFileStorage.createCacheProvider(identifier.streamResourceUid))
			let disposable = task.taskProgress.bindNext { result in
				observer.onNext(result)
				
				if case .Success = result {
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
	func getLoadTask() -> Observable<StreamTaskEvents>
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
	
	public func getLoadTask() -> Observable<StreamTaskEvents> {
		return cacheDispatcher.createLoadTask(resourceIdentifier, urlRequest: urlRequest)
	}
	
	deinit {
		print("cache item deinit")
	}
}