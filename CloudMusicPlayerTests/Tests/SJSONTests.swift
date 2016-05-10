//
//  SJSONTests.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 30.04.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import XCTest
import CloudMusicPlayer

class SJSONTests: XCTestCase {
	
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
	}
	
	func testLoadJsonFromNsData() {
		guard let path = NSBundle(forClass: YandexCloudResourceTests.self).pathForResource("YandexRoot", ofType: "json"),
			dataStr = try? String(contentsOfFile: path), let data = dataStr.dataUsingEncoding(NSUTF8StringEncoding) else { XCTFail("Error reading JSON"); return }
		
		let json = data.asSJSON()
		
		XCTAssertEqual(json?.forKey("name")?.asString, "disk")
		XCTAssertEqual(json?.forKey("created")?.asString, "2012-04-04T20:00:00+00:00")
		XCTAssertEqual(json?.forKey("_embedded")?.forKey("path")?.asString, "disk:/")
		XCTAssertEqual(json?.forKey("_embedded")?.forKey("total")?.asInt, 9)
		XCTAssertEqual(json?.forKey("_embedded")?.forKey("items")?.forIndex(0)?.forKey("path")?.asString, "disk:/Documents")
		XCTAssertEqual(json?.forKey("_embedded")?.forKey("items")?.forIndex(1)?.forKey("path")?.asString, "disk:/Lightroom Backups")
	}
	
	func testConvertBackAndForth() {
		guard let path = NSBundle(forClass: YandexCloudResourceTests.self).pathForResource("YandexRoot", ofType: "json"),
			dataStr = try? String(contentsOfFile: path), let data = dataStr.dataUsingEncoding(NSUTF8StringEncoding) else { XCTFail("Error reading JSON"); return }
		
		// convert data to json twice
		let json = data.asSJSON()?.rawData()?.asSJSON()
		
		// test still has correct data
		XCTAssertEqual(json?.forKey("name")?.asString, "disk")
		XCTAssertEqual(json?.forKey("created")?.asString, "2012-04-04T20:00:00+00:00")
		XCTAssertEqual(json?.forKey("_embedded")?.forKey("path")?.asString, "disk:/")
		XCTAssertEqual(json?.forKey("_embedded")?.forKey("total")?.asInt, 9)
		XCTAssertEqual(json?.forKey("_embedded")?.forKey("items")?.forIndex(0)?.forKey("path")?.asString, "disk:/Documents")
		XCTAssertEqual(json?.forKey("_embedded")?.forKey("items")?.forIndex(1)?.forKey("path")?.asString, "disk:/Lightroom Backups")
	}
}
