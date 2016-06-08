//
//  LocalFileStreamDataTaskTests.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 12.04.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import XCTest
import RxSwift
import CloudMusicPlayer

class LocalFileStreamDataTaskTests: XCTestCase {
	let bag = DisposeBag()
	
	
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
	}
	
	func testInitTaskForExistedFile() {
		let temp = NSFileManager.temporaryDirectory
		let file = temp.URLByAppendingPathComponent("\(NSUUID().UUIDString).dat")
		NSFileManager.defaultManager().createFileAtPath(file.path!, contents: nil, attributes: nil)
		let task = LocalFileStreamDataTask(uid: "\(NSUUID().UUIDString)", filePath: file.path!)
		XCTAssertNotNil(task)
		let _ = try? NSFileManager.defaultManager().removeItemAtURL(file)
	}
	
	func testNotInitTaskForNotExistedFile() {
		let temp = NSFileManager.temporaryDirectory
		let file = temp.URLByAppendingPathComponent("\(NSUUID().UUIDString).dat")
		let task = LocalFileStreamDataTask(uid: "\(NSUUID().UUIDString)", filePath: file.path!)
		XCTAssertNil(task)
	}
	
	func testStreamLocalFile() {
		let temp = NSFileManager.temporaryDirectory
		let file = temp.URLByAppendingPathComponent("\(NSUUID().UUIDString).mp3")
		let storedData = "some stored data".dataUsingEncoding(NSUTF8StringEncoding)!
		NSFileManager.defaultManager().createFileAtPath(file.path!, contents: storedData, attributes: nil)
		let task = LocalFileStreamDataTask(uid: NSUUID().UUIDString, filePath: file.path!)
		
		var receiveResponceExpectation: XCTestExpectation? = expectationWithDescription("Should receive responce")
		var cacheDataExpectation: XCTestExpectation? = expectationWithDescription("Should cache data")
		var successExpectation: XCTestExpectation? = expectationWithDescription("Should successifully complete")
		
		task?.taskProgress.bindNext { result in
			guard case Result.success(let box) = result else { return }
			if case StreamTaskEvents.ReceiveResponse(let response) = box.value {
				XCTAssertEqual(response.expectedContentLength, Int64(storedData.length))
				XCTAssertEqual(response.MIMEType, "audio/mpeg")
				receiveResponceExpectation?.fulfill()
				receiveResponceExpectation = nil
			} else if case StreamTaskEvents.CacheData(let provider) = box.value {
				XCTAssertTrue(provider.getCurrentData().isEqualToData(storedData))
				XCTAssertEqual(provider.contentMimeType, "audio/mpeg")
				cacheDataExpectation?.fulfill()
				cacheDataExpectation = nil
			} else if case StreamTaskEvents.Success = box.value {
				successExpectation?.fulfill()
				successExpectation = nil
			}
		}.addDisposableTo(bag)
		
		task?.resume()
		
		waitForExpectationsWithTimeout(1, handler: nil)
		
		let _ = try? NSFileManager.defaultManager().removeItemAtURL(file)
	}
	
	func testNotStreamIfCannotGetNSData() {
		let temp = NSFileManager.temporaryDirectory
		let file = temp.URLByAppendingPathComponent("\(NSUUID().UUIDString).mp3")
		let storedData = "some stored data".dataUsingEncoding(NSUTF8StringEncoding)!
		NSFileManager.defaultManager().createFileAtPath(file.path!, contents: storedData, attributes: nil)
		let task = LocalFileStreamDataTask(uid: NSUUID().UUIDString, filePath: file.path!)
		
		// delete file
		let _ = try? NSFileManager.defaultManager().removeItemAtURL(file)
		
		let successExpectation = expectationWithDescription("Should successifully complete")
		
		task?.taskProgress.bindNext { e in
			guard case Result.success(let box) = e else { return }
			if case StreamTaskEvents.ReceiveResponse = box.value {
				XCTFail("Should not rise ReceiveResponse this event")
			} else if case StreamTaskEvents.CacheData = box.value {
				XCTFail("Should not rise CacheData this event")
			} else if case StreamTaskEvents.Success(let provider) = box.value {
				XCTAssertNil(provider, "Should not send any provider")
				successExpectation.fulfill()
			}
			}.addDisposableTo(bag)
		
		task?.resume()
		
		waitForExpectationsWithTimeout(1, handler: nil)
	}
}
