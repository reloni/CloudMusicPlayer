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
	func loadChildResourcesRecursive(resource: CloudResource, loadMode: CloudResourceLoadMode) -> Observable<Result<[CloudResource]>>
}

public class CloudResourceClient {
	public internal(set) var cacheProvider: CloudResourceCacheProviderType?
	init(cacheProvider: CloudResourceCacheProviderType? = nil) {
		self.cacheProvider = cacheProvider
	}
	
	internal func internalLoadChildResourcesRecursive(resource: CloudResource, loadMode: CloudResourceLoadMode) -> Observable<Result<CloudResource>> {
		return Observable.create { [weak self] observer in
			guard let object = self else { observer.onCompleted(); return NopDisposable.instance }
			
			let serialScheduler = SerialDispatchQueueScheduler(globalConcurrentQueueQOS: DispatchQueueSchedulerQOS.Utility)
			
			let disposable = object.loadChildResources(resource, loadMode: loadMode).observeOn(serialScheduler).flatMap { result -> Observable<CloudResource> in
				if case Result.success(let box) = result {
					return box.value.toObservable()
				} else if case Result.error(let error) = result {
					observer.onNext(Result.error(error))
					observer.onCompleted()
					return Observable.empty()
				} else {
					observer.onCompleted()
					return Observable.empty()
				}
				}.flatMap { e -> Observable<Result<CloudResource>> in
					return [Result.success(Box(value: e))].toObservable().concat(object.internalLoadChildResourcesRecursive(e, loadMode: loadMode).observeOn(serialScheduler))
				}.bindTo(observer)
			
			return AnonymousDisposable {
				disposable.dispose()
			}
		}
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
	
	public func loadChildResourcesRecursive(resource: CloudResource, loadMode: CloudResourceLoadMode) -> Observable<Result<[CloudResource]>> {
		return Observable.create { [weak self] observer in
			guard let object = self else { observer.onCompleted(); return NopDisposable.instance }
			
			let disposable = object.internalLoadChildResourcesRecursive(resource, loadMode: loadMode).flatMap { result -> Observable<CloudResource> in
				if case Result.success(let box) = result {
					return Observable.just(box.value)
				} else if case Result.error(let error) = result {
					observer.onNext(Result.error(error))
					observer.onCompleted()
					return Observable.empty()
				} else {
					observer.onCompleted()
					return Observable.empty()
				}
				}.toArray().bindNext { result in
					observer.onNext(Result.success(Box(value: result)))
					observer.onCompleted()
			}
			
			return AnonymousDisposable {
				disposable.dispose()
			}
		}
	}
}