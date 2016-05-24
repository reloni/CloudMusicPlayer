//
//  CloudResourceClient.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 04.05.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import RxSwift
import SwiftyJSON

public protocol CloudResourceClientType {
	var cacheProvider: CloudResourceCacheProviderType? { get }
	func loadChildResources(resource: CloudResource, loadMode: CloudResourceLoadMode) -> Observable<Result<[CloudResource]>>
}

public class CloudResourceClient {
	public internal(set) var cacheProvider: CloudResourceCacheProviderType?
	init(cacheProvider: CloudResourceCacheProviderType? = nil) {
		self.cacheProvider = cacheProvider
	}
}

extension CloudResourceClient : CloudResourceClientType {
	public func loadChildResources(resource: CloudResource, loadMode: CloudResourceLoadMode) -> Observable<Result<[CloudResource]>> {
		return Observable.create { [weak self] observer in
			// check cached data
			if loadMode == .CacheAndRemote || loadMode == .CacheOnly {
				if let cachedData = self?.cacheProvider?.getCachedChilds(resource) where cachedData.count > 0 {
					observer.onNext(Result.success(Box(value: cachedData)))
				}
			}
			
			var remoteDisposable: Disposable?
			if loadMode == .CacheAndRemote || loadMode == .RemoteOnly {
				remoteDisposable = resource.loadChildResources().catchError { error in
					observer.onNext(Result.error(error))
					return Observable.empty()
					}.flatMapLatest { result -> Observable<CloudResource> in
						if case Result.success(let box) = result {
							return resource.deserializeResponse(box.value).toObservable()
						} else if case Result.error(let error) = result {
							observer.onNext(Result.error(error))
							return Observable.error(error)
						}
						return Observable.empty()
					}.toArray().doOnCompleted { observer.onCompleted() }.bindNext {
						self?.cacheProvider?.cacheChilds(resource, childs: $0)
						observer.onNext(Result.success(Box(value: $0)))
				}
			} else { observer.onCompleted() }
			
			return AnonymousDisposable {
				remoteDisposable?.dispose()
			}
		}
	}
}