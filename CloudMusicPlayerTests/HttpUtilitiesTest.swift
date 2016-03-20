//
//  HttpUtilitiesTest.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 15.03.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import XCTest
@testable import CloudMusicPlayer

class HttpUtilitiesTest: XCTestCase {
	var request: FakeRequest!
	
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
		request = FakeRequest(url: NSURL(baseUrl: "https://test.com", parameters: ["param": "value"]))
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
		
		request = nil
	}
	
	func testCreateNSMutableURLRequest() {
		let req = HttpUtilities().createUrlRequest("https://test.com", parameters: ["param1": "value1"]) as? NSMutableURLRequest
		XCTAssertNotNil(req, "Should return instance of NSMutableURLRequest")
		XCTAssertEqual("https://test.com?param1=value1", req?.URL?.URLString, "Should create request with correct url")
	}
	
	func testCreateNSMutableURLRequestWithHeaders() {
		let req = HttpUtilities().createUrlRequest("https://test.com", parameters: ["param1": "value1"], headers: ["header1": "value1"]) as? NSMutableURLRequest
		XCTAssertNotNil(req, "Should return instance of NSMutableURLRequest")
		XCTAssertEqual("https://test.com?param1=value1", req?.URL?.URLString, "Should create request with correct url")
		XCTAssertEqual(1, req?.allHTTPHeaderFields?.count, "Should create request with one header")
		XCTAssertEqual("value1", req?.allHTTPHeaderFields!["header1"], "Should create request with correct header")
	}
	
	func testNotCreateNSMutableUrlRequestWithWrongUrl() {
		XCTAssertNil(HttpUtilities().createUrlRequest("wrong url", parameters: nil))
	}
	
	func testNotCreateNSMutableUrlRequestWithWrongUrlAndHeaders() {
		XCTAssertNil(HttpUtilities().createUrlRequest("wrong url", parameters: nil, headers: nil))
	}
	
	func testCreateUrlSession() {
		let session = HttpUtilities().createUrlSession(NSURLSession.defaultConfig) as? NSURLSession
		XCTAssertNotNil(session)
		XCTAssertEqual(session?.configuration, NSURLSession.defaultConfig)
		XCTAssertNil(session?.delegate)
	}
	
	func testCreateUrlSessionWithSpecificConfig() {
		let config = NSURLSessionConfiguration.defaultSessionConfiguration()
		config.HTTPCookieAcceptPolicy = .Always
		let session = HttpUtilities().createUrlSession(config) as? NSURLSession
		XCTAssertEqual(session?.configuration.HTTPCookieAcceptPolicy, NSHTTPCookieAcceptPolicy.Always)
		XCTAssertNil(session?.delegate)
	}
	
	func testCreateUrlSessionWithDelegate() {
		let delegate = UrlSessionStreamObserver()
		let session = HttpUtilities().createUrlSession(NSURLSession.defaultConfig, delegate: delegate, queue: nil) as? NSURLSession
		XCTAssertTrue(delegate === session?.delegate)
	}
	
	func testCreateStreamObserver() {
		XCTAssertNotNil(HttpUtilities().createUrlSessionStreamObserver())
	}
	
	func testCreateStreamDataTask() {
		let utilities = HttpUtilities()
		let config = NSURLSessionConfiguration.defaultSessionConfiguration()
		config.HTTPCookieAcceptPolicy = .Always
		let task = utilities.createStreamDataTask(request, sessionConfiguration: config) as? StreamDataTask
		XCTAssertEqual(task?.request.URL?.URLString, request.URL?.URLString)
		XCTAssertTrue(task?.httpUtilities as? HttpUtilities === utilities)
		XCTAssertEqual(task?.sessionConfiguration, config)
	}
}
