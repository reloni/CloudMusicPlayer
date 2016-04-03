//
//  PlayerQueue.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 28.03.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation

public class PlayerQueue {
	internal var itemsSet = NSMutableOrderedSet()
	public internal(set) var current: PlayerQueueItem?
	public internal(set) var repeatQueue: Bool
	
	public var first: PlayerQueueItem? {
		return getItemAtPosition(0)
	}
	
	public var last: PlayerQueueItem? {
		return getItemAtPosition(itemsSet.count - 1)
	}
	
	public var currentItems: [PlayerQueueItem] {
		return itemsSet.map { PlayerQueueItem(queue: self, playerItem: $0 as! StreamAudioItem) }
	}
	
	public var count: Int {
		return itemsSet.count
	}
	
	public init(repeatQueue: Bool = false) {
		self.repeatQueue = repeatQueue
	}
	
	public convenience init(items: [StreamAudioItem], shuffle: Bool = false, repeatQueue: Bool = false) {
		self.init(repeatQueue: repeatQueue)
		
		initWithNewItems(items, shuffle: shuffle)
	}
	
	public func initWithNewItems(items: [StreamAudioItem], shuffle: Bool = false) {
		itemsSet.removeAllObjects()
		current = nil
		if shuffle {
			itemsSet.addObjectsFromArray(items.shuffle())
		} else {
			itemsSet.addObjectsFromArray(items)
		}
	}
	
	public func shuffle() {
		var items = itemsSet.array
		items.shuffleInPlace()
		itemsSet = NSMutableOrderedSet(array: items)
	}
	
	public func toNext() -> PlayerQueueItem? {
		if current == nil {
			current = first
		} else {
			current = repeatQueue ? current?.child ?? first : current?.child
		}
		return current
	}
	
	public func toPrevious() -> PlayerQueueItem? {
		if current == nil {
			current = first
		} else if current != first {
			current = current?.parent
		}
		return current
	}
	
	public func remove(item: StreamAudioItem) {
		itemsSet.removeObject(item)
	}
	
	public func remove(item: PlayerQueueItem) {
		remove(item.streamItem)
	}
	
	public func getItemAtPosition(position: Int) -> PlayerQueueItem? {
		guard let item: StreamAudioItem = itemsSet.getObjectAtIndex(position) else { return nil }
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
	/// If item already exists, set item at specified index and return PlayerQueueItem with this item
	private func add(item: StreamAudioItem, index: Int) -> PlayerQueueItem {
		var addAtIndex = index
		if let currentIndex = itemsSet.getIndexOfObject(item) {
			if currentIndex == index {
				return PlayerQueueItem(queue: self, playerItem: item)
			} else {
				itemsSet.removeObject(item)
				if addAtIndex > 0 { addAtIndex -= 1 }
			}
		}
		
		if 0..<itemsSet.count + 1 ~= index {
			itemsSet.insertObject(item, atIndex: addAtIndex)
		} else {
			itemsSet.addObject(item)
		}
		
		return PlayerQueueItem(queue: self, playerItem: item)
	}
}

public class PlayerQueueItem {
	public var parent: PlayerQueueItem? {
		return queue.getItemBefore(streamItem)
	}
	public var child: PlayerQueueItem? {
		return queue.getItemAfter(streamItem)
	}
	public let streamItem: StreamAudioItem
	public let queue: PlayerQueue
	public var inQueue: Bool {
		return queue.itemsSet.indexOfObject(streamItem) != NSNotFound
	}
	
	public init(queue: PlayerQueue, playerItem: StreamAudioItem) {
		self.queue = queue
		self.streamItem = playerItem
	}
	
	deinit {
		print("PlayerQueueItem deinit")
	}
}

public func ==(lhs: PlayerQueueItem, rhs: PlayerQueueItem) -> Bool {
	return lhs.hashValue == rhs.hashValue
}

extension PlayerQueueItem : Hashable {
	public var hashValue: Int {
		return streamItem.hashValue
	}
}