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
	public func playUrl(url: StreamResourceIdentifier, clearQueue: Bool = true) {
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
	
	public func playPlayList(playList: PlayListType) {
		playPlayList(playList, shuffle: shuffleQueue)
	}
	
	public func playPlayList(playList: PlayListType, shuffle: Bool) {
		let queueItems = playList.items.map { loadStreamResourceByUid($0.uid) }
		initWithNewItems(queueItems, shuffle: shuffle)
		playing = true
		current = first
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