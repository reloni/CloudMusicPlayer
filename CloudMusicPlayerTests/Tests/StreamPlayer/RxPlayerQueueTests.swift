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

class RxPlayerQueueTests: XCTestCase {
	//var player: RxPlayer!
	var audioItems: [StreamResourceIdentifier]!
	var bag = DisposeBag()
	
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
		//player = RxPlayer()
		audioItems = ["http://item1.com", "http://item2.com", "http://item3.com", "http://item4.com"]
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
		
		//bag = nil
	}
	
	func testCreateEmptyQueue() {
		let queue = RxPlayer()
		XCTAssertNil(queue.current, "Current item should be nil")
		XCTAssertNil(queue.first, "First item should be nil")
		XCTAssertNil(queue.last, "Last item should be nil")
		XCTAssertEqual(0, queue.count, "Queue should not have any items")
	}
	
	func testCreateQueueWithCorrectItems() {
		let queue = RxPlayer(items: audioItems)
		XCTAssertEqual(audioItems.count, queue.currentItems.count, "Should create queue with correct count of items")
		XCTAssertEqual(audioItems.map { $0 as! String }, queue.currentItems.map { $0.streamIdentifier as! String }, "Check initial array and array in queue are equal")
		XCTAssertEqual(0, queue.currentItems.filter { !$0.inQueue }.count, "All items should have property inQueue in true state")
		XCTAssertEqual(audioItems[0].streamResourceUid, queue.first?.streamIdentifier.streamResourceUid, "Check first item in queue")
		XCTAssertEqual(audioItems[0].streamResourceUid, queue.getItemAtPosition(0)?.streamIdentifier.streamResourceUid, "Check first item in queue by index")
		XCTAssertNil(queue.first?.parent, "First item in queue should not have a parent item")
		XCTAssertEqual(audioItems[1].streamResourceUid, queue.first?.child?.streamIdentifier.streamResourceUid, "Check second item in queue")
		XCTAssertEqual(audioItems[0].streamResourceUid, queue.first?.child?.parent?.streamIdentifier.streamResourceUid, "Second item should have first as parent")
		XCTAssertEqual(audioItems[2].streamResourceUid, queue.first?.child?.child?.streamIdentifier.streamResourceUid, "Check third item in queue")
		XCTAssertEqual(audioItems[1].streamResourceUid, queue.first?.child?.child?.parent?.streamIdentifier.streamResourceUid, "Third item should have second as parent")
		XCTAssertEqual(audioItems[3].streamResourceUid, queue.first?.child?.child?.child?.streamIdentifier.streamResourceUid, "Check fourth item in queue")
		XCTAssertEqual(audioItems[2].streamResourceUid, queue.first?.child?.child?.child?.parent?.streamIdentifier.streamResourceUid, "Fourth item should have third as parent")
		XCTAssertNil(queue.first?.child?.child?.child?.child, "Fourth item should not have child item")
		XCTAssertNil(queue.current, "Current item in queue should be nil")
		XCTAssertEqual(audioItems[3].streamResourceUid, queue.last?.streamIdentifier.streamResourceUid, "Check last item in queue")
	}
	
	func testCreateShuffledQueueWithCorrectItems() {
		let queue = RxPlayer(items: audioItems, shuffle: true)
		XCTAssertNotEqual(audioItems.map { $0 as! String }, queue.currentItems.map { $0.streamIdentifier as! String }, "Queue should have collection of shuffled items")
	}
	
	func testShuffleQueueWithItems() {
		let queue = RxPlayer(items: audioItems)
		
		let expectation = expectationWithDescription("Should rise event")
		
		var itemsFromEvent: [RxPlayerQueueItem]?
		queue.playerEvents.bindNext { result in
			if case PlayerEvents.Shuflle(let newItems) = result {
				itemsFromEvent = newItems
				expectation.fulfill()
			}
			}.addDisposableTo(bag)
		
		queue.shuffle()
		
		waitForExpectationsWithTimeout(1, handler: nil)
		
		XCTAssertNotEqual(audioItems.map { $0 as! String }, queue.currentItems.map { $0.streamIdentifier as! String }, "Queue should be shuffled")
		if let itemsFromEvent = itemsFromEvent {
			XCTAssertEqual(itemsFromEvent, queue.currentItems, "Check Shuffle event return correct items")
		} else {
			XCTFail("Shuffle event should be rised")
		}
	}
	
	func testSetCurrentItemToNilAfterShuffle() {
		let queue = RxPlayer(items: audioItems)
		queue.toNext()
		XCTAssertNotNil(queue.current, "Current item should not be nil")
		queue.shuffle()
		XCTAssertNil(queue.current, "Current item should be nil after shuffle")
	}
	
	func testShuffleQueueAndForceSetNewCurrentItem() {
		let queue = RxPlayer(items: audioItems)
		queue.toNext()
		XCTAssertNotNil(queue.current, "Current item should not be nil")
		queue.shuffle(true)
		XCTAssertEqual(queue.first?.streamIdentifier.streamResourceUid, queue.current?.streamIdentifier.streamResourceUid,
		               "Should set correct current item")
	}
	
	func testShuffleAndPreserveCurrentItem() {
		let queue = RxPlayer(items: audioItems)
		queue.current = queue.getItemAtPosition(1)
		let cur = queue.current
		XCTAssertNotNil(queue.current, "Current item should not be nil")
		queue.shuffleAndContinue()
		XCTAssertEqual(cur?.streamIdentifier.streamResourceUid, queue.current?.streamIdentifier.streamResourceUid)
	}
	
	func testInitWithNewItems() {
		let queue = RxPlayer(items: audioItems)
		queue.toNext()
		let newItems = [audioItems[0], audioItems[1]]
		
		let initExpectation = expectationWithDescription("Should rise event")
		let currentItemExpectation = expectationWithDescription("Should rise event")
		
		var itemsFromEvent: [RxPlayerQueueItem]?
		// init current item with value
		var currentItem: RxPlayerQueueItem? = RxPlayerQueueItem(player: queue, streamIdentifier: audioItems[0])
		queue.playerEvents.bindNext { result in
			if case PlayerEvents.InitWithNewItems(let newItems) = result {
				itemsFromEvent = newItems
				initExpectation.fulfill()
			} else if case PlayerEvents.CurrentItemChanged(let current) = result {
				currentItem = current
				currentItemExpectation.fulfill()
			}
			}.addDisposableTo(bag)
		
		queue.initWithNewItems(newItems)
		
		waitForExpectationsWithTimeout(1, handler: nil)
		
		XCTAssertEqual(newItems.map { $0 as! String }, queue.currentItems.map { $0.streamIdentifier as! String }, "Queue should have correct two items")
		if let itemsFromEvent = itemsFromEvent {
			XCTAssertEqual(itemsFromEvent, queue.currentItems, "Check InitWithNewItems event return correct items")
		} else {
			XCTFail("InitWithNewItems event should be rised")
		}
		XCTAssertNil(currentItem, "Check CurrentItemChanged was rised and send nil as current item")
	}
	
	func testInitWithShuffledNewItemsIfShuffleQueueIsTrue() {
		let queue = RxPlayer()
		// set default shuffle as true
		queue.shuffleQueue = true
		queue.initWithNewItems(audioItems)
		XCTAssertNotEqual(audioItems.map { $0.streamResourceUid }, queue.currentItems.map { $0.streamIdentifier.streamResourceUid }, "Queue should has shuffled items")
	}
	
	func testResetCurrentItemAfterInitWithNewItems() {
		let queue = RxPlayer(items: audioItems)
		queue.toNext()
		let newItems = [audioItems[0], audioItems[1]]
		queue.initWithNewItems(newItems)
		XCTAssertNil(queue.current, "Current property should be nil")
	}
	
	func testAddItemsToQueue() {
		let queue = RxPlayer()
		
		var eventExpectation: XCTestExpectation? = expectationWithDescription("Should rise AddNewItem event")
		
		var addedItem: RxPlayerQueueItem?
		queue.playerEvents.bindNext { result in
			if case PlayerEvents.AddNewItem(let newItem) = result {
				addedItem = newItem
				eventExpectation?.fulfill()
			}
		}.addDisposableTo(bag)
		
		// add first item
		let firstAddedtem = queue.addFirst(audioItems[0])
		waitForExpectationsWithTimeout(1, handler: nil)
		
		XCTAssertEqual(firstAddedtem.streamIdentifier.streamResourceUid, audioItems[0].streamResourceUid, "Check correct first item returned by method")
		XCTAssertEqual(1, queue.currentItems.count, "Check correct count in queue")
		XCTAssertEqual(firstAddedtem, queue.first, "Check added item is first in queue")
		XCTAssertEqual(firstAddedtem, queue.last, "Check added item is last in queue")
		XCTAssertNil(queue.last?.child, "Check last item in queue don't have child")
		XCTAssertNil(queue.first?.parent, "Check first item in queue don't have parent")
		if let addedItem = addedItem {
			XCTAssertEqual(addedItem.streamIdentifier.streamResourceUid, firstAddedtem.streamIdentifier.streamResourceUid, "Check event return correct new item")
		} else {
			XCTFail("Event AddNewItem should be rised")
		}
		
		eventExpectation = expectationWithDescription("Should rise AddNewItem event")
		// add second item at first place
		let secondAddedItem = queue.addFirst(audioItems[1])
		waitForExpectationsWithTimeout(1, handler: nil)
		
		XCTAssertEqual(audioItems[1].streamResourceUid, secondAddedItem.streamIdentifier.streamResourceUid, "Check correct second item returned by method")
		XCTAssertEqual(2, queue.currentItems.count, "Check correct count in queue")
		XCTAssertEqual(secondAddedItem, queue.first, "Check second added item is first in queue")
		XCTAssertEqual(firstAddedtem, queue.last, "Check first added item still last in queue")
		XCTAssertEqual(firstAddedtem.parent, secondAddedItem, "Check second item has first as a parent")
		XCTAssertNil(queue.last?.child, "Check last item in queue don't have child")
		XCTAssertNil(queue.first?.parent, "Check first item in queue don't have parent")
		if let addedItem = addedItem {
			XCTAssertEqual(addedItem.streamIdentifier.streamResourceUid, secondAddedItem.streamIdentifier.streamResourceUid, "Check event return correct new item")
		} else {
			XCTFail("Event AddNewItem should be rised")
		}
		
		eventExpectation = expectationWithDescription("Should rise AddNewItem event")
		// add third item at the end
		let thirdAddedItem = queue.addLast(audioItems[2])
		waitForExpectationsWithTimeout(1, handler: nil)
		
		XCTAssertEqual(audioItems[2].streamResourceUid, thirdAddedItem.streamIdentifier.streamResourceUid, "Check correct third item returned by method")
		XCTAssertEqual(3, queue.currentItems.count, "Check correct count in queue")
		XCTAssertEqual(thirdAddedItem, queue.last, "Check third added item is last in queue")
		XCTAssertEqual(secondAddedItem, queue.first, "Check second added item is still first in queue")
		XCTAssertNil(queue.last?.child, "Check last item in queue don't have child")
		XCTAssertNil(queue.first?.parent, "Check first item in queue don't have parent")
		if let addedItem = addedItem {
			XCTAssertEqual(addedItem.streamIdentifier.streamResourceUid, thirdAddedItem.streamIdentifier.streamResourceUid, "Check event return correct new item")
		} else {
			XCTFail("Event AddNewItem should be rised")
		}
		
		eventExpectation = expectationWithDescription("Should rise AddNewItem event")
		// add fourth item at third place
		let fourthAddedItem = queue.addAfter(audioItems[3], afterItem: firstAddedtem.streamIdentifier.streamResourceUid)
		waitForExpectationsWithTimeout(1, handler: nil)
		
		XCTAssertEqual(audioItems[3].streamResourceUid, fourthAddedItem.streamIdentifier.streamResourceUid, "Check correct fourth item returned by method")
		XCTAssertEqual(4, queue.currentItems.count, "Check correct count in queue")
		XCTAssertNil(queue.last?.child, "Check last item in queue don't have child")
		XCTAssertNil(queue.first?.parent, "Check first item in queue don't have parent")
		if let addedItem = addedItem {
			XCTAssertEqual(addedItem.streamIdentifier.streamResourceUid, fourthAddedItem.streamIdentifier.streamResourceUid, "Check event return correct new item")
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
		let queue = RxPlayer(items: audioItems)
		
		queue.playerEvents.bindNext { result in
			if case PlayerEvents.AddNewItem = result {
				XCTFail("Event AddNewItem should not be rised")
			}
			}.addDisposableTo(bag)
		
		//let addedItem = queue.addLast(audioItems[1])
		let addedItem = queue.addLast(FakeStreamResourceIdentifier(uid: audioItems[1].streamResourceUid))
		XCTAssertEqual(audioItems.count, queue.count, "Check items count not changed")
		XCTAssertEqual(addedItem.streamIdentifier.streamResourceUid, audioItems[1].streamResourceUid, "Check method return correct item (that was already in queue")
	}
	
	func testInitQueueWithUniqueItems() {
		let items: [StreamResourceIdentifier] = ["test1", "test2", "test1", "test3", "test3", "test1"]
		let queue = RxPlayer(items: items)
		XCTAssertEqual(3, queue.count, "Should have only unique items")
		XCTAssertEqual(queue.currentItems.map { $0.streamIdentifier as! String }, ["test1", "test2", "test3"], "Check correct unique items")
	}
	
	func testCorrectChangeOrderOfItems() {
		let queue = RxPlayer(items: audioItems)
		guard let second = queue.getItemAtPosition(1), third = queue.getItemAtPosition(2) else {
			XCTFail("Should return items at indeces 1 and 2")
			return
		}
		
		var expectation = expectationWithDescription("Should rise event")
		
		var queueFromEvent: RxPlayer?
		queue.playerEvents.bindNext { result in
			if case PlayerEvents.ChangeItemsOrder(let resultQueue) = result {
				queueFromEvent = resultQueue
				expectation.fulfill()
			} else if case PlayerEvents.AddNewItem = result {
				XCTFail("Event AddNewItem should not be rised")
			}
			}.addDisposableTo(bag)
		
		// swap items
		var swapped = queue.addAfter(second.streamIdentifier.streamResourceUid, afterItem: third.streamIdentifier.streamResourceUid)
		
		waitForExpectationsWithTimeout(1, handler: nil)
		
		//print(queue.currentItems.map { $0.playerItem })
		XCTAssertEqual(second.streamIdentifier.streamResourceUid, swapped.streamIdentifier.streamResourceUid, "Method addAfter should return correct item")
		XCTAssertEqual(audioItems[0].streamResourceUid, queue.getItemAtPosition(0)?.streamIdentifier.streamResourceUid, "First item should be at same place")
		XCTAssertEqual(audioItems[1].streamResourceUid, queue.getItemAtPosition(2)?.streamIdentifier.streamResourceUid, "Second item should be now third")
		XCTAssertEqual(audioItems[2].streamResourceUid, queue.getItemAtPosition(1)?.streamIdentifier.streamResourceUid, "Third item should now be second")
		XCTAssertEqual(audioItems[3].streamResourceUid, queue.getItemAtPosition(3)?.streamIdentifier.streamResourceUid, "Last item should be at same place")
		XCTAssertTrue(queueFromEvent === queue, "Check ChangeItemsOrder event was rised and send correct instance of queue")
		
		expectation = expectationWithDescription("Should rise event")
		queueFromEvent = nil
		guard let first	= queue.first, last = queue.last else {
			XCTFail("Should return first and last items")
			return
		}
		
		// move first item to the end
		swapped = queue.addAfter(first.streamIdentifier.streamResourceUid, afterItem: last.streamIdentifier.streamResourceUid)
		
		waitForExpectationsWithTimeout(1, handler: nil)
		
		XCTAssertEqual(first.streamIdentifier.streamResourceUid, swapped.streamIdentifier.streamResourceUid, "Method addAfter should return correct item")
		XCTAssertEqual(audioItems[0].streamResourceUid, queue.getItemAtPosition(3)?.streamIdentifier.streamResourceUid, "First item should be now fourth (last)")
		XCTAssertEqual(audioItems[1].streamResourceUid, queue.getItemAtPosition(1)?.streamIdentifier.streamResourceUid, "Second item should be now second (again)")
		XCTAssertEqual(audioItems[2].streamResourceUid, queue.getItemAtPosition(0)?.streamIdentifier.streamResourceUid, "Third item should now be first")
		XCTAssertEqual(audioItems[3].streamResourceUid, queue.getItemAtPosition(2)?.streamIdentifier.streamResourceUid, "Fourt item should be now third")
		XCTAssertTrue(queueFromEvent === queue, "Check ChangeItemsOrder event was rised and send correct instance of queue")
	}
	
	func testCorrectMoveExistedItemToBeginningOfQueue() {
		let queue = RxPlayer(items: audioItems)
		guard let third = queue.getItemAtPosition(2) else {
			XCTFail("Should return item at 2 index")
			return
		}
		
		let expectation = expectationWithDescription("Should rise event")
		
		var queueFromEvent: RxPlayer?
		queue.playerEvents.bindNext { result in
			if case PlayerEvents.ChangeItemsOrder(let resultQueue) = result {
				queueFromEvent = resultQueue
				expectation.fulfill()
			} else if case PlayerEvents.AddNewItem = result {
				XCTFail("Event AddNewItem should not be rised")
			}
			}.addDisposableTo(bag)
		
		let swapped = queue.addFirst(third.streamIdentifier.streamResourceUid)
		
		waitForExpectationsWithTimeout(1, handler: nil)
		
		XCTAssertEqual(third.streamIdentifier.streamResourceUid, swapped.streamIdentifier.streamResourceUid, "Method addAfter should return correct item")
		XCTAssertEqual(audioItems[2].streamResourceUid, queue.first?.streamIdentifier.streamResourceUid, "Third item should now be first")
		XCTAssertEqual(audioItems[0].streamResourceUid, queue.getItemAtPosition(1)?.streamIdentifier.streamResourceUid, "First item should now be second")
		XCTAssertTrue(queueFromEvent === queue, "Check ChangeItemsOrder event was rised and send correct instance of queue")
	}
	
	func testCorrectMoveExistedItemToTheEndOfQueue() {
		let queue = RxPlayer(items: audioItems)
		guard let second = queue.getItemAtPosition(1) else {
			XCTFail("Should return item at 1 index")
			return
		}
		
		let expectation = expectationWithDescription("Should rise event")
		
		var queueFromEvent: RxPlayer?
		queue.playerEvents.bindNext { result in
			if case PlayerEvents.ChangeItemsOrder(let resultQueue) = result {
				queueFromEvent = resultQueue
				expectation.fulfill()
			} else if case PlayerEvents.AddNewItem = result {
				XCTFail("Event AddNewItem should not be rised")
			}
			}.addDisposableTo(bag)
		
		let swapped = queue.addLast(second.streamIdentifier.streamResourceUid)
		
		waitForExpectationsWithTimeout(1, handler: nil)
		
		XCTAssertEqual(second.streamIdentifier.streamResourceUid, swapped.streamIdentifier.streamResourceUid, "Method addAfter should return correct item")
		XCTAssertEqual(audioItems[1].streamResourceUid, queue.last?.streamIdentifier.streamResourceUid, "Second item should now be last")
		XCTAssertEqual(audioItems[3].streamResourceUid, queue.getItemAtPosition(2)?.streamIdentifier.streamResourceUid, "Fourth item should now be third")
		XCTAssertTrue(queueFromEvent === queue, "Check ChangeItemsOrder event was rised and send correct instance of queue")
	}
	
	func testToNext() {
		let queue = RxPlayer(items: audioItems)
		// now current item is nil, should set first item as current
		var next = queue.toNext()
		XCTAssertNotNil(queue.current)
		XCTAssertEqual(next, queue.current)
		XCTAssertEqual(next?.streamIdentifier.streamResourceUid, audioItems[0].streamResourceUid)
		
		next = queue.toNext()
		XCTAssertNotNil(queue.current)
		XCTAssertEqual(next, queue.current)
		XCTAssertEqual(next?.streamIdentifier.streamResourceUid, audioItems[1].streamResourceUid)
	}
	
	func testToPrevious() {
		let queue = RxPlayer(items: audioItems)
		// set second item as current
		queue.current = RxPlayerQueueItem(player: queue, streamIdentifier: audioItems[1])
		var next = queue.toPrevious()
		XCTAssertNotNil(queue.current)
		XCTAssertEqual(next, queue.current)
		XCTAssertEqual(next?.streamIdentifier.streamResourceUid, audioItems[0].streamResourceUid)
		
		// call toPrevious one more time
		// should remain on first item
		next = queue.toPrevious()
		XCTAssertNotNil(queue.current)
		XCTAssertEqual(next, queue.current)
		XCTAssertEqual(next?.streamIdentifier.streamResourceUid, audioItems[0].streamResourceUid)
	}
	
	func testToPreviousSetFistItemAsCurrentIfCurrentIsNil() {
		let queue = RxPlayer(items: audioItems)
		
		let expectation = expectationWithDescription("Should rise event")
		
		var newCurrent: RxPlayerQueueItem?
		queue.playerEvents.bindNext { result in
			if case PlayerEvents.CurrentItemChanged(let item) = result {
				newCurrent = item
				expectation.fulfill()
			}
			}.addDisposableTo(bag)
		
		let next = queue.toPrevious()
		
		waitForExpectationsWithTimeout(1, handler: nil)
		
		XCTAssertNotNil(queue.current, "Check current property is not nil")
		XCTAssertEqual(next, queue.current, "Check toPrevious return correct current item")
		XCTAssertEqual(next?.streamIdentifier.streamResourceUid, queue.first?.streamIdentifier.streamResourceUid, "Check current item is first in queue")
		XCTAssertEqual(newCurrent?.streamIdentifier.streamResourceUid, queue.first?.streamIdentifier.streamResourceUid, "Check event return correct current item")
	}
	
	func testToNextOnLastItemSetCurrentToNil() {
		let queue = RxPlayer(items: audioItems)
		// set curent item to last
		queue.current = RxPlayerQueueItem(player: queue, streamIdentifier: audioItems.last!)
		
		let expectation = expectationWithDescription("Should rise event")
		
		// init new current with value
		var newCurrent: RxPlayerQueueItem? = queue.current
		queue.playerEvents.bindNext { result in
			if case PlayerEvents.CurrentItemChanged(let item) = result {
				newCurrent = item
				expectation.fulfill()
			}
			}.addDisposableTo(bag)
		
		let next = queue.toNext()
		
		waitForExpectationsWithTimeout(1, handler: nil)
		
		XCTAssertNil(queue.current, "Current property in queue should be nil")
		XCTAssertNil(next, "Check toNext return nil as current item")
		XCTAssertNil(newCurrent, "Check event return nil as current item")
	}
	
	func testToNextOnLastItemSetCurrentToFirstWhenRepeatQueueIsTrue() {
		let queue = RxPlayer(items: audioItems, shuffle: false, repeatQueue: true)
		// set curent item to last
		queue.current = RxPlayerQueueItem(player: queue, streamIdentifier: audioItems.last!)
		
		let expectation = expectationWithDescription("Should rise event")
		
		var newCurrent: RxPlayerQueueItem?
		queue.playerEvents.bindNext { result in
			if case PlayerEvents.CurrentItemChanged(let item) = result {
				newCurrent = item
				expectation.fulfill()
			}
			}.addDisposableTo(bag)
		
		let next = queue.toNext()
		
		waitForExpectationsWithTimeout(1, handler: nil)
		
		XCTAssertNotNil(queue.current, "Check current is not nill")
		XCTAssertEqual(next, queue.current, "Check toNext return correct current item")
		XCTAssertEqual(next?.streamIdentifier.streamResourceUid, queue.first?.streamIdentifier.streamResourceUid, "Check current item is first")
		XCTAssertEqual(newCurrent?.streamIdentifier.streamResourceUid, audioItems[0].streamResourceUid, "Check event return correct current item")
	}
	
	func testRemoveItem() {
		let queue = RxPlayer(items: audioItems)
		let itemToRemove = RxPlayerQueueItem(player: queue, streamIdentifier: audioItems[1])
		
		let expectation = expectationWithDescription("Should rise event")
		
		var removedItem: RxPlayerQueueItem?
		queue.playerEvents.bindNext { result in
			if case PlayerEvents.RemoveItem(let item) = result {
				removedItem = item
				expectation.fulfill()
			} else if case PlayerEvents.ChangeItemsOrder = result {
				XCTFail("Change item order should not be rised")
			}
			}.addDisposableTo(bag)
		
		queue.remove(itemToRemove)
		
		waitForExpectationsWithTimeout(1, handler: nil)
		
		XCTAssertEqual(3, queue.count, "Check items count changed")
		XCTAssertEqual(0, queue.currentItems.filter { $0.streamIdentifier.streamResourceUid == audioItems[1].streamResourceUid }.count, "Check item actually removed from current queue items")
		XCTAssertFalse(itemToRemove.inQueue, "Check removed item now has status inQueue == false")
		XCTAssertEqual(removedItem?.streamIdentifier.streamResourceUid, itemToRemove.streamIdentifier.streamResourceUid, "Check event rised with correct removed item")
	}
	
	func testNotRemoveItemThatNotExistsInQueue() {
		let queue = RxPlayer(items: audioItems)
		let notExisted = RxPlayerQueueItem(player: queue, streamIdentifier: "http://item5.com")
		
		queue.playerEvents.bindNext { result in
			if case PlayerEvents.RemoveItem = result {
				XCTFail("Should not rise this event, because we try to delete item not existed in queue")
			}
			}.addDisposableTo(bag)
		
		queue.remove(notExisted)
		XCTAssertEqual(4, queue.count)
	}
	
	func testChangeRepeat() {
		let queue = RxPlayer(items: audioItems, shuffle: false, repeatQueue: false)
		XCTAssertFalse(queue.repeatQueue, "RepeatQueue should be false")
		
		let expectation = expectationWithDescription("Should rise event")
		
		var eventValue: Bool?
		queue.playerEvents.bindNext { result in
			if case PlayerEvents.RepeatChanged(let newVal) = result {
				eventValue = newVal
				expectation.fulfill()
			}
			}.addDisposableTo(bag)
		
		queue.repeatQueue = true
		
		waitForExpectationsWithTimeout(1, handler: nil)
		
		XCTAssertEqual(true, eventValue, "Check queue rised event wih correct new value")
		XCTAssertTrue(queue.repeatQueue, "RepeatQueue should be true")
	}
	
	func testNotMoveitemsInQueueIfItemAlreadyExists() {
		let player = RxPlayer(items: audioItems)
		
		// play url that exists in queue and set clearQueue to false
		// so order of items should be preserved
		player.play(audioItems[1], clearQueue: false)
		
		XCTAssertEqual(audioItems[1].streamResourceUid, player.current?.streamIdentifier.streamResourceUid, "Check correct current item")
		XCTAssertEqual(audioItems.map { $0.streamResourceUid }, player.currentItems.map { $0.streamIdentifier.streamResourceUid }, "Check order of items in queue")
	}
	
	func testToNextStartPlaying() {
		let queue = RxPlayer(items: audioItems)
		// start playing first item and pause
		queue.resume(true)
		queue.pause()
		
		XCTAssertFalse(queue.playing, "Check player is not playing")
		
		let expectation = expectationWithDescription("Should rise event")

		queue.playerEvents.bindNext { result in
			if case PlayerEvents.CurrentItemChanged(let item) = result {
				XCTAssertEqual(item?.streamIdentifier.streamResourceUid, self.audioItems[1].streamResourceUid, "Check switched to second item")
				expectation.fulfill()
			}
		}.addDisposableTo(bag)
		
		queue.toNext(true)
		
		waitForExpectationsWithTimeout(1, handler: nil)
		
		XCTAssertTrue(queue.playing)
	}
	
	func testToNextNotStartPlayingOnLastItemIfRepeatQueueIsFalse() {
		let queue = RxPlayer(items: audioItems)
		queue.repeatQueue = false
		// start playing last item and pause
		queue.current = queue.last
		queue.pause()
		
		XCTAssertFalse(queue.playing, "Check player is not playing")
		
		let expectation = expectationWithDescription("Should rise event")
		
		queue.playerEvents.bindNext { result in
			if case PlayerEvents.CurrentItemChanged(let item) = result {
				XCTAssertNil(item, "Check new current item is nil")
				expectation.fulfill()
			}
			}.addDisposableTo(bag)
		
		queue.toNext(true)
		
		waitForExpectationsWithTimeout(1, handler: nil)
		
		XCTAssertFalse(queue.playing)
	}
	
	func testToNextStartPlayingOnLastItemIfRepeatQueueIsTrue() {
		let queue = RxPlayer(items: audioItems)
		queue.repeatQueue = true
		// start playing last item and pause
		queue.current = queue.last
		queue.pause()
		
		XCTAssertFalse(queue.playing, "Check player is not playing")
		
		let expectation = expectationWithDescription("Should rise CurrentItemChanged event")
		
		queue.playerEvents.bindNext { result in
			if case PlayerEvents.CurrentItemChanged(let item) = result {
				print(item?.streamIdentifier.streamResourceUid)
				XCTAssertEqual(item?.streamIdentifier.streamResourceUid, queue.first?.streamIdentifier.streamResourceUid, "Check new item is first item in queue")
				expectation.fulfill()
			}
			}.addDisposableTo(bag)
		
		queue.toNext(true)
		
		waitForExpectationsWithTimeout(1, handler: nil)

		XCTAssertTrue(queue.playing)
	}
	
	
	
	func testToPreviousStartPlaying() {
		let queue = RxPlayer(items: audioItems)
		// start playing item and pause
		queue.current = queue.getItemAtPosition(2)
		queue.resume(true)
		queue.pause()
		
		XCTAssertFalse(queue.playing, "Check player is not playing")
		
		let expectation = expectationWithDescription("Should rise event")
		
		queue.playerEvents.bindNext { result in
			if case PlayerEvents.CurrentItemChanged(let item) = result {
				XCTAssertEqual(item?.streamIdentifier.streamResourceUid, self.audioItems[1].streamResourceUid, "Check switched to second item")
				expectation.fulfill()
			}
			}.addDisposableTo(bag)
		
		queue.toPrevious(true)
		
		waitForExpectationsWithTimeout(1, handler: nil)
		
		XCTAssertTrue(queue.playing)
	}
	
	func testToPreviousDoNothingOnfirstItemWhenStartPlayingIsTrue() {
		let queue = RxPlayer(items: audioItems)
		queue.repeatQueue = false
		// start playing first item and pause
		queue.current = queue.first
		queue.pause()
		
		XCTAssertFalse(queue.playing, "Check player is not playing")
		
		
		queue.playerEvents.bindNext { result in
			if case PlayerEvents.CurrentItemChanged = result {
				XCTFail("Should not change current item")
			}
		}.addDisposableTo(bag)
		
		queue.toPrevious(true)
		
		NSThread.sleepForTimeInterval(0.05)

		XCTAssertEqual(queue.first?.streamIdentifier.streamResourceUid, audioItems.first?.streamResourceUid)
		XCTAssertFalse(queue.playing)
	}
	
	func testFindItemByUid() {
		let player = RxPlayer(items: ["http://test.com", "http://test2.com", FakeStreamResourceIdentifier(uid: "http://test3.com")])
		XCTAssertNotNil(player.getQueueItemByUid("http://test.com"))
		XCTAssertNotNil(player.getQueueItemByUid("http://test3.com"))
	}
	
	func testPlayItemsWhenStartItemSpecifiedMoveThisItemToFirstPlace() {
		let queue = RxPlayer()
		queue.play(audioItems, startWithItem: audioItems.last)
		
		XCTAssertEqual(audioItems.count, queue.count)
		XCTAssertEqual(queue.first?.streamIdentifier.streamResourceUid, audioItems.last?.streamResourceUid)
	}
}
