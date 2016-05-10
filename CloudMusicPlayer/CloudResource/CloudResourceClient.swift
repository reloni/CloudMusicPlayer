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
	func loadChildResources(resource: CloudResource, loadMode: CloudResourceLoadMode) -> Observable<[CloudResource]>
}

public class CloudResourceClient {
	public internal(set) var cacheProvider: CloudResourceCacheProviderType?
	init(cacheProvider: CloudResourceCacheProviderType? = nil) {
		self.cacheProvider = cacheProvider
	}
}

extension CloudResourceClient : CloudResourceClientType {
	public func loadChildResources(resource: CloudResource, loadMode: CloudResourceLoadMode) -> Observable<[CloudResource]> {
		return Observable.create { [weak self] observer in
			// check cached data
			//var cacheDisposable: Disposable?
			if loadMode == .CacheAndRemote || loadMode == .CacheOnly {
				if let cachedData = self?.cacheProvider?.getCachedChilds(resource) where cachedData.count > 0 {
					//cacheDisposable = resource.deserializeResponse(JSON(data: cachedData).toObservable()).toArray().bindNext { observer.onNext($0) }
					observer.onNext(cachedData)
				}
			}
			
			var remoteDisposable: Disposable?
			if loadMode == .CacheAndRemote || loadMode == .RemoteOnly {
				remoteDisposable = resource.loadChildResources().doOnError { error in
					// catch errors
					observer.onError(error)
					}.flatMapLatest { json -> Observable<CloudResource> in
//						if let cacheProvider = self?.cacheProvider, rawData = try? json.rawData() {
//							//cacheProvider.cacheChilds(resource, childsData: rawData)
//						}
						return resource.deserializeResponse(json).toObservable()
					}.toArray().doOnCompleted { observer.onCompleted() }.bindNext {
						self?.cacheProvider?.cacheChilds(resource, childs: $0)
						observer.onNext($0)
				}
			} else { observer.onCompleted() }
			
			return AnonymousDisposable {
				//cacheDisposable?.dispose()
				remoteDisposable?.dispose()
			}
		}
	}
}