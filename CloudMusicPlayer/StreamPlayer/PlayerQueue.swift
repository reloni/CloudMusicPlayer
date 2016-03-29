//
//  PlayerQueue.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 28.03.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation

public class PlayerQueue {
	public var first: PlayerQueueItem? {
		return getItemAtPosition(0)
	}
	public var last: PlayerQueueItem? {
		return getItemAtPosition(itemsSet.count - 1)
	}
	public private(set) var current: PlayerQueueItem?
	//internal var items = [String: PlayerQueueItem]()
	public var currentItems: [PlayerQueueItem] {
		return itemsSet.map { PlayerQueueItem(queue: self, playerItem: $0 as! StreamAudioItem) }
	}
	internal var itemsSet = NSMutableOrderedSet()
	
	public init() { }
	
	public init(items: [StreamAudioItem], shuffle: Bool = false) {
		if shuffle {
			itemsSet.addObjectsFromArray(items.shuffle())
		} else {
			itemsSet.addObjectsFromArray(items)
		}
	}
	
	public func getItemAtPosition(position: Int) -> PlayerQueueItem? {
		guard position != NSNotFound && position >= 0 && position < itemsSet.count else { return nil }
		guard let item = itemsSet[position] as? StreamAudioItem else { return nil }
		return PlayerQueueItem(queue: self, playerItem: item)
	}
	
	public func getItemAfter(item: StreamAudioItem) -> PlayerQueueItem? {
		let index = itemsSet.indexOfObject(item)
		return getItemAtPosition(index + 1)
	}
	
	public func getItemBefore(item: StreamAudioItem) -> PlayerQueueItem? {
		let index = itemsSet.indexOfObject(item)
		return getItemAtPosition(index - 1)
	}
	
	public func addLast(item: StreamAudioItem) -> PlayerQueueItem {
		return add(item, index: itemsSet.count)
	}
	
	public func addFirst(item: StreamAudioItem) -> PlayerQueueItem {
		return add(item, index: 0)
	}

	/// Add item in queue after specified item.
	/// If specified item doesn't exist, add to end
	public func addAfter(itemToAdd: StreamAudioItem, afterItem: StreamAudioItem) -> PlayerQueueItem {
		let index = itemsSet.getIndexOfObject(afterItem) ?? itemsSet.count
		return add(itemToAdd, index: index + 1)
	}
	
	/// Add item in queue. 
	/// Return instance of PlayerQueueItem if item was added. 
	/// If item already exists - return PlayerQueueItem with this item
	internal func add(item: StreamAudioItem, index: Int) -> PlayerQueueItem {
		guard itemsSet.indexOfObject(item) == NSNotFound else { return PlayerQueueItem(queue: self, playerItem: item) }
		
		if 0..<itemsSet.count + 1 ~= index {
			itemsSet.insertObject(item, atIndex: index)
		} else {
			itemsSet.addObject(item)
		}
		
		return PlayerQueueItem(queue: self, playerItem: item)
	}
}

public class PlayerQueueItem {
	public var parent: PlayerQueueItem? {
		return queue.getItemBefore(playerItem)
	}
	public var child: PlayerQueueItem? {
		return queue.getItemAfter(playerItem)
	}
	public let playerItem: StreamAudioItem
	public let queue: PlayerQueue
	public var inQueue: Bool {
		return queue.itemsSet.indexOfObject(playerItem) != NSNotFound
	}
	
	public init(queue: PlayerQueue, playerItem: StreamAudioItem) {
		self.queue = queue
		self.playerItem = playerItem
	}
}