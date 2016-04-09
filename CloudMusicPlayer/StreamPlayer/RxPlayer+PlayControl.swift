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
	public func playUrl(url: StreamResourceIdentifier, contentTypeOverride: ContentType? = nil) {
		playUrl(url, clearQueue: true, contentTypeOverride: contentTypeOverride)
	}
	
	public func playUrl(url: StreamResourceIdentifier, clearQueue: Bool = true, contentTypeOverride: ContentType?) {
		if clearQueue {
			initWithNewItems([url])
			current = first
		} else {
			current = addLast(url)
		}
		
		guard let current = current else { return }
		queueEventsSubject.onNext(PlayerEvents.PreparingToPlay(current, contentTypeOverride))
	}
}