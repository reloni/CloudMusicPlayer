//
//  MetadataLoadTests.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 14.04.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import XCTest
@testable import CloudMusicPlayer
import AVFoundation
import RxSwift

class RxPlayerQueueItemTests: XCTestCase {
	let bag = DisposeBag()
	
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
	}
	
	func testLoadMetadataFromFile() {
		let metadataFile = NSURL(fileURLWithPath: NSBundle(forClass: RxPlayerQueueItemTests.self).pathForResource("MetadataTest", ofType: "mp3")!)
		let player = RxPlayer()
		let item = player.addLast("http://testitem.com")
		let metadata = item.loadFileMetadata(metadataFile, utilities: StreamPlayerUtilities())
		XCTAssertEqual(metadata?.album, "Of Her")
		XCTAssertEqual(metadata?.artist, "Yusuke Tsutsumi")
		XCTAssertEqual(metadata?.duration?.asTimeString, "04: 27")
		XCTAssertEqual(metadata?.title, "Love")
		XCTAssertNotNil(metadata?.artwork)
	}
	
	func testLoadMetadataFromCachedFile() {
		let player = RxPlayer()
		player.rx_observe().dispatchPlayerControlEvents().subscribe().addDisposableTo(bag)
		
		let storage = LocalNsUserDefaultsStorage()
		let metadataFile = NSURL(fileURLWithPath: NSBundle(forClass: RxPlayerQueueItemTests.self).pathForResource("MetadataTest", ofType: "mp3")!)
		let copiedFile = storage.tempSaveStorageDirectory.URLByAppendingPathComponent("FileWithMetadata.mp3")
		let _ = try? NSFileManager.defaultManager().copyItemAtURL(metadataFile, toURL: copiedFile)
		storage.tempSaveStorageDictionary["https://testitem.com"] = copiedFile.lastPathComponent
		
		//DownloadManager.initWithInstance(DownloadManager(saveData: false, fileStorage: storage, httpUtilities: FakeHttpUtilities()))
		let downloadManager = DownloadManager(saveData: false, fileStorage: storage, httpUtilities: FakeHttpUtilities())
		
		player.rx_observe().streamContent(StreamPlayerUtilities(), downloadManager: downloadManager).subscribe().addDisposableTo(bag)
		
		let item = player.addLast("https://testitem.com")
		
		let metadataLoadExpectation = expectationWithDescription("Should load metadta from local file")
		
		item.loadMetadata(downloadManager, utilities: StreamPlayerUtilities()).bindNext { metadata in
			XCTAssertEqual(metadata?.album, "Of Her")
			XCTAssertEqual(metadata?.artist, "Yusuke Tsutsumi")
			XCTAssertEqual(metadata?.duration?.asTimeString, "04: 27")
			XCTAssertEqual(metadata?.title, "Love")
			XCTAssertNotNil(metadata?.artwork)
			
			metadataLoadExpectation.fulfill()
		}.addDisposableTo(bag)
		
		waitForExpectationsWithTimeout(1, handler: nil)
		
		copiedFile.deleteFile()
	}
	
	func testReturnNilMetadataIfReceiveError() {
		let player = RxPlayer()
		player.rx_observe().dispatchPlayerControlEvents().subscribe().addDisposableTo(bag)
		
		let storage = LocalNsUserDefaultsStorage()
		
		let streamObserver = NSURLSessionDataEventsObserver()
		let httpUtilities = FakeHttpUtilities()
		httpUtilities.streamObserver = streamObserver
		let session = FakeSession(fakeTask: FakeDataTask(completion: nil))
		httpUtilities.fakeSession = session
		let downloadManager = DownloadManager(saveData: false, fileStorage: storage, httpUtilities: httpUtilities)
		
		player.rx_observe().streamContent(StreamPlayerUtilities(), downloadManager: downloadManager).subscribe().addDisposableTo(bag)
		
		let item = player.addLast("https://testitem.com")
		
		let metadataLoadExpectation = expectationWithDescription("Should load metadta from local file")
		
		// simulate http request failure and send error
		session.task?.taskProgress.bindNext { e in
			if case FakeDataTaskMethods.resume(let tsk) = e {
				dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
					streamObserver.sessionEventsSubject.onNext(.didCompleteWithError(session: session, dataTask: tsk,
						error: NSError(domain: "HttpRequestTests", code: 1, userInfo: nil)))
				}
			}
		}.addDisposableTo(bag)
		
		item.loadMetadata(downloadManager, utilities: StreamPlayerUtilities()).bindNext { metadata in
			XCTAssertNil(metadata, "Should return nil as metadata due internal http error")
			metadataLoadExpectation.fulfill()
		}.addDisposableTo(bag)
		
		waitForExpectationsWithTimeout(1, handler: nil)
	}
}
