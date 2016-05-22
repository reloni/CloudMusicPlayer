//
//  MediaLibraryModel.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 20.05.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import RxSwift

class MediaLibraryModel {
	let player: RxPlayer
	let newResourceSubject = PublishSubject<CloudResource>()
	var pendingItemsCount = 0
	let scheduler = SerialDispatchQueueScheduler(globalConcurrentQueueQOS: DispatchQueueSchedulerQOS.Utility)
	
	init(player: RxPlayer) {
		self.player = player
	}
	
	func addToMediaLibrary(resources: [CloudResource]) {
		resources.forEach { pendingItemsCount += 1; newResourceSubject.onNext($0) }
	}

	var loadProgress: Observable<Int> {
		return Observable.create { [weak self] observer in
			guard let object = self else { observer.onCompleted(); return NopDisposable.instance }
			
			var itemsToProcess = 0
			//var processedItems = 0
			let disposable = object.newResourceSubject.observeOn(object.scheduler).flatMap { resource -> Observable<CloudResource> in
				if resource is CloudAudioResource {
					return Observable.just(resource)
				} else {
					return resource.loadChildResourcesRecursive()
				}
				}.filter { $0 is CloudAudioResource }.map { item -> StreamResourceIdentifier in itemsToProcess += 1; return item as! StreamResourceIdentifier }
				.flatMap { return rxPlayer.loadMetadata($0) }.catchError { _ in print("catch in library model"); return Observable.empty() }
				.doOnNext { _ in
					itemsToProcess -= 1
					observer.onNext(itemsToProcess)
				}.doOnCompleted { print("completed?") }.subscribe()
		
			return AnonymousDisposable {
				disposable.dispose()
			}
		}
	}
}