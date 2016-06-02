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
		let content = try! file.streamResourceType.toBlocking().first()
		XCTAssertEqual(content, StreamResourceType.HttpResource)
		//} else { XCTFail("Should return resource type") }
	}
	
	func testParseHttpsUrl() {
		let file = "https://Documents/File.txt"
		let content = try! file.streamResourceType.toBlocking().first()
		XCTAssertEqual(content, StreamResourceType.HttpsResource)
		//} else { XCTFail("Should return resource type") }
	}
	
	func testParseLocalUrl() {
		let file = NSFileManager.temporaryDirectory.URLByAppendingPathComponent("\(NSUUID().UUIDString).dat")
		NSFileManager.defaultManager().createFileAtPath(file.path!, contents: nil, attributes: nil)
		if let content = try! file.path!.streamResourceType.toBlocking().first() {
			XCTAssertEqual(content, StreamResourceType.LocalResource)
		} else { XCTFail("Should return resource type") }
		let _ = try? NSFileManager.defaultManager().removeItemAtURL(file)
	}
	
	func testNotParseIncorrectUrl() {
		let file = "/Documents/File.txt"
		XCTAssertNil(try! file.streamResourceType.toBlocking().first())
	}
}
