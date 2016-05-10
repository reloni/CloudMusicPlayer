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
import RealmSwift

class RxPlayerPlayControlsTests: XCTestCase {
	let bag = DisposeBag()
	
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
		Realm.Configuration.defaultConfiguration.inMemoryIdentifier = self.name
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
	}
	
	func testCurrentItemObservableReturnNilForNewPlayer() {
		let player = RxPlayer()
		
		let currentItemChangeExpectation = expectationWithDescription("Should send current item")
		player.currentItem.bindNext { item in
			XCTAssertNil(item, "Should return nil")
			currentItemChangeExpectation.fulfill()
			}.addDisposableTo(bag)
		
		waitForExpectationsWithTimeout(1, handler: nil)
	}
	
	func testStartPlaying() {
		let downloadManager = DownloadManager(saveData: false, fileStorage: LocalNsUserDefaultsStorage(), httpUtilities: FakeHttpUtilities())
		//let player = RxPlayer(repeatQueue: false, internalPlayer: FakeInternalPlayer(), downloadManager: downloadManager)
		let player = RxPlayer(repeatQueue: false, downloadManager: downloadManager, streamPlayerUtilities: FakeStreamPlayerUtilities())
		
		XCTAssertFalse(player.playing, "Playing property should be false")
		
		//player.playerEvents.dispatchPlayerControlEvents().subscribe().addDisposableTo(bag)
		//player.playerEvents.streamContent().subscribe().addDisposableTo(bag)
		
		let preparingExpectation = expectationWithDescription("Should rise PreparingToPlay event")
		let playStartedExpectation = expectationWithDescription("Should invoke Start on internal player")
		let currentItemChangeExpectation = expectationWithDescription("Should change current item")
		
		let playingItem = "https://test.com/track1.mp3"
		player.playerEvents.bindNext { e in
			if case PlayerEvents.PreparingToPlay(let item) = e {
				XCTAssertEqual(playingItem.streamResourceUid, item.streamIdentifier.streamResourceUid, "Check correct item preparing to play")
				preparingExpectation.fulfill()
			} else if case PlayerEvents.Started = e {
				playStartedExpectation.fulfill()
			}
		}.addDisposableTo(bag)
		
		player.currentItem.filter { $0 != nil }.bindNext { item in
			XCTAssertEqual(playingItem.streamResourceUid, item?.streamIdentifier.streamResourceUid, "Check correct item send as new current item")
			currentItemChangeExpectation.fulfill()
		}.addDisposableTo(bag)
		
		player.playUrl(playingItem)
		
		waitForExpectationsWithTimeout(1, handler: nil)
		
		XCTAssertTrue(player.playing, "Playing property should be true")
	}
	
	func testPausing() {
		let downloadManager = DownloadManager(saveData: false, fileStorage: LocalNsUserDefaultsStorage(), httpUtilities: FakeHttpUtilities())
		//let player = RxPlayer(repeatQueue: false, internalPlayer: FakeInternalPlayer(), downloadManager: downloadManager)
		//let player = RxPlayer(repeatQueue: false, internalPlayer: FakeInternalPlayer())
		let player = RxPlayer(repeatQueue: false, downloadManager: downloadManager, streamPlayerUtilities: FakeStreamPlayerUtilities())
		
		//player.playerEvents.dispatchPlayerControlEvents().subscribe().addDisposableTo(bag)
		//player.playerEvents.streamContent().subscribe().addDisposableTo(bag)
		
		let pausingExpectation = expectationWithDescription("Should rise Pausing event")
		let pausedExpectation = expectationWithDescription("Should invoke Pause on internal player")
		
		let playingItem = "https://test.com/track1.mp3"
		player.playerEvents.bindNext { e in
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
		//let fakeInternalPlayer = FakeInternalPlayer()
		// set fake native player instance, 
		// so RxPlayer will think, that player paused and will invoke resume method
		//fakeInternalPlayer.nativePlayer = FakeNativePlayer()
		//let player = RxPlayer(repeatQueue: false, internalPlayer: fakeInternalPlayer, downloadManager: downloadManager)
		//let player = RxPlayer(repeatQueue: false, internalPlayer: FakeInternalPlayer())
		let player = RxPlayer(repeatQueue: false, downloadManager: downloadManager, streamPlayerUtilities: FakeStreamPlayerUtilities())
		
		// set fake native player instance,
		// so RxPlayer will think, that player paused and will invoke resume method
		(player.internalPlayer as! FakeInternalPlayer).nativePlayer = FakeNativePlayer()
		
		//player.playerEvents.dispatchPlayerControlEvents().subscribe().addDisposableTo(bag)
		//player.playerEvents.streamContent().subscribe().addDisposableTo(bag)
		
		let resumingExpectation = expectationWithDescription("Should rise Resuming event")
		let resumedExpectation = expectationWithDescription("Should invoke Resume on internal player")
		
		let playingItem = "https://test.com/track1.mp3"
		player.playerEvents.bindNext { e in
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
	
	func testResumingWhenNativePlayerIsNil() {
		let downloadManager = DownloadManager(saveData: false, fileStorage: LocalNsUserDefaultsStorage(), httpUtilities: FakeHttpUtilities())
		//let player = RxPlayer(repeatQueue: false, internalPlayer: FakeInternalPlayer(), downloadManager: downloadManager)
		//let player = RxPlayer(repeatQueue: false, internalPlayer: FakeInternalPlayer())
		let player = RxPlayer(repeatQueue: false, downloadManager: downloadManager, streamPlayerUtilities: FakeStreamPlayerUtilities())
		
		player.initWithNewItems(["https://test.com/track1.mp3", "https://test.com/track2.mp3", "https://test.com/track3.mp3"])
		let playingItem = player.first!.streamIdentifier
		// set current item
		player.current = player.first
		
		
		//player.playerEvents.dispatchPlayerControlEvents().subscribe().addDisposableTo(bag)
		//player.playerEvents.streamContent().subscribe().addDisposableTo(bag)
		
		let resumingExpectation = expectationWithDescription("Should rise Resuming event")
		let startedExpectation = expectationWithDescription("Should invoke Play on internal player")
		let preparingToPlayExpectation = expectationWithDescription("Should rise PreparingToPlay event")
		
		player.playerEvents.bindNext { e in
			if case PlayerEvents.Resuming(let item) = e {
				XCTAssertEqual(playingItem.streamResourceUid, item.streamIdentifier.streamResourceUid)
				resumingExpectation.fulfill()
			} else if case PlayerEvents.Started = e {
				startedExpectation.fulfill()
			} else if case PlayerEvents.PreparingToPlay(let preparingItem) = e {
				XCTAssertEqual(preparingItem.streamIdentifier.streamResourceUid, playingItem.streamResourceUid)
				preparingToPlayExpectation.fulfill()
			}
			}.addDisposableTo(bag)
		
		//player.playUrl(playingItem)
		//player.pause()
		player.resume()
		
		waitForExpectationsWithTimeout(1, handler: nil)
		
		XCTAssertTrue(player.playing, "Playing property should be true")
	}
	
	func testStopping() {
		let downloadManager = DownloadManager(saveData: false, fileStorage: LocalNsUserDefaultsStorage(), httpUtilities: FakeHttpUtilities())
		//let player = RxPlayer(repeatQueue: false, internalPlayer: FakeInternalPlayer(), downloadManager: downloadManager)
		//let player = RxPlayer(repeatQueue: false, internalPlayer: FakeInternalPlayer())
		let player = RxPlayer(repeatQueue: false, downloadManager: downloadManager, streamPlayerUtilities: FakeStreamPlayerUtilities())
		
		//player.playerEvents.dispatchPlayerControlEvents().subscribe().addDisposableTo(bag)
		//player.playerEvents.streamContent().subscribe().addDisposableTo(bag)
		
		let stoppingExpectation = expectationWithDescription("Should rise Stopping event")
		let stoppedExpectation = expectationWithDescription("Should invoke Stopped on internal player")
		
		let playingItem = "https://test.com/track1.mp3"
		player.playerEvents.bindNext { e in
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
		XCTAssertNotNil(player.current)
	}
	
	func testNotResumeWhenCurrentIsNil() {
		let downloadManager = DownloadManager(saveData: false, fileStorage: LocalNsUserDefaultsStorage(), httpUtilities: FakeHttpUtilities())
		//let player = RxPlayer(repeatQueue: false, internalPlayer: FakeInternalPlayer(), downloadManager: downloadManager)
		//let player = RxPlayer(repeatQueue: false, internalPlayer: FakeInternalPlayer())
		let player = RxPlayer(repeatQueue: false, downloadManager: downloadManager, streamPlayerUtilities: FakeStreamPlayerUtilities())
		
		//player.playerEvents.dispatchPlayerControlEvents().subscribe().addDisposableTo(bag)
		//player.playerEvents.streamContent().subscribe().addDisposableTo(bag)
		
		let playingItem = "https://test.com/track1.mp3"
		
		player.initWithNewItems([playingItem])
		
		player.playerEvents.skip(1).bindNext { e in
			XCTFail("Should not rise any events while resuming")
		}.addDisposableTo(bag)
		
		player.resume()
		
		NSThread.sleepForTimeInterval(0.5)
		XCTAssertFalse(player.playing, "Playing property should be false")
	}
	
	func testForceResumeFromNextIfCurrentIsNil() {
		let downloadManager = DownloadManager(saveData: false, fileStorage: LocalNsUserDefaultsStorage(), httpUtilities: FakeHttpUtilities())
		//let player = RxPlayer(repeatQueue: false, internalPlayer: FakeInternalPlayer(), downloadManager: downloadManager)
		//let player = RxPlayer(repeatQueue: false, internalPlayer: FakeInternalPlayer())
		let player = RxPlayer(repeatQueue: false, downloadManager: downloadManager, streamPlayerUtilities: FakeStreamPlayerUtilities())
		
		//player.playerEvents.dispatchPlayerControlEvents().subscribe().addDisposableTo(bag)
		//player.playerEvents.streamContent().subscribe().addDisposableTo(bag)
		
		let playingItems: [StreamResourceIdentifier] = ["https://test.com/track1.mp3", "https://test.com/track2.mp3", "https://test.com/track3.mp3"]
		player.initWithNewItems(playingItems)
		
		let preparingToPlayExpectation = expectationWithDescription("Should rise PrepareToPlay event")
		
		player.playerEvents.bindNext { e in
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
		//let player = RxPlayer(repeatQueue: false, internalPlayer: FakeInternalPlayer(), downloadManager: downloadManager)
		//let player = RxPlayer(items: ["https://test.com/track1.mp3", "https://test.com/track2.mp3", "https://test.com/track3.mp3"])
		let player = RxPlayer(repeatQueue: false, downloadManager: downloadManager, streamPlayerUtilities: FakeStreamPlayerUtilities())
		player.initWithNewItems(["https://test.com/track1.mp3", "https://test.com/track2.mp3", "https://test.com/track3.mp3"])
		player.toNext()
		
		//player.playerEvents.dispatchPlayerControlEvents().subscribe().addDisposableTo(bag)
		//player.playerEvents.streamContent().subscribe().addDisposableTo(bag)
		
		let preparingExpectation = expectationWithDescription("Should start play new item")
		let currentItemChangedExpectation = expectationWithDescription("Should change current item")
		
		let newItem = "https://test.com/track4.mp3"
		player.playerEvents.bindNext { e in
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
	
	func testSwitchToNextAfterCurrentItemFinishesPlaying() {
		let downloadManager = DownloadManager(saveData: false, fileStorage: LocalNsUserDefaultsStorage(), httpUtilities: FakeHttpUtilities())
		//let fakeInternalPlayer = FakeInternalPlayer()
		//let player = RxPlayer(repeatQueue: false, internalPlayer: fakeInternalPlayer, downloadManager: downloadManager)
		let player = RxPlayer(repeatQueue: false, downloadManager: downloadManager, streamPlayerUtilities: FakeStreamPlayerUtilities())
		player.initWithNewItems(["https://test.com/track1.mp3", "https://test.com/track2.mp3", "https://test.com/track3.mp3"])
		player.toNext()
		
		//player.playerEvents.dispatchPlayerControlEvents().subscribe().addDisposableTo(bag)
		//player.playerEvents.streamContent().subscribe().addDisposableTo(bag)
		
		let expectation = expectationWithDescription("Should switch to next item")
		var skipped = false
		player.currentItem.bindNext { item in
			if !skipped { skipped = true }
			else {
				XCTAssertEqual(item?.streamIdentifier.streamResourceUid, "https://test.com/track2.mp3", "Check current item changed to next")
				expectation.fulfill()
			}
		}.addDisposableTo(bag)
		
		// send notification about finishing current item playing
		//fakeInternalPlayer.publishSubject.onNext(.FinishPlayingCurrentItem(player))
		(player.internalPlayer as! FakeInternalPlayer).finishPlayingCurrentItem()
		
		waitForExpectationsWithTimeout(1, handler: nil)
		XCTAssertEqual(player.current?.streamIdentifier.streamResourceUid, "https://test.com/track2.mp3", "Check correct current item")
	}
	
	func testSwitchCurrentItemToNilAfterFinishing() {
		let downloadManager = DownloadManager(saveData: false, fileStorage: LocalNsUserDefaultsStorage(), httpUtilities: FakeHttpUtilities())
		//let fakeInternalPlayer = FakeInternalPlayer()
		//let player = RxPlayer(repeatQueue: false, internalPlayer: fakeInternalPlayer, downloadManager: downloadManager)
		let player = RxPlayer(repeatQueue: false, downloadManager: downloadManager, streamPlayerUtilities: FakeStreamPlayerUtilities())
		player.initWithNewItems(["https://test.com/track1.mp3", "https://test.com/track2.mp3", "https://test.com/track3.mp3"])
		player.current = player.last
		
		//player.playerEvents.dispatchPlayerControlEvents().subscribe().addDisposableTo(bag)
		//player.playerEvents.streamContent().subscribe().addDisposableTo(bag)
		
		let expectation = expectationWithDescription("Should switch to next item")
		var skipped = false
		player.currentItem.bindNext { item in
			if !skipped { skipped = true }
			else {
				XCTAssertNil(item, "Current item should be nil")
				expectation.fulfill()
			}
			}.addDisposableTo(bag)
		
		// send notification about finishing current item playing
		//fakeInternalPlayer.publishSubject.onNext(.FinishPlayingCurrentItem(player))
		(player.internalPlayer as! FakeInternalPlayer).finishPlayingCurrentItem()
		
		waitForExpectationsWithTimeout(1, handler: nil)
		XCTAssertNil(player.current, "Current item should be nil")
	}
}