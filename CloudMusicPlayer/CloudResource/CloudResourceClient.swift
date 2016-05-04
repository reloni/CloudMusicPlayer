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
			var cacheDisposable: Disposable?
			if loadMode == .CacheAndRemote || loadMode == .CacheOnly {
				if let cachedData = self?.cacheProvider?.getCachedChilds(resource) {
					cacheDisposable = resource.deserializeResponse(JSON(data: cachedData)).toArray().bindNext { observer.onNext($0) }
				}
			}
			
			let disposable = resource.loadChildResources().doOnError { error in
				// catch errors
				observer.onError(error)
				}.flatMapLatest { json -> Observable<CloudResource> in
					if let cacheProvider = self?.cacheProvider, rawData = try? json.rawData() {
						cacheProvider.cacheChilds(resource, childsData: rawData)
					}
					return resource.deserializeResponse(json)
				}.doOnCompleted { observer.onCompleted() }.toArray().bindNext { observer.onNext($0) }
			
			return AnonymousDisposable {
				cacheDisposable?.dispose()
				disposable.dispose()
			}
		}
	}
}