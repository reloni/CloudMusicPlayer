//
//  RxPlayer+LoadMetadata.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 28.04.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import RxSwift

extension RxPlayer {
	internal func loadFileMetadata(resource: StreamResourceIdentifier, file: NSURL, utilities: StreamPlayerUtilitiesProtocol) -> AudioItemMetadata? {
		guard file.fileExists() else { return nil }
		
		let item = utilities.createavPlayerItem(file)
		var metadataArray = item.getAsset().getMetadata()
		metadataArray["duration"] = item.getAsset().duration.safeSeconds
		return AudioItemMetadata(resourceUid: resource.streamResourceUid, metadata: metadataArray)
	}
	
	public func loadMetadata(resource: StreamResourceIdentifier) -> Observable<MediaItemMetadataType?> {
		return loadMetadata(resource, downloadManager: downloadManager, utilities: streamPlayerUtilities)
	}
	
	internal func loadMetadata(resource: StreamResourceIdentifier, downloadManager: DownloadManagerType, utilities: StreamPlayerUtilitiesProtocol) -> Observable<MediaItemMetadataType?> {
		return Observable.create { [weak self] observer in
			guard let object = self else { observer.onNext(nil); observer.onCompleted(); return NopDisposable.instance }
			
			if let metadata = object.mediaLibrary.getMetadata(resource) {
				observer.onNext(metadata)
				observer.onCompleted()
				return NopDisposable.instance
			}
			
			if let localFile = object.downloadManager.fileStorage.getFromStorage(resource.streamResourceUid) {
				let metadata = object.loadFileMetadata(resource, file: localFile, utilities: utilities)
				if let metadata = metadata {
					object.mediaLibrary.saveMetadata(resource, metadata: metadata)
				}
				
				observer.onNext(metadata)
				observer.onCompleted()
				return NopDisposable.instance
			}
			
			let downloadObservable = downloadManager.createDownloadObservable(resource, priority: .Low)
			
			var receivedDataLen = 0
			let disposable = downloadObservable.doOnError { observer.onError($0) }.bindNext { e in
				if case StreamTaskEvents.CacheData(let prov) = e {
					receivedDataLen = prov.getData().length
					if receivedDataLen >= 1024 * 256 {
						if let file = downloadManager.fileStorage.saveToTemporaryFolder(prov) {
							let metadata = object.loadFileMetadata(resource, file: file, utilities: utilities)
							if let metadata = metadata {
								object.mediaLibrary.saveMetadata(resource, metadata: metadata)
							}
							
							observer.onNext(metadata)
							file.deleteFile()
						}
						observer.onCompleted()
					}
				}
			}
			
			return AnonymousDisposable {
				disposable.dispose()
			}
		}
	}
	
	public func loadMetadataForItemsInQueue() -> Observable<MediaItemMetadataType?> {
		return loadMetadataForItemsInQueue(downloadManager, utilities: streamPlayerUtilities, mediaLibrary: mediaLibrary)
	}
	
	internal func loadMetadataForItemsInQueue(downloadManager: DownloadManagerType, utilities: StreamPlayerUtilitiesProtocol,
	                                          mediaLibrary: MediaLibraryType) -> Observable<MediaItemMetadataType?> {
		return Observable.create { [weak self] observer in
			guard let object = self else { observer.onCompleted(); return NopDisposable.instance }
			
			let serialScheduler = SerialDispatchQueueScheduler(globalConcurrentQueueQOS: DispatchQueueSchedulerQOS.Utility)
			let loadDisposable = object.currentItems.filter { !mediaLibrary.metadataExists($0.streamIdentifier) }.toObservable().observeOn(serialScheduler)
				.flatMap { item -> Observable<MediaItemMetadataType?> in
					return object.loadMetadata(item.streamIdentifier)
				}.doOnCompleted { print("batch metadata load completed"); observer.onCompleted() }.bindNext { meta in
					if let meta = meta {
						observer.onNext(meta)
					}
			}
			
			return AnonymousDisposable {
				print("dispose batch metadata load")
				observer.onCompleted()
				loadDisposable.dispose()
			}
		}
	}
}