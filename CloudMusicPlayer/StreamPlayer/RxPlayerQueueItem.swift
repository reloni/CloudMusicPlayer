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
}

public func ==(lhs: RxPlayerQueueItem, rhs: RxPlayerQueueItem) -> Bool {
	return lhs.hashValue == rhs.hashValue
}

extension RxPlayerQueueItem : Hashable {
	public var hashValue: Int {
		return streamIdentifier.streamResourceUid.hashValue
	}
}