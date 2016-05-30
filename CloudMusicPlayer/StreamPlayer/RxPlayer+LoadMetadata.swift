//
//  RxPlayer+LoadMetadata.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 28.04.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import RxSwift
import MediaPlayer

extension RxPlayer {
	public func getCurrentItemMetadataForNowPlayingCenter() -> [String: AnyObject]? {
		guard let current = current else { return nil }
		guard let meta = (try? mediaLibrary.getMetadataObjectByUid(current.streamIdentifier)) ?? nil else { return nil }
		
		var data = [String: AnyObject]()
		data[MPMediaItemPropertyTitle] = meta.title
		data[MPMediaItemPropertyAlbumTitle] = meta.album
		data[MPMediaItemPropertyArtist] = meta.artist
		data[MPMediaItemPropertyPlaybackDuration] = meta.duration
		data[MPNowPlayingInfoPropertyElapsedPlaybackTime] = internalPlayer.getCurrentTimeAndDuration()?.currentTime.safeSeconds
		data[MPNowPlayingInfoPropertyPlaybackRate] = playing ? 1 : 0
		if let artwork = meta.artwork, image = UIImage(data: artwork) {
			data[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(image: image)
		}
		return data
	}
	
	internal func loadFileMetadata(resource: StreamResourceIdentifier, file: NSURL, utilities: StreamPlayerUtilitiesProtocol) -> AudioItemMetadata? {
		guard file.fileExists() else { return nil }
		
		let item = utilities.createavPlayerItem(file)
		var metadataArray = item.getAsset().getMetadata()
		metadataArray["duration"] = item.getAsset().duration.safeSeconds
		return AudioItemMetadata(resourceUid: resource.streamResourceUid, metadata: metadataArray)
	}
	
	public func loadMetadata(resource: StreamResourceIdentifier) -> Observable<Result<MediaItemMetadataType?>> {
		return loadMetadata(resource, downloadManager: downloadManager, utilities: streamPlayerUtilities)
	}
	
	internal func loadMetadata(resource: StreamResourceIdentifier, downloadManager: DownloadManagerType, utilities: StreamPlayerUtilitiesProtocol)
		-> Observable<Result<MediaItemMetadataType?>> {
		return Observable.create { [weak self] observer in
			guard let object = self else { observer.onNext(Result.success(Box(value: nil))); observer.onCompleted(); return NopDisposable.instance }
			
			if let metadata = try! object.mediaLibrary.getMetadataObjectByUid(resource) {
				observer.onNext(Result.success(Box(value: metadata)))
				observer.onCompleted()
				return NopDisposable.instance
			}
			
			if let localFile = object.downloadManager.fileStorage.getFromStorage(resource.streamResourceUid) {
				let metadata = object.loadFileMetadata(resource, file: localFile, utilities: utilities)
				if let metadata = metadata {
					object.mediaLibrary.saveMetadataSafe(metadata, updateExistedObjects: true)
				}
				
				observer.onNext(Result.success(Box(value: metadata)))
				observer.onCompleted()
				return NopDisposable.instance
			}
			
			let downloadObservable = downloadManager.createDownloadObservable(resource, priority: .Low)
			
			var receivedDataLen = 0
			let disposable = downloadObservable.catchError { error in
					observer.onNext(Result.error(error))
					observer.onCompleted()
					return Observable.empty()
				}.bindNext { e in
				if case Result.success(let box) = e {
					if case StreamTaskEvents.CacheData(let prov) = box.value {
						receivedDataLen = prov.getData().length
						if receivedDataLen >= 1024 * 256 {
							if let file = downloadManager.fileStorage.saveToTemporaryFolder(prov) {
								let metadata = object.loadFileMetadata(resource, file: file, utilities: utilities)
								if let metadata = metadata {
									object.mediaLibrary.saveMetadataSafe(metadata, updateExistedObjects: true)
								}
								
								observer.onNext(Result.success(Box(value: metadata)))
								file.deleteFile()
							}
							observer.onCompleted()
						}
					}
				} else if case Result.error(let error) = e {
					observer.onNext(Result.error(error))
					observer.onCompleted()
				}
			}
			
			return AnonymousDisposable {
				disposable.dispose()
			}
		}
	}
	
	public func loadMetadataForItemsInQueue() -> Observable<Result<MediaItemMetadataType>> {
		return loadMetadataForItemsInQueue(downloadManager, utilities: streamPlayerUtilities, mediaLibrary: mediaLibrary)
	}
	
	public func loadMetadataAndAddToMediaLibrary(items: [StreamResourceIdentifier]) -> Observable<Result<MediaItemMetadataType>> {
		return Observable.create { [weak self] observer in
			guard let object = self else { observer.onCompleted(); return NopDisposable.instance }
			
			let serialScheduler = SerialDispatchQueueScheduler(globalConcurrentQueueQOS: DispatchQueueSchedulerQOS.Utility)
			let loadDisposable = items.toObservable().observeOn(serialScheduler)
				.flatMap { item -> Observable<Result<MediaItemMetadataType?>> in
					return object.loadMetadata(item)
				}.doOnCompleted { print("batch metadata load completed"); observer.onCompleted() }.bindNext { result in
					if case Result.success(let box) = result, let meta = box.value {
						observer.onNext(Result.success(Box(value: meta)))
					} else if case Result.error(let error) = result {
						observer.onNext(Result.error(error))
					}
			}
			
			return AnonymousDisposable {
				print("dispose batch metadata load")
				//observer.onCompleted()
				loadDisposable.dispose()
			}
		}
	}
	
	internal func loadMetadataForItemsInQueue(downloadManager: DownloadManagerType, utilities: StreamPlayerUtilitiesProtocol,
	                                          mediaLibrary: MediaLibraryType) -> Observable<Result<MediaItemMetadataType>> {
		return loadMetadataAndAddToMediaLibrary(currentItems.map { $0.streamIdentifier })
	}
}