//
//  NSURLTests.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 14.03.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import XCTest

class NSURLTests: XCTestCase {
	
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
	}
	
	func testCreateNSURLWithParameters() {
		let url = NSURL(baseUrl: "http://test.com", parameters: ["param1": "value1", "param2": "value2"])
		XCTAssertEqual(url?.URLString, "http://test.com?param1=value1&param2=value2")
	}
	
	func testCreateNSURLWithoutParameters() {
		let url = NSURL(baseUrl: "http://test.com", parameters: nil)
		XCTAssertEqual(url?.URLString, "http://test.com")
	}

	func testNotCreateNSURL() {
		let url = NSURL(baseUrl: "some string", parameters: ["param1": "value1", "param2": "value2"])
		XCTAssertNil(url)
	}
}
