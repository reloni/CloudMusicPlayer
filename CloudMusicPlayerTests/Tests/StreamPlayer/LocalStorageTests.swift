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
		//let caches = NSFileManager.defaultManager().URLsForDirectory(.CachesDirectory, inDomains: .UserDomainMask)[0]
//		let caches = NSURL(fileURLWithPath: NSTemporaryDirectory())
//		print("Caches: \(caches)")
//		XCTAssertTrue(NSFileManager.fileExistsAtPath(caches.path!, isDirectory: true))
//		
//		let shit = NSFileManager.getOrCreateSubDirectory(caches, subDirName: "shit")
//		print("Shit: \(shit)")
//		XCTAssertTrue(NSFileManager.fileExistsAtPath(shit!.path!, isDirectory: true))
//		
//		let file = shit?.URLByAppendingPathComponent("\(NSUUID().UUIDString).dat")
//		XCTAssertFalse(NSFileManager.fileExistsAtPath(file!.path!, isDirectory: false))
//		
//		let someData = "Shit data".dataUsingEncoding(NSUTF8StringEncoding)
//		XCTAssertTrue(someData!.writeToURL(file!, atomically: true))
		
		//let str = LocalStorage()
		
		//print("shit1:" + str.tempCacheDirectory.absoluteString)
		//print("shit2:" + str.tempSaveDirectory.absoluteString)
		
		//XCTAssertTrue(NSFileManager.fileExistsAtPath(str.tempCacheDirectory.absoluteString, isDirectory: true))
		//XCTAssertTrue(NSFileManager.fileExistsAtPath(str.tempSaveDirectory.absoluteString, isDirectory: true))
		//XCTAssertTrue(NSFileManager.fileExistsAtPath(str.permanentSaveDirectory.absoluteString, isDirectory: true))
	}
	
	func testPaths() {
		let storage = LocalStorage()
		XCTAssertTrue(NSFileManager.fileExistsAtPath(storage.tempCacheDirectory.path!, isDirectory: true))
		XCTAssertTrue(NSFileManager.fileExistsAtPath(storage.tempSaveStorageDirectory.path!, isDirectory: true))
		XCTAssertTrue(NSFileManager.fileExistsAtPath(storage.permanentSaveStorageDirectory.path!, isDirectory: true))
	}
}
