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
		request = FakeRequest()
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
		utilities = nil
		streamObserver = nil
	}
	
	func testReturnNSError() {
		session.task?.taskProgress.bindNext { [unowned self] progress in
			if case .resume(let tsk) = progress {
				XCTAssertEqual(tsk.originalRequest?.URL, self.request.URL)
				
				dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) { [unowned self] in
					//tsk.completion?(nil, nil, NSError(domain: "HttpRequestTests", code: 1, userInfo: nil))
					//self.streamObserver.subject.onNext(.Error(NSError(domain: "HttpRequestTests", code: 1, userInfo: nil)))
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
}
