//
//  PlayerQueueTests.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 29.03.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import XCTest
@testable import CloudMusicPlayer

class PlayerQueueTests: XCTestCase {
	var player: StreamAudioPlayer!
	
	var audioItems: [StreamAudioItem]!
	
	//var session: FakeSession!
	//var utilities: FakeHttpUtilities!
	
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
		player = StreamAudioPlayer()
		audioItems = [StreamAudioItem(resourceIdentifier: FakeResourceIdentifier(uid: "fake one", task: nil), player: player),
		             StreamAudioItem(resourceIdentifier: FakeResourceIdentifier(uid: "fake two", task: nil), player: player),
		             StreamAudioItem(resourceIdentifier: FakeResourceIdentifier(uid: "fake three", task: nil), player: player),
		             StreamAudioItem(resourceIdentifier: FakeResourceIdentifier(uid: "fake four", task: nil), player: player)]
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
	}
	
	func testCreateEmptyQueue() {
		let queue = PlayerQueue()
		XCTAssertNil(queue.current, "Current item should be nil")
		XCTAssertNil(queue.first, "First item should be nil")
		XCTAssertNil(queue.last, "Last item should be nil")
		XCTAssertEqual(0, queue.currentItems.count, "Queue should not have any items")
	}
	
	func testCreateQueueWithCorrectItems() {
		let queue = PlayerQueue(items: audioItems)
		XCTAssertEqual(audioItems.count, queue.currentItems.count, "Should create queue with correct count of items")
		XCTAssertEqual(audioItems, queue.currentItems.map { $0.playerItem }, "Check initial array and array in queue are equal")
		XCTAssertEqual(0, queue.currentItems.filter { !$0.inQueue }.count, "All items should have property inQueue in true state")
		XCTAssertEqual(audioItems[0], queue.first?.playerItem, "Check first item in queue")
		XCTAssertEqual(audioItems[0], queue.getItemAtPosition(0)?.playerItem, "Check first item in queue by index")
		XCTAssertNil(queue.first?.parent, "First item in queue should not have a parent item")
		XCTAssertEqual(audioItems[1], queue.first?.child?.playerItem, "Check second item in queue")
		XCTAssertEqual(audioItems[0], queue.first?.child?.parent?.playerItem, "Second item should have first as parent")
		XCTAssertEqual(audioItems[2], queue.first?.child?.child?.playerItem, "Check third item in queue")
		XCTAssertEqual(audioItems[1], queue.first?.child?.child?.parent?.playerItem, "Third item should have second as parent")
		XCTAssertEqual(audioItems[3], queue.first?.child?.child?.child?.playerItem, "Check fourth item in queue")
		XCTAssertEqual(audioItems[2], queue.first?.child?.child?.child?.parent?.playerItem, "Fourth item should have third as parent")
		XCTAssertNil(queue.first?.child?.child?.child?.child, "Fourth item should not have child item")
		XCTAssertNil(queue.current, "Current item in queue should be nil")
		XCTAssertEqual(audioItems[3], queue.last?.playerItem, "Check last item in queue")
	}
	
	func testCreateShuffledQueueWithCorrectItems() {
		let queue = PlayerQueue(items: audioItems, shuffle: true)
		XCTAssertNotEqual(audioItems, queue.currentItems.map { $0.playerItem }, "Queue should have collection of shuffled items")
	}
	
	func testAddItemsToQueue() {
		let queue = PlayerQueue()
		
		// add first item
		let firstAddedtem = queue.addFirst(audioItems[0])
		XCTAssertEqual(firstAddedtem.playerItem, audioItems[0], "Check correct first item returned by method")
		XCTAssertEqual(1, queue.currentItems.count, "Check correct count in queue")
		XCTAssertEqual(firstAddedtem.playerItem, queue.first?.playerItem, "Check added item is first in queue")
		XCTAssertEqual(firstAddedtem.playerItem, queue.last?.playerItem, "Check added item is last in queue")
		XCTAssertNil(queue.last?.child, "Check last item in queue don't have child")
		XCTAssertNil(queue.first?.parent, "Check first item in queue don't have parent")
		
		// add second item at first place
		let secondAddedItem = queue.addFirst(audioItems[1])
		XCTAssertEqual(audioItems[1], secondAddedItem.playerItem, "Check correct second item returned by method")
		XCTAssertEqual(2, queue.currentItems.count, "Check correct count in queue")
		XCTAssertEqual(secondAddedItem.playerItem, queue.first?.playerItem, "Check second added item is first in queue")
		XCTAssertEqual(firstAddedtem.playerItem, queue.last?.playerItem, "Check first added item still last in queue")
		XCTAssertEqual(firstAddedtem.parent?.playerItem, secondAddedItem.playerItem, "Check second item has first as a parent")
		XCTAssertNil(queue.last?.child, "Check last item in queue don't have child")
		XCTAssertNil(queue.first?.parent, "Check first item in queue don't have parent")
		
		// add third item at the end
		let thirdAddedItem = queue.addLast(audioItems[2])
		XCTAssertEqual(audioItems[2], thirdAddedItem.playerItem, "Check correct third item returned by method")
		XCTAssertEqual(3, queue.currentItems.count, "Check correct count in queue")
		XCTAssertEqual(thirdAddedItem.playerItem, queue.last?.playerItem, "Check third added item is last in queue")
		XCTAssertEqual(secondAddedItem.playerItem, queue.first?.playerItem, "Check second added item is still first in queue")
		XCTAssertNil(queue.last?.child, "Check last item in queue don't have child")
		XCTAssertNil(queue.first?.parent, "Check first item in queue don't have parent")
		
		// add fourth item at third place
		let fourthAddedItem = queue.addAfter(audioItems[3], afterItem: firstAddedtem.playerItem)
		XCTAssertEqual(audioItems[3], fourthAddedItem.playerItem, "Check correct fourth item returned by method")
		XCTAssertEqual(4, queue.currentItems.count, "Check correct count in queue")
		XCTAssertNil(queue.last?.child, "Check last item in queue don't have child")
		XCTAssertNil(queue.first?.parent, "Check first item in queue don't have parent")
		
		// check items chain
		XCTAssertEqual(queue.first?.playerItem, secondAddedItem.playerItem, "Second added item should be first")
		XCTAssertEqual(queue.first?.child?.playerItem, firstAddedtem.playerItem, "First added item should be second")
		XCTAssertEqual(queue.first?.child?.child?.playerItem, fourthAddedItem.playerItem, "Fourth added item should be third")
		XCTAssertEqual(queue.first?.child?.child?.child?.playerItem, thirdAddedItem.playerItem, "Third added item should be fourth")
	}
}

extension StreamAudioItem : CustomStringConvertible {
	public var description: String {
		return resourceIdentifier.uid
	}
}
