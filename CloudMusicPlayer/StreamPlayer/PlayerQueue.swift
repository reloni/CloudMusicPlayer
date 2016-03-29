//
//  PlayerQueue.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 28.03.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation

public class PlayerQueue {
	public private(set) var root: PlayerQueueItem?
	public private(set) var last: PlayerQueueItem?
	public private(set) var current: PlayerQueueItem?
	internal var items = [String: PlayerQueueItem]()
	
	public init() { }
	
	public init(items: [StreamAudioItem], shuffle: Bool = false) {
		(self.items, self.root, self.last) = initItems(items, shuffle: shuffle)
	}
	
	internal func initItems(items: [StreamAudioItem], shuffle: Bool = false) ->
		(queueItems: [String: PlayerQueueItem], first: PlayerQueueItem?, last: PlayerQueueItem?) {
			guard items.count > 1 else {
				let item = PlayerQueueItem(playerItem: items.first!)
				return ([item.playerItem.resourceIdentifier.uid: item], item, item)
			}
			
			var queueItems = items.map { PlayerQueueItem(playerItem: $0) }
			if shuffle {
				queueItems = queueItems.shuffle()
			}
			
			_ = queueItems.dropFirst().reduce(queueItems.first!) { item, next in
				item.child = next
				next.parent = item
				return next
			}
			
			let newQueue = Dictionary<String, PlayerQueueItem>(queueItems.map { ($0.playerItem.resourceIdentifier.uid, $0)})
			
			return (queueItems: newQueue, first: queueItems.first, last: queueItems.last)
	}
}

public class PlayerQueueItem {
	public var parent: PlayerQueueItem?
	public var child: PlayerQueueItem?
	public let playerItem: StreamAudioItem
	
	public init(playerItem: StreamAudioItem) {
		self.playerItem = playerItem
	}
}