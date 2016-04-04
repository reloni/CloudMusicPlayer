//
//  PlayerQueueTests.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 29.03.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import XCTest
import RxSwift
@testable import CloudMusicPlayer

class PlayerQueueTests: XCTestCase {
	var player: StreamAudioPlayer!
	var audioItems: [StreamAudioItem]!
	var bag: DisposeBag!
	
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
		player = StreamAudioPlayer()
		audioItems = [StreamAudioItem(cacheItem: FakeCacheItem(resourceIdeitifier: "fake one", task: nil), player: player),
		             StreamAudioItem(cacheItem: FakeCacheItem(resourceIdeitifier: "fake two", task: nil), player: player),
		             StreamAudioItem(cacheItem: FakeCacheItem(resourceIdeitifier: "fake three", task: nil), player: player),
		             StreamAudioItem(cacheItem: FakeCacheItem(resourceIdeitifier: "fake four", task: nil), player: player)]
		bag = DisposeBag()
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
		
		bag = nil
	}
	
	func testCreateEmptyQueue() {
		let queue = PlayerQueue()
		XCTAssertNil(queue.current, "Current item should be nil")
		XCTAssertNil(queue.first, "First item should be nil")
		XCTAssertNil(queue.last, "Last item should be nil")
		XCTAssertEqual(0, queue.count, "Queue should not have any items")
	}
	
	func testCreateQueueWithCorrectItems() {
		let queue = PlayerQueue(items: audioItems)
		XCTAssertEqual(audioItems.count, queue.currentItems.count, "Should create queue with correct count of items")
		XCTAssertEqual(audioItems, queue.currentItems.map { $0.streamItem }, "Check initial array and array in queue are equal")
		XCTAssertEqual(0, queue.currentItems.filter { !$0.inQueue }.count, "All items should have property inQueue in true state")
		XCTAssertEqual(audioItems[0], queue.first?.streamItem, "Check first item in queue")
		XCTAssertEqual(audioItems[0], queue.getItemAtPosition(0)?.streamItem, "Check first item in queue by index")
		XCTAssertNil(queue.first?.parent, "First item in queue should not have a parent item")
		XCTAssertEqual(audioItems[1], queue.first?.child?.streamItem, "Check second item in queue")
		XCTAssertEqual(audioItems[0], queue.first?.child?.parent?.streamItem, "Second item should have first as parent")
		XCTAssertEqual(audioItems[2], queue.first?.child?.child?.streamItem, "Check third item in queue")
		XCTAssertEqual(audioItems[1], queue.first?.child?.child?.parent?.streamItem, "Third item should have second as parent")
		XCTAssertEqual(audioItems[3], queue.first?.child?.child?.child?.streamItem, "Check fourth item in queue")
		XCTAssertEqual(audioItems[2], queue.first?.child?.child?.child?.parent?.streamItem, "Fourth item should have third as parent")
		XCTAssertNil(queue.first?.child?.child?.child?.child, "Fourth item should not have child item")
		XCTAssertNil(queue.current, "Current item in queue should be nil")
		XCTAssertEqual(audioItems[3], queue.last?.streamItem, "Check last item in queue")
	}
	
	func testCreateShuffledQueueWithCorrectItems() {
		let queue = PlayerQueue(items: audioItems, shuffle: true)
		XCTAssertNotEqual(audioItems, queue.currentItems.map { $0.streamItem }, "Queue should have collection of shuffled items")
	}
	
	func testShuffleQueueWithItems() {
		let queue = PlayerQueue(items: audioItems)
		
		var itemsFromEvent: [PlayerQueueItem]?
		queue.queueEvents.bindNext { result in
			if case PlayerQueueEvents.Shuflle(let newItems) = result {
				itemsFromEvent = newItems
			}
		}.addDisposableTo(bag)
		
		queue.shuffle()
		XCTAssertNotEqual(audioItems, queue.currentItems.map { $0.streamItem }, "Queue should be shuffled")
		if let itemsFromEvent = itemsFromEvent {
			XCTAssertEqual(itemsFromEvent, queue.currentItems, "Check Shuffle event return correct items")
		} else {
			XCTFail("Shuffle event should be rised")
		}
	}
	
	func testInitWithNewItems() {
		let queue = PlayerQueue(items: audioItems)
		let newItems = [audioItems[0], audioItems[1]]
		
		var itemsFromEvent: [PlayerQueueItem]?
		// init current item with value
		var currentItem: PlayerQueueItem? = PlayerQueueItem(queue: queue, playerItem: audioItems[0])
		queue.queueEvents.bindNext { result in
			if case PlayerQueueEvents.InitWithNewItems(let newItems) = result {
				itemsFromEvent = newItems
			} else if case PlayerQueueEvents.CurrentItemChanged(let current) = result {
				currentItem = current
			}
		}.addDisposableTo(bag)
		
		queue.initWithNewItems(newItems)
		XCTAssertEqual(newItems, queue.currentItems.map { $0.streamItem }, "Queue should have correct two items")
		if let itemsFromEvent = itemsFromEvent {
			XCTAssertEqual(itemsFromEvent, queue.currentItems, "Check InitWithNewItems event return correct items")
		} else {
			XCTFail("InitWithNewItems event should be rised")
		}
		XCTAssertNil(currentItem, "Check CurrentItemChanged was rised and send nil as current item")
	}
	
	func testResetCurrentItemAfterInitWithNewItems() {
		let queue = PlayerQueue(items: audioItems)
		queue.toNext()
		let newItems = [audioItems[0], audioItems[1]]
		queue.initWithNewItems(newItems)
		XCTAssertNil(queue.current, "Current property should be nil")
	}
	
	func testAddItemsToQueue() {
		let queue = PlayerQueue()
		
		var addedItem: PlayerQueueItem?
		queue.queueEvents.bindNext { result in
			if case PlayerQueueEvents.AddNewItem(let newItem) = result {
				addedItem = newItem
			}
		}.addDisposableTo(bag)
		
		// add first item
		let firstAddedtem = queue.addFirst(audioItems[0])
		XCTAssertEqual(firstAddedtem.streamItem, audioItems[0], "Check correct first item returned by method")
		XCTAssertEqual(1, queue.currentItems.count, "Check correct count in queue")
		XCTAssertEqual(firstAddedtem, queue.first, "Check added item is first in queue")
		XCTAssertEqual(firstAddedtem, queue.last, "Check added item is last in queue")
		XCTAssertNil(queue.last?.child, "Check last item in queue don't have child")
		XCTAssertNil(queue.first?.parent, "Check first item in queue don't have parent")
		if let addedItem = addedItem {
			XCTAssertEqual(addedItem.streamItem, firstAddedtem.streamItem, "Check event return correct new item")
		} else {
			XCTFail("Event AddNewItem should be rised")
		}
		
		// add second item at first place
		let secondAddedItem = queue.addFirst(audioItems[1])
		XCTAssertEqual(audioItems[1], secondAddedItem.streamItem, "Check correct second item returned by method")
		XCTAssertEqual(2, queue.currentItems.count, "Check correct count in queue")
		XCTAssertEqual(secondAddedItem, queue.first, "Check second added item is first in queue")
		XCTAssertEqual(firstAddedtem, queue.last, "Check first added item still last in queue")
		XCTAssertEqual(firstAddedtem.parent, secondAddedItem, "Check second item has first as a parent")
		XCTAssertNil(queue.last?.child, "Check last item in queue don't have child")
		XCTAssertNil(queue.first?.parent, "Check first item in queue don't have parent")
		if let addedItem = addedItem {
			XCTAssertEqual(addedItem.streamItem, secondAddedItem.streamItem, "Check event return correct new item")
		} else {
			XCTFail("Event AddNewItem should be rised")
		}
		
		// add third item at the end
		let thirdAddedItem = queue.addLast(audioItems[2])
		XCTAssertEqual(audioItems[2], thirdAddedItem.streamItem, "Check correct third item returned by method")
		XCTAssertEqual(3, queue.currentItems.count, "Check correct count in queue")
		XCTAssertEqual(thirdAddedItem, queue.last, "Check third added item is last in queue")
		XCTAssertEqual(secondAddedItem, queue.first, "Check second added item is still first in queue")
		XCTAssertNil(queue.last?.child, "Check last item in queue don't have child")
		XCTAssertNil(queue.first?.parent, "Check first item in queue don't have parent")
		if let addedItem = addedItem {
			XCTAssertEqual(addedItem.streamItem, thirdAddedItem.streamItem, "Check event return correct new item")
		} else {
			XCTFail("Event AddNewItem should be rised")
		}
		
		// add fourth item at third place
		let fourthAddedItem = queue.addAfter(audioItems[3], afterItem: firstAddedtem.streamItem)
		XCTAssertEqual(audioItems[3], fourthAddedItem.streamItem, "Check correct fourth item returned by method")
		XCTAssertEqual(4, queue.currentItems.count, "Check correct count in queue")
		XCTAssertNil(queue.last?.child, "Check last item in queue don't have child")
		XCTAssertNil(queue.first?.parent, "Check first item in queue don't have parent")
		if let addedItem = addedItem {
			XCTAssertEqual(addedItem.streamItem, fourthAddedItem.streamItem, "Check event return correct new item")
		} else {
			XCTFail("Event AddNewItem should be rised")
		}
		
		// check items chain
		XCTAssertEqual(queue.first, secondAddedItem, "Second added item should be first")
		XCTAssertEqual(queue.first?.child, firstAddedtem, "First added item should be second")
		XCTAssertEqual(queue.first?.child?.child, fourthAddedItem, "Fourth added item should be third")
		XCTAssertEqual(queue.first?.child?.child?.child, thirdAddedItem, "Third added item should be fourth")
	}
	
	func testNotAddExistedItemToQueue() {
		let queue = PlayerQueue(items: audioItems)
		
		queue.queueEvents.bindNext { result in
			if case PlayerQueueEvents.AddNewItem = result {
				XCTFail("Event AddNewItem should not be rised")
			}
		}.addDisposableTo(bag)
		
		let addedItem = queue.addLast(audioItems[1])
		XCTAssertEqual(audioItems.count, queue.count, "Check items count not changed")
		XCTAssertEqual(addedItem.streamItem, audioItems[1], "Check method return correct item (that was already in queue")
	}
	
	func testCorrectChangeOrderOfItems() {
		let queue = PlayerQueue(items: audioItems)
		guard let second = queue.getItemAtPosition(1), third = queue.getItemAtPosition(2) else {
			XCTFail("Should return items at indeces 1 and 2")
			return
		}
		
		var queueFromEvent: PlayerQueue?
		queue.queueEvents.bindNext { result in
			if case PlayerQueueEvents.ChangeItemsOrder(let resultQueue) = result {
				queueFromEvent = resultQueue
			} else if case PlayerQueueEvents.AddNewItem = result {
				XCTFail("Event AddNewItem should not be rised")
			}
		}.addDisposableTo(bag)
		
		// swap items
		var swapped = queue.addAfter(second.streamItem, afterItem: third.streamItem)
		//print(queue.currentItems.map { $0.playerItem })
		XCTAssertEqual(second.streamItem, swapped.streamItem, "Method addAfter should return correct item")
		XCTAssertEqual(audioItems[0], queue.getItemAtPosition(0)?.streamItem, "First item should be at same place")
		XCTAssertEqual(audioItems[1], queue.getItemAtPosition(2)?.streamItem, "Second item should be now third")
		XCTAssertEqual(audioItems[2], queue.getItemAtPosition(1)?.streamItem, "Third item should now be second")
		XCTAssertEqual(audioItems[3], queue.getItemAtPosition(3)?.streamItem, "Last item should be at same place")
		XCTAssertTrue(queueFromEvent === queue, "Check ChangeItemsOrder event was rised and send correct instance of queue")
		
		queueFromEvent = nil
		guard let first	= queue.first, last = queue.last else {
			XCTFail("Should return first and last items")
			return
		}
		
		// move first item to the end
		swapped = queue.addAfter(first.streamItem, afterItem: last.streamItem)
		XCTAssertEqual(first.streamItem, swapped.streamItem, "Method addAfter should return correct item")
		XCTAssertEqual(audioItems[0], queue.getItemAtPosition(3)?.streamItem, "First item should be now fourth (last)")
		XCTAssertEqual(audioItems[1], queue.getItemAtPosition(1)?.streamItem, "Second item should be now second (again)")
		XCTAssertEqual(audioItems[2], queue.getItemAtPosition(0)?.streamItem, "Third item should now be first")
		XCTAssertEqual(audioItems[3], queue.getItemAtPosition(2)?.streamItem, "Fourt item should be now third")
		XCTAssertTrue(queueFromEvent === queue, "Check ChangeItemsOrder event was rised and send correct instance of queue")
	}
	
	func testCorrectMoveExistedItemToBeginningOfQueue() {
		let queue = PlayerQueue(items: audioItems)
		guard let third = queue.getItemAtPosition(2) else {
			XCTFail("Should return item at 2 index")
			return
		}
		
		var queueFromEvent: PlayerQueue?
		queue.queueEvents.bindNext { result in
			if case PlayerQueueEvents.ChangeItemsOrder(let resultQueue) = result {
				queueFromEvent = resultQueue
			} else if case PlayerQueueEvents.AddNewItem = result {
				XCTFail("Event AddNewItem should not be rised")
			}
		}.addDisposableTo(bag)
		
		let swapped = queue.addFirst(third.streamItem)
		XCTAssertEqual(third.streamItem, swapped.streamItem, "Method addAfter should return correct item")
		XCTAssertEqual(audioItems[2], queue.first?.streamItem, "Third item should now be first")
		XCTAssertEqual(audioItems[0], queue.getItemAtPosition(1)?.streamItem, "First item should now be second")
		XCTAssertTrue(queueFromEvent === queue, "Check ChangeItemsOrder event was rised and send correct instance of queue")
	}
	
	func testCorrectMoveExistedItemToTheEndOfQueue() {
		let queue = PlayerQueue(items: audioItems)
		guard let second = queue.getItemAtPosition(1) else {
			XCTFail("Should return item at 1 index")
			return
		}
		
		var queueFromEvent: PlayerQueue?
		queue.queueEvents.bindNext { result in
			if case PlayerQueueEvents.ChangeItemsOrder(let resultQueue) = result {
				queueFromEvent = resultQueue
			} else if case PlayerQueueEvents.AddNewItem = result {
				XCTFail("Event AddNewItem should not be rised")
			}
		}.addDisposableTo(bag)
		
		let swapped = queue.addLast(second.streamItem)
		XCTAssertEqual(second.streamItem, swapped.streamItem, "Method addAfter should return correct item")
		XCTAssertEqual(audioItems[1], queue.last?.streamItem, "Second item should now be last")
		XCTAssertEqual(audioItems[3], queue.getItemAtPosition(2)?.streamItem, "Fourth item should now be third")
		XCTAssertTrue(queueFromEvent === queue, "Check ChangeItemsOrder event was rised and send correct instance of queue")
	}
	
	func testToNext() {
		let queue = PlayerQueue(items: audioItems)
		// now current item is nil, should set first item as current
		var next = queue.toNext()
		XCTAssertNotNil(queue.current)
		XCTAssertEqual(next, queue.current)
		XCTAssertEqual(next?.streamItem, audioItems[0])
		
		next = queue.toNext()
		XCTAssertNotNil(queue.current)
		XCTAssertEqual(next, queue.current)
		XCTAssertEqual(next?.streamItem, audioItems[1])
	}
	
	func testToPrevious() {
		let queue = PlayerQueue(items: audioItems)
		// set second item as current
		queue.current = PlayerQueueItem(queue: queue, playerItem: audioItems[1])
		var next = queue.toPrevious()
		XCTAssertNotNil(queue.current)
		XCTAssertEqual(next, queue.current)
		XCTAssertEqual(next?.streamItem, audioItems[0])
		
		// call toPrevious one more time
		// should remain on first item
		next = queue.toPrevious()
		XCTAssertNotNil(queue.current)
		XCTAssertEqual(next, queue.current)
		XCTAssertEqual(next?.streamItem, audioItems[0])
	}
	
	func testToPreviousSetFistItemAsCurrentIfCurrentIsNil() {
		let queue = PlayerQueue(items: audioItems)
		
		var newCurrent: PlayerQueueItem?
		queue.queueEvents.bindNext { result in
			if case PlayerQueueEvents.CurrentItemChanged(let item) = result {
				newCurrent = item
			}
		}.addDisposableTo(bag)
		
		let next = queue.toPrevious()
		XCTAssertNotNil(queue.current, "Check current property is not nil")
		XCTAssertEqual(next, queue.current, "Check toPrevious return correct current item")
		XCTAssertEqual(next?.streamItem, queue.first?.streamItem, "Check current item is first in queue")
		XCTAssertEqual(newCurrent?.streamItem, queue.first?.streamItem, "Check event return correct current item")
	}
	
	func testToNextOnLastItemSetCurrentToNil() {
		let queue = PlayerQueue(items: audioItems)
		// set curent item to last
		queue.current = PlayerQueueItem(queue: queue, playerItem: audioItems.last!)
		
		// init new current with value
		var newCurrent: PlayerQueueItem? = queue.current
		queue.queueEvents.bindNext { result in
			if case PlayerQueueEvents.CurrentItemChanged(let item) = result {
				newCurrent = item
			}
		}.addDisposableTo(bag)
		
		let next = queue.toNext()
		
		XCTAssertNil(queue.current, "Current property in queue should be nil")
		XCTAssertNil(next, "Check toNext return nil as current item")
		XCTAssertNil(newCurrent, "Check event return nil as current item")
	}
	
	func testToNextOnLastItemSetCurrentToFirstWhenRepeatQueueIsTrue() {
		let queue = PlayerQueue(items: audioItems, shuffle: false, repeatQueue: true)
		// set curent item to last
		queue.current = PlayerQueueItem(queue: queue, playerItem: audioItems.last!)
		
		var newCurrent: PlayerQueueItem?
		queue.queueEvents.bindNext { result in
			if case PlayerQueueEvents.CurrentItemChanged(let item) = result {
				newCurrent = item
			}
		}.addDisposableTo(bag)
		
		let next = queue.toNext()
		XCTAssertNotNil(queue.current, "Check current is not nill")
		XCTAssertEqual(next, queue.current, "Check toNext return correct current item")
		XCTAssertEqual(next?.streamItem, queue.first?.streamItem, "Check current item is first")
		XCTAssertEqual(newCurrent?.streamItem, audioItems[0], "Check event return correct current item")
	}
	
	func testRemoveItem() {
		let queue = PlayerQueue(items: audioItems)
		let itemToRemove = PlayerQueueItem(queue: queue, playerItem: audioItems[1])
		
		var removedItem: PlayerQueueItem?
		queue.queueEvents.bindNext { result in
			if case PlayerQueueEvents.RemoveItem(let item) = result {
				removedItem = item
			} else if case PlayerQueueEvents.ChangeItemsOrder = result {
				XCTFail("Change item order should not be rised")
			}
		}.addDisposableTo(bag)
		
		queue.remove(itemToRemove)
		XCTAssertEqual(3, queue.count, "Check items count changed")
		XCTAssertEqual(0, queue.currentItems.filter { $0.streamItem == audioItems[1] }.count, "Check item actually removed from current queue items")
		XCTAssertFalse(itemToRemove.inQueue, "Check removed item now has status inQueue == false")
		XCTAssertEqual(removedItem?.streamItem, itemToRemove.streamItem, "Check event rised with correct removed item")
	}
	
	func testNotRemoveItemThatNotExistsInQueue() {
		let queue = PlayerQueue(items: audioItems)
		let notExisted = PlayerQueueItem(queue: queue,
										playerItem: StreamAudioItem(cacheItem: FakeCacheItem(resourceIdeitifier: "fake five", task: nil), player: player))
		
		queue.queueEvents.bindNext { result in
			if case PlayerQueueEvents.RemoveItem = result {
				XCTFail("Should not rise this event, because we try to delete item not existed in queue")
			}
		}.addDisposableTo(bag)
		
		queue.remove(notExisted)
		XCTAssertEqual(4, queue.count)
	}
	
	func testChangeRepeat() {
		let queue = PlayerQueue(items: audioItems, shuffle: false, repeatQueue: false)
		XCTAssertFalse(queue.repeatQueue, "RepeatQueue should be false")
		
		var eventValue: Bool?
		queue.queueEvents.bindNext { result in
			if case PlayerQueueEvents.RepeatChanged(let newVal) = result {
				eventValue = newVal
			}
		}.addDisposableTo(bag)
		
		queue.repeatQueue = true
		
		XCTAssertEqual(true, eventValue, "Check queue rised event wih correct new value")
		XCTAssertTrue(queue.repeatQueue, "RepeatQueue should be true")
	}
}
