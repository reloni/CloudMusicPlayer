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
			if let index = itemsSet.getIndexOfObject(url as! AnyObject) {
				// if found item queue, set this item as current
				current = getItemAtPosition(index)
			} else {
				current = addLast(url)
			}
		}
	}
	
	public func pause() {
		playing = false
		if let current = current {
			queueEventsSubject.onNext(.Pausing(current))
		}
	}
	
	public func resume(force: Bool = false) {
		if let current = current {
			playing = true
			queueEventsSubject.onNext(.Resuming(current))
		} else if force {
			//playing = true
			toNext(true)
		}
	}
	
	public func stop() {
		playing = false
		if let current = current {
			queueEventsSubject.onNext(.Stopping(current))
		}
	}
}

extension Observable where Element : PlayerEventType {
	public func dispatchPlayerControlEvents() -> Observable<Void> {
		return self.map { e in return e as! PlayerEvents }.map { e in
			switch e {
			case .Pausing(let current): current.player.internalPlayer.pause()
			case .Resuming(let current):
				if current.player.internalPlayer.nativePlayer == nil {
					current.player.queueEventsSubject.onNext(PlayerEvents.PreparingToPlay(current))
				} else {
					current.player.internalPlayer.resume()
				}
			case .Stopping(let current): current.player.internalPlayer.stop()
			case .FinishPlayingCurrentItem(let player): player.toNext(true)
			default: break
			}
		}
	}
}
