//
//  LocalStorageTests.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 05.04.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import XCTest
import CloudMusicPlayer

class LocalStorageTests: XCTestCase {
	
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
	}
	
	func testPaths() {
		let storage = LocalNsUserDefaultsStorage()
		XCTAssertTrue(NSFileManager.fileExistsAtPath(storage.tempCacheDirectory.path!, isDirectory: true))
		XCTAssertTrue(NSFileManager.fileExistsAtPath(storage.tempSaveStorageDirectory.path!, isDirectory: true))
		XCTAssertTrue(NSFileManager.fileExistsAtPath(storage.permanentSaveStorageDirectory.path!, isDirectory: true))
	}
}
