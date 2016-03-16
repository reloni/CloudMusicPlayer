//
//  HttpRequestTests.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 14.03.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import XCTest
@testable import CloudMusicPlayer
import RxSwift
import SwiftyJSON

class HttpRequestTests: XCTestCase {
	var bag: DisposeBag!
	var request: FakeRequest!
	var session: FakeSession!
	var utilities: FakeHttpUtilities!
	
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
		
		bag = DisposeBag()
		request = FakeRequest()
		session = FakeSession(fakeTask: FakeDataTask(completion: nil))
		utilities = FakeHttpUtilities()
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
		bag = nil
		request = nil
		session = nil
		utilities = nil
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
		
		HttpRequest.instance.loadData(request, session: session).bindNext { result in
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
		
		HttpRequest.instance.loadData(request, session: session).bindNext { result in
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
		
		HttpRequest.instance.loadData(request, session: session).bindNext { result in
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
		
		HttpRequest.instance.loadJsonData(request, session: session).bindNext { result in
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
		
		HttpRequest.instance.loadJsonData(request, session: session).bindNext { result in
			guard case .SuccessJson(_) = result else {
				expectation.fulfill()
				return
			}
		}.addDisposableTo(bag)
		
		waitForExpectationsWithTimeout(1, handler: nil)
	}
	
	func testTerminateRequest() {
		let expectation = expectationWithDescription("Should suspend task")
		
		session.task?.taskProgress.bindNext { progress in
			if case .resume(let tsk) = progress {
				dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
					for _ in 0...10 {
						sleep(1)
					}
					tsk.completion?(nil, nil, nil)
				}
			} else if case .suspend(_) = progress {
				expectation.fulfill()
			}
		}.addDisposableTo(bag)
		
		let loadRequest = HttpRequest.instance.loadData(request, session: session).bindNext { _ in
		}
		loadRequest.dispose()
		
		waitForExpectationsWithTimeout(1, handler: nil)
	}
	
	func testTerminateJsonRequest() {
		let expectation = expectationWithDescription("Should suspend task")
		
		session.task?.taskProgress.bindNext { progress in
			if case .resume(let tsk) = progress {
				dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
					for _ in 0...10 {
						sleep(1)
					}
					tsk.completion?(nil, nil, nil)
				}
			} else if case .suspend(_) = progress {
				expectation.fulfill()
			}
			}.addDisposableTo(bag)
		
		let loadRequest = HttpRequest.instance.loadJsonData(request, session: session).bindNext { _ in
		}
		loadRequest.dispose()
		
		waitForExpectationsWithTimeout(1, handler: nil)
	}
	
	func testCreateRequestForCloudResource() {
		let request = HttpRequest.instance as! HttpRequest
		let resource = FakeCloudResource(oaRes: OAuthResourceBase(id: "fake", authUrl: "oauth", clientId: nil, tokenId: nil))
		resource.resourcesUrl = "https://test.com/restapi/1"
		resource.requestParameters = ["Param1": "Value with space", "Param2": "Value with / special chars"]
		resource.requestHeaders = ["Header1": "Value1", "Header2": "Value2"]
		// invoke with fakehttputilities
		let createdRequest = request.createRequestForCloudResource(resource, httpUtilities: utilities) as? FakeRequest
		XCTAssertNotNil(createdRequest, "Should create request")
		XCTAssertEqual(2, createdRequest?.headers.count, "Should add 2 headers to request")
		XCTAssertEqual("Value1", createdRequest?.headers["Header1"], "Check value of header1")
		XCTAssertEqual("Value2", createdRequest?.headers["Header2"], "Check value of header2")
	}
	
	func testNotCreateRequestForCloudResourceWithIncorrectUrl() {
		let request = HttpRequest.instance as! HttpRequest
		let resource = FakeCloudResource(oaRes: OAuthResourceBase(id: "fake", authUrl: "oauth", clientId: nil, tokenId: nil))
		resource.resourcesUrl = "incorrect base url"
		// invoke with real httputilities
		let createdRequest = request.createRequestForCloudResource(resource)
		XCTAssertNil(createdRequest)
	}
	
	func testReturnJsonForCloudResource() {
		session.task?.taskProgress.bindNext { progress in
			if case .resume(let tsk) = progress {
				let json: JSON =  ["Test": "Value"]
				dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
					tsk.completion?(try? json.rawData(), nil, nil)
				}
			}
			}.addDisposableTo(bag)
		
		let expectation = expectationWithDescription("Should return correct json data")
		let fakeRes = FakeCloudResource(oaRes: OAuthResourceBase(id: "fake", authUrl: "fake", clientId: nil, tokenId: nil))
		fakeRes.resourcesUrl = "https://test.com"
		
		HttpRequest.instance.loadDataForCloudResource(fakeRes, session: session, httpUtilities: utilities)?.bindNext { result in
			if case .SuccessJson(let json) = result where json["Test"] == "Value" {
				expectation.fulfill()
			}
		}.addDisposableTo(bag)
		
		waitForExpectationsWithTimeout(1, handler: nil)
	}
	
	func testNotReturnRequestForCloudResourceWithIncorrectUrl() {
		session.task?.taskProgress.bindNext { progress in
			if case .resume(let tsk) = progress {
				let json: JSON =  ["Test": "Value"]
				dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
					tsk.completion?(try? json.rawData(), nil, nil)
				}
			}
			}.addDisposableTo(bag)
		
		let fakeRes = FakeCloudResource(oaRes: OAuthResourceBase(id: "fake", authUrl: "fake", clientId: nil, tokenId: nil))
		fakeRes.resourcesUrl = "incorrect url"
		
		// use real httputilities in this case
		XCTAssertNil(HttpRequest.instance.loadDataForCloudResource(fakeRes, session: session, httpUtilities: HttpUtilities.instance), "Should not return request due to incorrect url")
	}
}
