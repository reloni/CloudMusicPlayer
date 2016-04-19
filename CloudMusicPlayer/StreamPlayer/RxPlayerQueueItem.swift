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
	
	public func loadMetadata() -> Observable<AudioItemMetadata?> {
		return loadMetadata(player.downloadManager, utilities: player.streamPlayerUtilities)
	}
	
	internal func loadMetadata(downloadManager: DownloadManagerType, utilities: StreamPlayerUtilitiesProtocol) -> Observable<AudioItemMetadata?> {
		return Observable.create { [weak self] observer in
			guard let object = self else { observer.onNext(nil); observer.onCompleted(); return NopDisposable.instance }
			
			if let localFile = downloadManager.fileStorage.getFromStorage(object.streamIdentifier.streamResourceUid) {
				observer.onNext(object.loadFileMetadata(localFile, utilities: utilities))
				observer.onCompleted()
				return NopDisposable.instance
			}
			
			guard let downloadTask = downloadManager.createDownloadTask(object.streamIdentifier, checkInPendingTasks: false) else {
				observer.onNext(nil)
				observer.onCompleted()
				return NopDisposable.instance
			}
			
			var receivedDataLen = 0
			let disposable = downloadTask.taskProgress.bindNext { e in
				if case StreamTaskEvents.CacheData(let prov) = e {
					receivedDataLen = prov.getData().length
					if receivedDataLen >= 1024 * 256 {
						if let file = downloadManager.fileStorage.saveToTemporaryFolder(prov) {
							observer.onNext(object.loadFileMetadata(file, utilities: utilities))
							file.deleteFile()
						}
						downloadTask.cancel()
						observer.onCompleted()
					}
				} else if case StreamTaskEvents.Error = e {
					downloadTask.cancel()
					observer.onNext(nil)
					observer.onCompleted()
				}
			}
			
			downloadTask.resume()
			
			return AnonymousDisposable {
				disposable.dispose()
				downloadTask.cancel()
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