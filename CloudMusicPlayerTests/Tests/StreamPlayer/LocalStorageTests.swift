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
	
	func testReturnDirectories() {
		let str = LocalStorage() as LocalStorageProtocol
		
		print("shit1:" + str.tempCacheDirectory.absoluteString)
		print("shit2:" + str.tempSaveDirectory.absoluteString)
		
		XCTAssertTrue(NSFileManager.fileExistsAtPath(str.tempCacheDirectory.absoluteString, isDirectory: true))
		XCTAssertTrue(NSFileManager.fileExistsAtPath(str.tempSaveDirectory.absoluteString, isDirectory: true))
		XCTAssertTrue(NSFileManager.fileExistsAtPath(str.permanentSaveDirectory.absoluteString, isDirectory: true))
	}
}
