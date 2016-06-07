//
//  RealmRxPlayerPersistanceProviderTests.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 06.06.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import XCTest
@testable import CloudMusicPlayer
import RealmSwift

class RealmRxPlayerPersistanceProviderTests: XCTestCase {
	
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
		Realm.Configuration.defaultConfiguration.inMemoryIdentifier = self.name
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
	}
	
	func testSavePlayerState() {
		let player = RxPlayer()
		player.repeatQueue = true
		player.shuffleQueue = true
		
		let queueItems: [StreamResourceIdentifier] = ["https://test.com", "https://test2.com", "https://test3.com"]
		player.initWithNewItems(queueItems, shuffle: false)
		player.current = player.first
		
		let persistence = RealmRxPlayerPersistenceProvider()
		try! persistence.savePlayerState(player)
		
		let realm = try! Realm()
		
		let playerState = realm.objects(RealmPlayerState).first
		
		XCTAssertEqual(true, playerState?.shuffle)
		XCTAssertEqual(true, playerState?.repeatQueue)
		XCTAssertEqual(3, playerState?.queueItems.count)
		XCTAssertEqual(queueItems.map { $0.streamResourceUid }, playerState!.queueItems.map { $0.uid })
		XCTAssertEqual(player.current?.streamIdentifier.streamResourceUid, playerState?.currentItem?.uid)
	}
	
	func testLoadPlayerState() {
		let realm = try! Realm()
		
		let state = RealmPlayerState()
		state.repeatQueue = true
		state.shuffle = true
		
		let queueItems: [StreamResourceIdentifier] = ["https://test.com", "https://test2.com", "https://test3.com"]
		
		state.queueItems.appendContentsOf(queueItems.map {
			let qi = RealmPlayerQueueItem()
			qi.uid = $0.streamResourceUid
			return qi
		})
				
		try! realm.write {
			realm.add(state)
			state.currentItem = realm.objects(RealmPlayerQueueItem).filter("uid = %@", "https://test.com").first
		}
		
		let player = RxPlayer()
		let persistence = RealmRxPlayerPersistenceProvider()
		try! persistence.loadPlayerState(player)
		
		XCTAssertEqual(true, player.repeatQueue)
		XCTAssertEqual(true, player.shuffleQueue)
		XCTAssertEqual(queueItems.count, player.currentItems.count)
		XCTAssertEqual(queueItems.map { $0.streamResourceUid }, player.currentItems.map { $0.streamIdentifier.streamResourceUid })
		XCTAssertEqual("https://test.com", player.current?.streamIdentifier.streamResourceUid)
	}
	
	func testLoadPlayerStateWithCustomStreamResource() {
		let realm = try! Realm()
		
		let state = RealmPlayerState()
		state.repeatQueue = true
		state.shuffle = true
		
		let queueItems: [StreamResourceIdentifier] = ["https://test.com", "https://test2.com", "https://test3.com"]
		
		state.queueItems.appendContentsOf(queueItems.map {
			let qi = RealmPlayerQueueItem()
			qi.uid = $0.streamResourceUid
			return qi
			})
		
		try! realm.write {
			realm.add(state)
			state.currentItem = realm.objects(RealmPlayerQueueItem).filter("uid = %@", "https://test.com").first
		}
		
		let player = RxPlayer()
		let streamResourceLoader = FakeStreamResourceLoader(items: queueItems.map { $0.streamResourceUid })
		player.streamResourceLoaders.append(streamResourceLoader)
		let persistence = RealmRxPlayerPersistenceProvider()
		try! persistence.loadPlayerState(player)
		
		XCTAssertEqual(queueItems.count, player.currentItems.count)
		XCTAssertEqual(queueItems.count, player.currentItems.filter { $0.streamIdentifier is FakeStreamResourceIdentifier }.count)
		XCTAssertEqual("https://test.com", player.current?.streamIdentifier.streamResourceUid)
	}
}
