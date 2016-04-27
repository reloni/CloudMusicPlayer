//
//  RxPlayerQueueItem.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 14.04.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import AVFoundation
import RxSwift

public class RxPlayerQueueItem {
	public var parent: RxPlayerQueueItem? {
		return player.getItemBefore(streamIdentifier)
	}
	public var child: RxPlayerQueueItem? {
		return player.getItemAfter(streamIdentifier)
	}
	public let streamIdentifier: StreamResourceIdentifier
	public let player: RxPlayer
	public var inQueue: Bool {
		return player.itemsSet.indexOfObject(streamIdentifier as! AnyObject) != NSNotFound
	}
	
	public init(player: RxPlayer, streamIdentifier: StreamResourceIdentifier) {
		self.player = player
		self.streamIdentifier = streamIdentifier
	}
	
	internal func loadFileMetadata(file: NSURL, utilities: StreamPlayerUtilitiesProtocol) -> AudioItemMetadata? {
		guard file.fileExists() else { return nil }
		
		let item = utilities.createavPlayerItem(file)
		var metadataArray = item.getAsset().getMetadata()
		metadataArray["duration"] = item.getAsset().duration.safeSeconds
		return AudioItemMetadata(metadata: metadataArray)
	}
	
	public func loadMetadata() -> Observable<MediaItemMetadataType?> {
		return loadMetadata(player.downloadManager, utilities: player.streamPlayerUtilities)
	}
	
	internal func loadMetadata(downloadManager: DownloadManagerType, utilities: StreamPlayerUtilitiesProtocol) -> Observable<MediaItemMetadataType?> {
		return Observable.create { [weak self] observer in
			guard let object = self else { observer.onNext(nil); observer.onCompleted(); return NopDisposable.instance }
			
			if let metadata = object.player.mediaLibrary.getMetadata(object.streamIdentifier) {
				observer.onNext(metadata)
				observer.onCompleted()
				return NopDisposable.instance
			}
			
			if let localFile = downloadManager.fileStorage.getFromStorage(object.streamIdentifier.streamResourceUid) {
				let metadata = object.loadFileMetadata(localFile, utilities: utilities)
				if let metadata = metadata {
					object.player.mediaLibrary.saveMetadata(object.streamIdentifier, metadata: metadata)
				}
				
				observer.onNext(metadata)
				observer.onCompleted()
				return NopDisposable.instance
			}
			
//			guard let downloadTask = downloadManager.createDownloadTask(object.streamIdentifier, checkInPendingTasks: false) else {
//				observer.onNext(nil)
//				observer.onCompleted()
//				return NopDisposable.instance
//			}
			let downloadObservable = downloadManager.createDownloadObservable(object.streamIdentifier, priority: .Low)
			
			var receivedDataLen = 0
			let disposable = downloadObservable.doOnError { observer.onError($0) }.bindNext { e in
				if case StreamTaskEvents.CacheData(let prov) = e {
					receivedDataLen = prov.getData().length
					if receivedDataLen >= 1024 * 256 {
						if let file = downloadManager.fileStorage.saveToTemporaryFolder(prov) {
							let metadata = object.loadFileMetadata(file, utilities: utilities)
							if let metadata = metadata {
								object.player.mediaLibrary.saveMetadata(object.streamIdentifier, metadata: metadata)
							}
							
							observer.onNext(metadata)
							file.deleteFile()
						}
						//downloadTask.cancel()
						print("Complete metadata task")
						observer.onCompleted()
					}
				}
			}
			
			//downloadTask.resume()
			
			return AnonymousDisposable {
				print("dispose metadata task")
				disposable.dispose()
				//downloadTask.cancel()
			}
		}
	}
	
	deinit {
		print("RxPlayerQueueItem deinit")
	}
}

public func ==(lhs: RxPlayerQueueItem, rhs: RxPlayerQueueItem) -> Bool {
	return lhs.hashValue == rhs.hashValue
}

extension RxPlayerQueueItem : Hashable {
	public var hashValue: Int {
		return streamIdentifier.streamResourceUid.hashValue
	}
}