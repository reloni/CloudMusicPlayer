//
//  StreamDataCacheTaskTests.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 23.03.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import XCTest
import SwiftyJSON
import RxSwift
@testable import CloudMusicPlayer

class StreamDataCacheTaskTests: XCTestCase {
	var bag: DisposeBag!
	var request: FakeRequest!
	var session: FakeSession!
	var utilities: FakeHttpUtilities!
	var httpClient: HttpClientProtocol!
	var streamObserver: UrlSessionStreamObserver!
	
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
		
		bag = DisposeBag()
		streamObserver = UrlSessionStreamObserver()
		request = FakeRequest(url: NSURL(string: "https://test.com"))
		session = FakeSession(fakeTask: FakeDataTask(completion: nil))
		utilities = FakeHttpUtilities()
		utilities.fakeSession = session
		utilities.streamObserver = streamObserver
		httpClient = HttpClient(urlSession: session, httpUtilities: utilities)
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
		bag = nil
		request = nil
		session = nil
		utilities.streamObserver = nil
		utilities = nil
		streamObserver = nil
	}
	
	func testCorrectTargetMimeTypeAndExtension() {
		let task = utilities.createCacheDataTask(request, sessionConfiguration: NSURLSession.defaultConfig, saveCachedData: false, targetMimeType: "audio/mpeg")
		XCTAssertEqual(task.mimeType, "public.mp3", "Check correct mime type")
		XCTAssertEqual(task.fileExtension, "mp3", "Check correct file extension")
	}
	
	func testNillMimeTypeAndExtensionWithoutResponseAndTargetMimeType() {
		let task = utilities.createCacheDataTask(request, sessionConfiguration: NSURLSession.defaultConfig, saveCachedData: false, targetMimeType: nil)
		XCTAssertNil(task.mimeType)
		XCTAssertNil(task.fileExtension                                                                                   )
	}
	
	func testCorrectMimeTypeAndExtensionAfterReceivingResponse() {
		let task = utilities.createCacheDataTask(request, sessionConfiguration: NSURLSession.defaultConfig, saveCachedData: false, targetMimeType: nil)
	
		session.task?.taskProgress.bindNext { [unowned self] progress in
			if case .resume(let tsk) = progress {
				XCTAssertEqual(tsk.originalRequest?.URL, self.request.URL, "Check correct task url")
				let completion: (NSURLSessionResponseDisposition) -> () = { _ in }
				let fakeResponse = FakeResponse(contentLenght: 10)
				fakeResponse.MIMEType = "audio/aac"
				dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) { [unowned self] in
					self.streamObserver.sessionEvents.onNext(.didReceiveResponse(session: self.session, dataTask: tsk, response: fakeResponse, completion: completion))
				}
			}
		}.addDisposableTo(bag)
		
		let responseExpectation = expectationWithDescription("Should receive response")
		task.taskProgress.bindNext { result in
			if case .ReceiveResponse(let response) = result {
				XCTAssertNotNil(task.response)
				XCTAssertTrue(task.response as? FakeResponse === response as? FakeResponse)
				XCTAssertEqual(task.response?.MIMEType, "audio/aac")
				XCTAssertEqual(task.mimeType, "public.aac-audio")
				XCTAssertEqual(task.fileExtension, "aac")
				responseExpectation.fulfill()
			}
		}.addDisposableTo(bag)
		
		task.resume()
		
		waitForExpectationsWithTimeout(1, handler: nil)
	}
	
	func testCacheCorrectData() {
		let testData = ["First", "Second", "Third", "Fourth"]
		var dataSended: UInt64 = 0
		
		let sessionInvalidationExpectation = expectationWithDescription("Should return correct data and invalidate session")
		
		session.task?.taskProgress.bindNext { [unowned self] progress in
			if case .resume(let tsk) = progress {
				XCTAssertEqual(tsk.originalRequest?.URL, self.request.URL, "Check correct task url")
				dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) { [unowned self] in
					for i in 0...testData.count - 1 {
						let sendData = testData[i].dataUsingEncoding(NSUTF8StringEncoding)!
						dataSended += UInt64(sendData.length)
						self.streamObserver.sessionEvents.onNext(.didReceiveData(session: self.session, dataTask: tsk, data: sendData))
					}
					self.streamObserver.sessionEvents.onNext(.didCompleteWithError(session: self.session, dataTask: tsk, error: nil))
				}
			} else if case .cancel = progress {
				// task will be canceled if method cancelAndInvalidate invoked on FakeSession,
				// so fulfill expectation here after checking if session was invalidated
				if self.session.isInvalidatedAndCanceled {
					// set reference to nil (simutale real session dispose)
					self.utilities.streamObserver = nil
					self.streamObserver = nil
					sessionInvalidationExpectation.fulfill()
				}
			}
		}.addDisposableTo(bag)
		
		var receiveChunkCounter = 0
		
		let successExpectation = expectationWithDescription("Should successfuly cache data")
		
		httpClient.loadAndCacheData(request, sessionConfiguration: NSURLSession.defaultConfig, saveCacheData: false, targetMimeType: nil).bindNext { result in
			if case .CacheNewData = result {
				receiveChunkCounter += 1
			} else if case .Success(let cashedDataLen) = result {
				XCTAssertEqual(cashedDataLen, dataSended, "Should cache all sended data")
				XCTAssertEqual(testData.count, receiveChunkCounter, "Should cache correct data chunk amount")
				successExpectation.fulfill()
			} else if case .SuccessWithCache = result {
				XCTFail("Shouldn't cache data on disk")
			}
		}.addDisposableTo(bag)
		
		waitForExpectationsWithTimeout(1, handler: nil)
		XCTAssertTrue(self.session.isInvalidatedAndCanceled, "Session should be invalidated")
	}
	
	func testCacheCorrectDataOnDisk() {
		let testData = ["First", "Second", "Third", "Fourth"]
		let sendedData = NSMutableData()
		
		let sessionInvalidationExpectation = expectationWithDescription("Should return correct data and invalidate session")
		
		session.task?.taskProgress.bindNext { [unowned self] progress in
			if case .resume(let tsk) = progress {
				XCTAssertEqual(tsk.originalRequest?.URL, self.request.URL, "Check correct task url")
				dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) { [unowned self] in
					for i in 0...testData.count - 1 {
						let sendData = testData[i].dataUsingEncoding(NSUTF8StringEncoding)!
						sendedData.appendData(sendData)
						self.streamObserver.sessionEvents.onNext(.didReceiveData(session: self.session, dataTask: tsk, data: sendData))
					}
					self.streamObserver.sessionEvents.onNext(.didCompleteWithError(session: self.session, dataTask: tsk, error: nil))
				}
			} else if case .cancel = progress {
				// task will be canceled if method cancelAndInvalidate invoked on FakeSession,
				// so fulfill expectation here after checking if session was invalidated
				if self.session.isInvalidatedAndCanceled {
					// set reference to nil (simutale real session dispose)
					self.utilities.streamObserver = nil
					self.streamObserver = nil
					sessionInvalidationExpectation.fulfill()
				}
			}
		}.addDisposableTo(bag)
		
		var receiveChunkCounter = 0
		
		let successExpectation = expectationWithDescription("Should successfuly cache data")
		
		//let task = utilities.createCacheDataTask(request, sessionConfiguration: NSURLSession.defaultConfig, saveCachedData: true, targetMimeType: nil)
		
		httpClient.loadAndCacheData(request, sessionConfiguration: NSURLSession.defaultConfig, saveCacheData: true, targetMimeType: nil).bindNext { result in
			if case .CacheNewData = result {
				receiveChunkCounter += 1
			} else if case .Success = result {
				XCTFail("Shouldn't invoke Success event")
			} else if case .SuccessWithCache(let url) = result {
				if let data = NSData(contentsOfURL: url) {
					XCTAssertTrue(sendedData.isEqualToData(data), "Check equality of sended and received data")
					try! NSFileManager.defaultManager().removeItemAtURL(url)
				} else {
					XCTFail("Cached data should be equal to sended data")
				}
				XCTAssertEqual(testData.count, receiveChunkCounter, "Should cache correct data chunk amount")
				successExpectation.fulfill()
			}
		}.addDisposableTo(bag)
		
		//task.resume()
		
		waitForExpectationsWithTimeout(1, handler: nil)
		XCTAssertTrue(self.session.isInvalidatedAndCanceled, "Session should be invalidated")
	}
	
	func testReceiveError() {
		session.task?.taskProgress.bindNext { [unowned self] progress in
			if case .resume(let tsk) = progress {
				XCTAssertEqual(tsk.originalRequest?.URL, self.request.URL, "Check correct task url")
				dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) { [unowned self] in
					self.streamObserver.sessionEvents.onNext(.didCompleteWithError(session: self.session, dataTask: tsk, error: NSError(domain: "HttpRequestTests", code: 1, userInfo: nil)))
				}
			}
		}.addDisposableTo(bag)
		
		let expectation = expectationWithDescription("Should return NSError")
		
		httpClient.loadAndCacheData(request, sessionConfiguration: NSURLSession.defaultConfig, saveCacheData: false, targetMimeType: nil).bindNext { result in
			if case .Error(let error) = result where error.code == 1 {
				expectation.fulfill()
			}
		}.addDisposableTo(bag)
		
		waitForExpectationsWithTimeout(1, handler: nil)
	}
}
