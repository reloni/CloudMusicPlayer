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
		let metadata = player.loadFileMetadata(item.streamIdentifier, file: metadataFile, utilities: StreamPlayerUtilities())
		XCTAssertEqual(metadata?.album, "Of Her")
		XCTAssertEqual(metadata?.artist, "Yusuke Tsutsumi")
		XCTAssertEqual(metadata?.duration?.asTimeString, "04: 27")
		XCTAssertEqual(metadata?.title, "Love")
		XCTAssertNotNil(metadata?.artwork)
	}
	
	func testNotLoadMetadataFromNotExistedFile() {
		let player = RxPlayer()
		let item = player.addLast("https://testitem.com")
		XCTAssertNil(player.loadFileMetadata(item.streamIdentifier, file: NSURL(fileURLWithPath: "/Documents/File.mp3"), utilities: StreamPlayerUtilities()), "Should not return metadata")
	}
	
	func testLoadMetadataFromCachedFile() {
		let storage = LocalNsUserDefaultsStorage()
		let metadataFile = NSURL(fileURLWithPath: NSBundle(forClass: RxPlayerQueueItemTests.self).pathForResource("MetadataTest", ofType: "mp3")!)
		let copiedFile = storage.tempStorageDirectory.URLByAppendingPathComponent("FileWithMetadata.mp3")
		let _ = try? NSFileManager.defaultManager().copyItemAtURL(metadataFile, toURL: copiedFile)
		storage.tempStorageDictionary["https://testitem.com"] = copiedFile.lastPathComponent
		
		//DownloadManager.initWithInstance(DownloadManager(saveData: false, fileStorage: storage, httpUtilities: FakeHttpUtilities()))
		let downloadManager = DownloadManager(saveData: false, fileStorage: storage, httpUtilities: FakeHttpUtilities())
		
		
		let player = RxPlayer(repeatQueue: false, internalPlayer: InternalPlayer(), downloadManager: downloadManager,
		                      streamPlayerUtilities: StreamPlayerUtilities(), mediaLibrary: NonRetentiveMediaLibrary())
		player.rx_observe().dispatchPlayerControlEvents().subscribe().addDisposableTo(bag)
		player.rx_observe().streamContent().subscribe().addDisposableTo(bag)
		
		let item = player.addLast("https://testitem.com")
		
		let metadataLoadExpectation = expectationWithDescription("Should load metadta from local file")
		
		player.loadMetadata(item.streamIdentifier, downloadManager: downloadManager, utilities: StreamPlayerUtilities()).bindNext { metadata in
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
	
	func testReceiveErrorWhileLoadMetadata() {
		let storage = LocalNsUserDefaultsStorage()
		
		let streamObserver = NSURLSessionDataEventsObserver()
		let httpUtilities = FakeHttpUtilities()
		httpUtilities.streamObserver = streamObserver
		let session = FakeSession(fakeTask: FakeDataTask(completion: nil))
		httpUtilities.fakeSession = session
		let downloadManager = DownloadManager(saveData: false, fileStorage: storage, httpUtilities: httpUtilities)
		
		let player = RxPlayer(repeatQueue: false, internalPlayer: InternalPlayer(), downloadManager: downloadManager,
		                      streamPlayerUtilities: StreamPlayerUtilities(), mediaLibrary: NonRetentiveMediaLibrary())
		player.rx_observe().dispatchPlayerControlEvents().subscribe().addDisposableTo(bag)
		player.rx_observe().streamContent().subscribe().addDisposableTo(bag)
		
		let item = player.addLast("https://testitem.com")
		
		let metadataLoadExpectation = expectationWithDescription("Should load metadta from local file")
		let downloadTaskCancelationExpectation = expectationWithDescription("Should cancel task")
		
		// simulate http request failure and send error
		session.task?.taskProgress.bindNext { e in
			if case FakeDataTaskMethods.resume(let tsk) = e {
				dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
					streamObserver.sessionEventsSubject.onNext(.didCompleteWithError(session: session, dataTask: tsk,
						error: NSError(domain: "HttpRequestTests", code: 17, userInfo: nil)))
				}
			} else if case FakeDataTaskMethods.cancel = e {
				downloadTaskCancelationExpectation.fulfill()
			}
			}.addDisposableTo(bag)
		
		player.loadMetadata(item.streamIdentifier, downloadManager: downloadManager, utilities: StreamPlayerUtilities()).doOnError { error in
			if (error as NSError).code == 17 {
				metadataLoadExpectation.fulfill()
			}
			}.subscribe().addDisposableTo(bag)
		
		waitForExpectationsWithTimeout(1, handler: nil)
	}
	
	func testReturnMetadataFromRemote() {
		//let player = RxPlayer()
		//player.rx_observe().dispatchPlayerControlEvents().subscribe().addDisposableTo(bag)
		
		let storage = LocalNsUserDefaultsStorage()
		
		let streamObserver = NSURLSessionDataEventsObserver()
		let httpUtilities = FakeHttpUtilities()
		httpUtilities.streamObserver = streamObserver
		let session = FakeSession(fakeTask: FakeDataTask(completion: nil))
		httpUtilities.fakeSession = session
		let downloadManager = DownloadManager(saveData: false, fileStorage: storage, httpUtilities: httpUtilities)
		
		let player = RxPlayer(repeatQueue: false, internalPlayer: InternalPlayer(), downloadManager: downloadManager,
		                      streamPlayerUtilities: StreamPlayerUtilities(), mediaLibrary: NonRetentiveMediaLibrary())
		player.rx_observe().dispatchPlayerControlEvents().subscribe().addDisposableTo(bag)
		player.rx_observe().streamContent().subscribe().addDisposableTo(bag)
		
		let item = player.addLast("https://testitem.com")
		
		let metadataLoadExpectation = expectationWithDescription("Should load metadta from local file")
		let downloadTaskCancelationExpectation = expectationWithDescription("Should cancel task")
		
		// simulate http request 
		session.task?.taskProgress.bindNext { e in
			if case FakeDataTaskMethods.resume(let tsk) = e {
				dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
					let response = FakeResponse(contentLenght: 1024 * 256)
					response.MIMEType = "audio/mpeg"
					streamObserver.sessionEventsSubject.onNext(.didReceiveResponse(session: session, dataTask: tsk,
						response: response, completion: { _ in }))
					
					guard let data = NSData(contentsOfURL:
						NSURL(fileURLWithPath: NSBundle(forClass: RxPlayerQueueItemTests.self).pathForResource("MetadataTest", ofType: "mp3")!)) else {
							return
					}
					
					streamObserver.sessionEventsSubject.onNext(.didReceiveData(session: session, dataTask: tsk, data: data))
				}
			} else if case FakeDataTaskMethods.cancel = e {
				downloadTaskCancelationExpectation.fulfill()
			}
			}.addDisposableTo(bag)
		
		player.loadMetadata(item.streamIdentifier, downloadManager: downloadManager, utilities: StreamPlayerUtilities()).bindNext { metadata in
			XCTAssertEqual(metadata?.album, "Of Her")
			XCTAssertEqual(metadata?.artist, "Yusuke Tsutsumi")
			XCTAssertEqual(metadata?.duration?.asTimeString, "04: 27")
			XCTAssertEqual(metadata?.title, "Love")
			XCTAssertNotNil(metadata?.artwork)
			
			metadataLoadExpectation.fulfill()
			}.addDisposableTo(bag)
		
		waitForExpectationsWithTimeout(1, handler: nil)
	}
	
	func testRetirnNilMetadataForItemWithUnknownScheme() {
		//let player = RxPlayer()
		//player.rx_observe().dispatchPlayerControlEvents().subscribe().addDisposableTo(bag)
		
		let storage = LocalNsUserDefaultsStorage()
		let downloadManager = DownloadManager(saveData: false, fileStorage: storage, httpUtilities: HttpUtilities())
		
		let player = RxPlayer(repeatQueue: false, internalPlayer: InternalPlayer(), downloadManager: downloadManager,
		                      streamPlayerUtilities: StreamPlayerUtilities(), mediaLibrary: NonRetentiveMediaLibrary())
		player.rx_observe().dispatchPlayerControlEvents().subscribe().addDisposableTo(bag)
		player.rx_observe().streamContent().subscribe().addDisposableTo(bag)
		
		let item = player.addLast("wrong://testitem.com")
		
		let metadataLoadExpectation = expectationWithDescription("Should not load metadata for incorrect scheme")
		
		player.loadMetadata(item.streamIdentifier, downloadManager: downloadManager, utilities: StreamPlayerUtilities()).doOnError { error in
			if (error as NSError).code == DownloadManagerError.UnsupportedUrlSchemeOrFileNotExists.rawValue {
				metadataLoadExpectation.fulfill()
			}
		}.subscribe().addDisposableTo(bag)
		
		waitForExpectationsWithTimeout(1, handler: nil)
	}
}
