//
//  RxPlayer+PlayControl.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 08.04.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import RxSwift

extension RxPlayer {
	public func play(url: StreamResourceIdentifier, clearQueue: Bool = true) {
		if clearQueue {
			initWithNewItems([url])
			playing = true
			current = first
		} else {
			playing = true
			if let index = itemsSet.getIndexOfObject(url.asQueueSetItem()) {
				// if found item queue, set this item as current
				current = getItemAtPosition(index)
			} else {
				current = addLast(url)
			}
		}
	}
	
	func play(playList: PlayListType, startWithTrack: TrackType? = nil) {
		play(playList, shuffle: shuffleQueue, startWithTrack: startWithTrack)
	}
	
	func play(playList: PlayListType, shuffle: Bool, startWithTrack: TrackType? = nil) {
		//let items = playList.items.map { loadStreamResourceByUid($0.uid) }
		//var startWithItem: StreamResourceIdentifier? = nil
		//if let startWithTrack = startWithTrack {
		//	startWithItem = loadStreamResourceByUid(startWithTrack.uid)
		//}
		//play(items, startWithItem: startWithItem)
		let tracks = playList.items.map { $0 }
		play(tracks, startWithTrack: startWithTrack)
	}
	
	func play(tracks: [TrackType], startWithTrack: TrackType? = nil) {
		let items = tracks.map { loadStreamResourceByUid($0.uid) }
		var startWithItem: StreamResourceIdentifier? = nil
		if let startWithTrack = startWithTrack {
			startWithItem = loadStreamResourceByUid(startWithTrack.uid)
		}
		play(items, startWithItem: startWithItem)
	}
	
	func play(items: [StreamResourceIdentifier], startWithItem: StreamResourceIdentifier? = nil) {
		play(items, shuffle: shuffleQueue, startWithItem: startWithItem)
	}
	
	func play(items: [StreamResourceIdentifier], shuffle: Bool, startWithItem: StreamResourceIdentifier? = nil) {
		initWithNewItems(items)
		if let startWithItem = startWithItem, item = getQueueItemByUid(startWithItem.streamResourceUid) {
			addFirst(startWithItem)
			current = item
		}
		resume(true)
	}
	
	func play(item: RxPlayerQueueItem) {
		guard item.inQueue else { return }
		playing = true
		current = item
	}
	
	public func loadStreamResourceByUid(itemUid: String) -> StreamResourceIdentifier {
		for loader in streamResourceLoaders {
			if let streamResource = loader.loadStreamResourceByUid(itemUid) {
				return streamResource
			}
		}
		
		return itemUid
	}
	
	public func pause() {
		playing = false
		if let current = current {
			playerEventsSubject.onNext(.Pausing(current))
			internalPlayer.pause()
		}
	}
	
	public func resume(force: Bool = false) {
		if let current = current {
			playing = true
			playerEventsSubject.onNext(.Resuming(current))
			if internalPlayer.nativePlayer == nil {
				playerEventsSubject.onNext(.PreparingToPlay(_current!))
				startStreamTask()
			} else {
				internalPlayer.resume()
			}
		} else if force {
			//playing = true
			toNext(true)
		}
	}
	
	public func stop() {
		playing = false
		if let current = current {
			playerEventsSubject.onNext(.Stopping(current))
			internalPlayer.stop()
		}
	}
}