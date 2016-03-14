//
//  HttpRequestTests.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 14.03.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import XCTest
import CloudMusicPlayer
import RxSwift
import SwiftyJSON

class HttpRequestTests: XCTestCase {
	var bag: DisposeBag!
	var request: FakeRequest!
	var session: FakeSession!
	
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
		
		bag = DisposeBag()
		request = FakeRequest()
		session = FakeSession(fakeTask: FakeDataTask(completion: nil))
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
		bag = nil
		request = nil
		session = nil
	}
	
	func testReturnData() {
		session.task?.taskProgress.bindNext { progress in
			if case .resume(let tsk) = progress {
				dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
					tsk.completion?("Test data".dataUsingEncoding(NSUTF8StringEncoding), nil, nil)
				}
			}
			}.addDisposableTo(bag)
		
		let expectation = expectationWithDescription("Should return string as NSData")
		
		HttpRequest.sharedInstance.loadData(request, session: session).bindNext { result in
			if case .SuccessData(let data) = result where String(data: data, encoding: NSUTF8StringEncoding) == "Test data" {
				expectation.fulfill()
			}
			}.addDisposableTo(bag)
		
		waitForExpectationsWithTimeout(1, handler: nil)
	}
	
	func testReturnNilData() {
		session.task?.taskProgress.bindNext { progress in
			if case .resume(let tsk) = progress {
				dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
					tsk.completion?(nil, nil, nil)
				}
			}
			}.addDisposableTo(bag)
		
		let expectation = expectationWithDescription("Should return nil (as simple Success)")
		
		HttpRequest.sharedInstance.loadData(request, session: session).bindNext { result in
			if case .Success = result {
				expectation.fulfill()
			}
			}.addDisposableTo(bag)
		
		waitForExpectationsWithTimeout(1, handler: nil)
	}
	
	func testReturnNSError() {
		session.task?.taskProgress.bindNext { progress in
			if case .resume(let tsk) = progress {
				dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
					tsk.completion?(nil, nil, NSError(domain: "HttpRequestTests", code: 1, userInfo: nil))
				}
			}
			}.addDisposableTo(bag)
		
		let expectation = expectationWithDescription("Should return NSError")
		
		HttpRequest.sharedInstance.loadData(request, session: session).bindNext { result in
			if case .Error(let error) = result where error?.code == 1 {
				expectation.fulfill()
			}
			}.addDisposableTo(bag)
		
		waitForExpectationsWithTimeout(1, handler: nil)
	}
	
	func testReturnJson() {
		session.task?.taskProgress.bindNext { progress in
			if case .resume(let tsk) = progress {
				let json: JSON =  ["Test": "Value"]
				dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
					tsk.completion?(try? json.rawData(), nil, nil)
				}
			}
		}.addDisposableTo(bag)
		
		let expectation = expectationWithDescription("Should return json data")
		
		HttpRequest.sharedInstance.loadJsonData(request, session: session).bindNext { result in
			if case .SuccessJson(let json) = result where json["Test"] == "Value" {
				expectation.fulfill()
			}
		}.addDisposableTo(bag)
		
		waitForExpectationsWithTimeout(1, handler: nil)
	}
	
	func testNotReturnJson() {
		session.task?.taskProgress.bindNext { progress in
			if case .resume(let tsk) = progress {
				dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
					tsk.completion?(nil, nil, nil)
				}
			}
			}.addDisposableTo(bag)
		
		let expectation = expectationWithDescription("Should not return json data")
		
		HttpRequest.sharedInstance.loadJsonData(request, session: session).bindNext { result in
			guard case .SuccessJson(_) = result else {
				expectation.fulfill()
				return
			}
			}.addDisposableTo(bag)
		
		waitForExpectationsWithTimeout(1, handler: nil)
	}
	

	
//	func testReturnJsonForCloudResource() {
//		session.task?.taskProgress.bindNext { progress in
//			if case .resume(let tsk) = progress {
//				dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
//					tsk.completion?(nil, nil, nil)
//				}
//			}
//			}.addDisposableTo(bag)
//		
//		let expectation = expectationWithDescription("Should not return json data")
//		
//		HttpRequest.sharedInstance.loadDataForCloudResource(YandexDiskCloudJsonResource(), session: session) { result in
//			guard case .SuccessJson(_) = result else {
//				expectation.fulfill()
//				return
//			}
//			}.addDisposableTo(bag)
//		
//		waitForExpectationsWithTimeout(1, handler: nil)
//	}

}
