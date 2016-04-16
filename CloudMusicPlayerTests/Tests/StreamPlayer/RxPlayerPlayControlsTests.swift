//
//  RxPlayerTests.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 10.04.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import XCTest
import RxSwift
@testable import CloudMusicPlayer

class RxPlayerPlayControlsTests: XCTestCase {
	let bag = DisposeBag()
	
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
	}
	
	func testStartPlaying() {
		let downloadManager = DownloadManager(saveData: false, fileStorage: LocalNsUserDefaultsStorage(), httpUtilities: FakeHttpUtilities())		
		let player = RxPlayer(repeatQueue: false, internalPlayer: FakeInternalPlayer(), downloadManager: downloadManager)
		
		XCTAssertFalse(player.playing, "Playing property should be false")
		
		player.rx_observe().dispatchPlayerControlEvents().subscribe().addDisposableTo(bag)
		player.rx_observe().streamContent().subscribe().addDisposableTo(bag)
		
		let preparingExpectation = expectationWithDescription("Should rise PreparingToPlay event")
		let playStartedExpectation = expectationWithDescription("Should invoke Start on internal player")
		
		let playingItem = "https://test.com/track1.mp3"
		player.rx_observe().bindNext { e in
			if case PlayerEvents.PreparingToPlay(let item) = e {
				XCTAssertEqual(playingItem.streamResourceUid, item.streamIdentifier.streamResourceUid)
				preparingExpectation.fulfill()
			} else if case PlayerEvents.Started = e {
				playStartedExpectation.fulfill()
			}
		}.addDisposableTo(bag)
		
		player.playUrl(playingItem)
		
		waitForExpectationsWithTimeout(1, handler: nil)
		
		XCTAssertTrue(player.playing, "Playing property should be true")
	}
	
	func testPausing() {
		let downloadManager = DownloadManager(saveData: false, fileStorage: LocalNsUserDefaultsStorage(), httpUtilities: FakeHttpUtilities())
		let player = RxPlayer(repeatQueue: false, internalPlayer: FakeInternalPlayer(), downloadManager: downloadManager)
		//let player = RxPlayer(repeatQueue: false, internalPlayer: FakeInternalPlayer())
		
		player.rx_observe().dispatchPlayerControlEvents().subscribe().addDisposableTo(bag)
		player.rx_observe().streamContent().subscribe().addDisposableTo(bag)
		
		let pausingExpectation = expectationWithDescription("Should rise Pausing event")
		let pausedExpectation = expectationWithDescription("Should invoke Pause on internal player")
		
		let playingItem = "https://test.com/track1.mp3"
		player.rx_observe().bindNext { e in
			if case PlayerEvents.Pausing(let item) = e {
				XCTAssertEqual(playingItem.streamResourceUid, item.streamIdentifier.streamResourceUid)
				pausingExpectation.fulfill()
			} else if case PlayerEvents.Paused = e {
				pausedExpectation.fulfill()
			}
			}.addDisposableTo(bag)
		
		player.playUrl(playingItem)
		player.pause()
		
		waitForExpectationsWithTimeout(1, handler: nil)
		
		XCTAssertFalse(player.playing, "Playing property should be false")
	}
	
	func testResuming() {
		let downloadManager = DownloadManager(saveData: false, fileStorage: LocalNsUserDefaultsStorage(), httpUtilities: FakeHttpUtilities())
		let player = RxPlayer(repeatQueue: false, internalPlayer: FakeInternalPlayer(), downloadManager: downloadManager)
		//let player = RxPlayer(repeatQueue: false, internalPlayer: FakeInternalPlayer())
		
		player.rx_observe().dispatchPlayerControlEvents().subscribe().addDisposableTo(bag)
		player.rx_observe().streamContent().subscribe().addDisposableTo(bag)
		
		let resumingExpectation = expectationWithDescription("Should rise Resuming event")
		let resumedExpectation = expectationWithDescription("Should invoke Resume on internal player")
		
		let playingItem = "https://test.com/track1.mp3"
		player.rx_observe().bindNext { e in
			if case PlayerEvents.Resuming(let item) = e {
				XCTAssertEqual(playingItem.streamResourceUid, item.streamIdentifier.streamResourceUid)
				resumingExpectation.fulfill()
			} else if case PlayerEvents.Resumed = e {
				resumedExpectation.fulfill()
			}
			}.addDisposableTo(bag)
		
		player.playUrl(playingItem)
		player.pause()
		player.resume()
		
		waitForExpectationsWithTimeout(1, handler: nil)
		
		XCTAssertTrue(player.playing, "Playing property should be true")
	}
	
	func testStopping() {
		let downloadManager = DownloadManager(saveData: false, fileStorage: LocalNsUserDefaultsStorage(), httpUtilities: FakeHttpUtilities())
		let player = RxPlayer(repeatQueue: false, internalPlayer: FakeInternalPlayer(), downloadManager: downloadManager)
		//let player = RxPlayer(repeatQueue: false, internalPlayer: FakeInternalPlayer())
		
		player.rx_observe().dispatchPlayerControlEvents().subscribe().addDisposableTo(bag)
		player.rx_observe().streamContent().subscribe().addDisposableTo(bag)
		
		let stoppingExpectation = expectationWithDescription("Should rise Stopping event")
		let stoppedExpectation = expectationWithDescription("Should invoke Stopped on internal player")
		
		let playingItem = "https://test.com/track1.mp3"
		player.rx_observe().bindNext { e in
			if case PlayerEvents.Stopping(let item) = e {
				XCTAssertEqual(playingItem.streamResourceUid, item.streamIdentifier.streamResourceUid)
				stoppingExpectation.fulfill()
			} else if case PlayerEvents.Stopped = e {
				stoppedExpectation.fulfill()
			}
			}.addDisposableTo(bag)
		
		player.playUrl(playingItem)
		player.stop()
		
		waitForExpectationsWithTimeout(1, handler: nil)
		
		XCTAssertFalse(player.playing, "Playing property should be false")
	}
	
	func testNotResumeWhenCurrentIsNil() {
		let downloadManager = DownloadManager(saveData: false, fileStorage: LocalNsUserDefaultsStorage(), httpUtilities: FakeHttpUtilities())
		let player = RxPlayer(repeatQueue: false, internalPlayer: FakeInternalPlayer(), downloadManager: downloadManager)
		//let player = RxPlayer(repeatQueue: false, internalPlayer: FakeInternalPlayer())
		
		player.rx_observe().dispatchPlayerControlEvents().subscribe().addDisposableTo(bag)
		player.rx_observe().streamContent().subscribe().addDisposableTo(bag)
		
		let playingItem = "https://test.com/track1.mp3"
		
		player.initWithNewItems([playingItem])
		
		player.rx_observe().bindNext { e in
			XCTFail("Should not rise any events")
		}.addDisposableTo(bag)
		player.resume()
		
		
		XCTAssertFalse(player.playing, "Playing property should be false")
	}
	
	func testForceResumeFromNextIfCurrentIsNil() {
		let downloadManager = DownloadManager(saveData: false, fileStorage: LocalNsUserDefaultsStorage(), httpUtilities: FakeHttpUtilities())
		let player = RxPlayer(repeatQueue: false, internalPlayer: FakeInternalPlayer(), downloadManager: downloadManager)
		//let player = RxPlayer(repeatQueue: false, internalPlayer: FakeInternalPlayer())
		
		player.rx_observe().dispatchPlayerControlEvents().subscribe().addDisposableTo(bag)
		player.rx_observe().streamContent().subscribe().addDisposableTo(bag)
		
		let playingItems: [StreamResourceIdentifier] = ["https://test.com/track1.mp3", "https://test.com/track2.mp3", "https://test.com/track3.mp3"]
		player.initWithNewItems(playingItems)
		
		let preparingToPlayExpectation = expectationWithDescription("Should rise PrepareToPlay event")
		
		player.rx_observe().bindNext { e in
			if case PlayerEvents.PreparingToPlay(let item) = e {
				XCTAssertEqual(playingItems[0].streamResourceUid, item.streamIdentifier.streamResourceUid, "Should resume from first item")
				preparingToPlayExpectation.fulfill()
			}
		}.addDisposableTo(bag)
		
		player.resume(true)
		
		waitForExpectationsWithTimeout(1, handler: nil)
		
		XCTAssertTrue(player.playing, "Playing property should be true")
	}
	
	func testPlayUrlAddNewItemToEndAndSetAsCurrent() {
		let downloadManager = DownloadManager(saveData: false, fileStorage: LocalNsUserDefaultsStorage(), httpUtilities: FakeHttpUtilities())
		let player = RxPlayer(repeatQueue: false, internalPlayer: FakeInternalPlayer(), downloadManager: downloadManager)
		//let player = RxPlayer(items: ["https://test.com/track1.mp3", "https://test.com/track2.mp3", "https://test.com/track3.mp3"])
		player.initWithNewItems(["https://test.com/track1.mp3", "https://test.com/track2.mp3", "https://test.com/track3.mp3"])
		player.toNext()
		
		player.rx_observe().dispatchPlayerControlEvents().subscribe().addDisposableTo(bag)
		player.rx_observe().streamContent().subscribe().addDisposableTo(bag)
		
		let preparingExpectation = expectationWithDescription("Should start play new item")
		let currentItemChangedExpectation = expectationWithDescription("Should change current item")
		
		let newItem = "https://test.com/track4.mp3"
		player.rx_observe().bindNext { e in
			if case PlayerEvents.PreparingToPlay(let item) = e {
				XCTAssertEqual(newItem.streamResourceUid, item.streamIdentifier.streamResourceUid, "Should start playing new item")
				preparingExpectation.fulfill()
			} else if case PlayerEvents.CurrentItemChanged(let changedItem) = e {
				XCTAssertEqual(newItem.streamResourceUid, changedItem?.streamIdentifier.streamResourceUid, "Should set new item as current")
				currentItemChangedExpectation.fulfill()
			}
		}.addDisposableTo(bag)
		
		player.playUrl(newItem, clearQueue: false)
		
		waitForExpectationsWithTimeout(1, handler: nil)
		
		XCTAssertEqual(4, player.count, "Should have 4 items in queue")
	}
}