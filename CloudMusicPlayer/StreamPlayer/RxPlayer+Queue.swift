//
//  RxPlayerQueue.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 08.04.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import RxSwift

extension RxPlayer {
	public var first: RxPlayerQueueItem? {
		return getItemAtPosition(0)
	}
	
	public var last: RxPlayerQueueItem? {
		return getItemAtPosition(itemsSet.count - 1)
	}
	
	public var currentItems: [RxPlayerQueueItem] {
		return itemsSet.map { RxPlayerQueueItem(player: self, streamIdentifier: $0 as! StreamResourceIdentifier) }
	}
	
	public var count: Int {
		return itemsSet.count
	}

	public convenience init(items: [StreamResourceIdentifier], shuffle: Bool = false, repeatQueue: Bool = false) {
		self.init(repeatQueue: repeatQueue)
		
		initWithNewItems(items, shuffle: shuffle)
	}
	
	public func initWithNewItems(items: [StreamResourceIdentifier], shuffle: Bool = false) {
		itemsSet.removeAllObjects()
		
		current = nil
		if shuffle {
			itemsSet.addObjectsFromArray(items.map { $0 as! AnyObject }.shuffle())
		} else {
			itemsSet.addObjectsFromArray(items.map { $0 as! AnyObject })
		}
		queueEventsSubject.onNext(.InitWithNewItems(currentItems))
	}
	
	public func shuffle() {
		var items = itemsSet.array
		items.shuffleInPlace()
		itemsSet = NSMutableOrderedSet(array: items)
		queueEventsSubject.onNext(.Shuflle(currentItems))
	}
	
	public func toNext() -> RxPlayerQueueItem? {
		if current == nil {
			current = first
		} else {
			current = repeatQueue ? current?.child ?? first : current?.child
		}
		return current
	}
	
	public func toPrevious() -> RxPlayerQueueItem? {
		if current == nil {
			current = first
		} else if current != first {
			current = current?.parent
		}
		return current
	}
	
	public func remove(item: StreamResourceIdentifier) {
		guard let index = itemsSet.getIndexOfObject(item as! AnyObject) else { return }
		itemsSet.removeObjectAtIndex(index)
		queueEventsSubject.onNext(.RemoveItem(RxPlayerQueueItem(player: self, streamIdentifier: item)))
	}
	
	public func remove(item: RxPlayerQueueItem) {
		remove(item.streamIdentifier)
	}
	
	public func getItemAtPosition(position: Int) -> RxPlayerQueueItem? {
		guard let item: StreamResourceIdentifier = itemsSet.getObjectAtIndex(position) else { return nil }
		return RxPlayerQueueItem(player: self, streamIdentifier: item)
	}
	
	public func getItemAfter(item: StreamResourceIdentifier) -> RxPlayerQueueItem? {
		let index = itemsSet.indexOfObject(item as! AnyObject)
		return getItemAtPosition(index + 1)
	}
	
	public func getItemBefore(item: StreamResourceIdentifier) -> RxPlayerQueueItem? {
		let index = itemsSet.indexOfObject(item as! AnyObject)
		return getItemAtPosition(index - 1)
	}
	
	public func addLast(item: StreamResourceIdentifier) -> RxPlayerQueueItem {
		return add(item, index: itemsSet.count)
	}
	
	public func addFirst(item: StreamResourceIdentifier) -> RxPlayerQueueItem {
		return add(item, index: 0)
	}
	
	/// Add item in queue after specified item.
	/// If specified item doesn't exist, add to end
	public func addAfter(itemToAdd: StreamResourceIdentifier, afterItem: StreamResourceIdentifier) -> RxPlayerQueueItem {
		let index = itemsSet.getIndexOfObject(afterItem as! AnyObject) ?? itemsSet.count
		return add(itemToAdd, index: index + 1)
	}
	
	/// Add item in queue.
	/// Return instance of RxPlayerQueueItem if item was added.
	/// If item already exists, set item at specified index and return RxPlayerQueueItem with this item
	private func add(item: StreamResourceIdentifier, index: Int) -> RxPlayerQueueItem {
		var addAtIndex = index
		var isItemRemoved = false
		if let currentIndex = itemsSet.getIndexOfObject(item as! AnyObject) {
			if currentIndex == index {
				return RxPlayerQueueItem(player: self, streamIdentifier: item)
			} else {
				itemsSet.removeObject(item as! AnyObject)
				if addAtIndex > 0 { addAtIndex -= 1 }
				isItemRemoved = true
			}
		}
		
		if 0..<itemsSet.count + 1 ~= index {
			itemsSet.insertObject(item as! AnyObject, atIndex: addAtIndex)
		} else {
			itemsSet.addObject(item as! AnyObject)
		}
		
		let queueItem = RxPlayerQueueItem(player: self, streamIdentifier: item)
		
		if isItemRemoved {
			queueEventsSubject.onNext(.ChangeItemsOrder(self))
		} else {
			queueEventsSubject.onNext(.AddNewItem(queueItem))
		}
		
		return queueItem
	}
}

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