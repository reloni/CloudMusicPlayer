//
//  StreamDataTaskTests.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 18.03.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import XCTest
import RxSwift
@testable import CloudMusicPlayer

class StreamDataTaskTests: XCTestCase {
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
	
	func testReceiveCorrectData() {
		let testData = ["First", "Second", "Third", "Fourth"]
		var dataSended:UInt64 = 0
		
		let expectation = expectationWithDescription("Should return correct data and invalidate session")
		
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
					expectation.fulfill()
				}
			}
		}.addDisposableTo(bag)
		
		var receiveCounter = 0
		
		httpClient.loadStreamData(request, sessionConfiguration: .defaultSessionConfiguration()).bindNext { result in
			if case .StreamedData(let data) = result {
				XCTAssertEqual(String(data: data, encoding: NSUTF8StringEncoding), testData[receiveCounter], "Check correct chunk of data received")
				receiveCounter += 1
			} else if case .Success(let dataReceived) = result {
				XCTAssertEqual(dataReceived, dataSended, "Should receive correct amount of data")
				XCTAssertEqual(receiveCounter, testData.count, "Should receive correct amount of data chuncks")
			}
		}.addDisposableTo(bag)
		
		
		waitForExpectationsWithTimeout(1, handler: nil)
		XCTAssertTrue(self.session.isInvalidatedAndCanceled, "Session should be invalidated")
	}
	
	func testReturnNSError() {
		session.task?.taskProgress.bindNext { [unowned self] progress in
			if case .resume(let tsk) = progress {
				XCTAssertEqual(tsk.originalRequest?.URL, self.request.URL, "Check correct task url")
				dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) { [unowned self] in
					self.streamObserver.sessionEvents.onNext(.didCompleteWithError(session: self.session, dataTask: tsk, error: NSError(domain: "HttpRequestTests", code: 1, userInfo: nil)))
				}
			}
		}.addDisposableTo(bag)

		let expectation = expectationWithDescription("Should return NSError")
		httpClient.loadStreamData(request, sessionConfiguration: .defaultSessionConfiguration()).bindNext { result in
			if case .Error(let error) = result where error.code == 1 {
				expectation.fulfill()
			}
		}.addDisposableTo(bag)

		waitForExpectationsWithTimeout(1, handler: nil)
	}
	
	func testDidReceiveResponse() {
		var disposition: NSURLSessionResponseDisposition?
		let fakeResponse = FakeResponse(contentLenght: 64587)
		session.task?.taskProgress.bindNext { [unowned self] progress in
			if case .resume(let tsk) = progress {
				XCTAssertEqual(tsk.originalRequest?.URL, self.request.URL, "Check correct task url")
				let completion: (NSURLSessionResponseDisposition) -> () = { disp in
					disposition = disp
				}
				dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) { [unowned self] in
					self.streamObserver.sessionEvents.onNext(.didReceiveResponse(session: self.session, dataTask: tsk, response: fakeResponse, completion: completion))
				}
			}
			}.addDisposableTo(bag)
		
		let expectation = expectationWithDescription("Should return correct response")
		httpClient.loadStreamData(request, sessionConfiguration: .defaultSessionConfiguration()).bindNext { result in
			if case .StreamedResponse(let response) = result {
				XCTAssertEqual(response.expectedContentLength, fakeResponse.expectedContentLength)
				expectation.fulfill()
			}
		}.addDisposableTo(bag)
		
		waitForExpectationsWithTimeout(1, handler: nil)
		XCTAssertEqual(disposition, NSURLSessionResponseDisposition.Allow, "Should set correct completion disposition in completionHandler")
	}
	
	func testCreateCorrectTask() {
		let config = NSURLSessionConfiguration.defaultSessionConfiguration()
		config.HTTPCookieAcceptPolicy = .Always
		let task = StreamDataTask(request: request, httpUtilities: utilities, sessionConfiguration: config)
		XCTAssertEqual(task.sessionConfiguration, config)
		XCTAssertTrue(task.dataTask.getOriginalMutableUrlRequest() as? FakeRequest === request)
	}
}
