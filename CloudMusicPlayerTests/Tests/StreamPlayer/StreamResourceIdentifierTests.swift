//
//  StreamResourceIdentifierTests.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 07.04.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import XCTest
import CloudMusicPlayer

class StreamResourceIdentifierTests: XCTestCase {
	
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
	}
	
	func testParseHttplUrl() {
		let file = "http://Documents/File.txt"
		if let content = file.streamResourceType {
			XCTAssertEqual(content, StreamResourceType.HttpResource)
		} else { XCTFail("Should return resource type") }
	}
	
	func testParseHttpsUrl() {
		let file = "https://Documents/File.txt"
		if let content = file.streamResourceType {
			XCTAssertEqual(content, StreamResourceType.HttpsResource)
		} else { XCTFail("Should return resource type") }
	}
	
	func testParseLocalUrl() {
		let file = "file://Documents/File.txt"
		if let content = file.streamResourceType {
			XCTAssertEqual(content, StreamResourceType.LocalResource)
		} else { XCTFail("Should return resource type") }
	}
	
	func testNotParseIncorrectUrl() {
		let file = "fake://Documents/File.txt"
		XCTAssertNil(file.streamResourceType)
	}
}
