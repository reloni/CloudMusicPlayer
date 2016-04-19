//
//  NSFileManagerTests.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 19.04.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import XCTest

class NSFileManagerTests: XCTestCase {
	
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
	}
	
	func testCalculateDirectorySize() {
		let dir = NSFileManager.getOrCreateSubDirectory(NSFileManager.documentsDirectory, subDirName: "DirSizeTest")!
		
		let firstData = "first data".dataUsingEncoding(NSUTF8StringEncoding)!
		let secondData = "second data".dataUsingEncoding(NSUTF8StringEncoding)!
		
		let firstFile = dir.URLByAppendingPathComponent("first.dat")
		firstData.writeToURL(firstFile, atomically: true)
		let secondFile = dir.URLByAppendingPathComponent("second.dat")
		secondData.writeToURL(secondFile, atomically: true)
		
		XCTAssertEqual(NSFileManager.defaultManager().getDirectorySize(dir, recursive: false), UInt64(firstData.length) + UInt64(secondData.length))

		dir.deleteFile()
	}
	
	func testCalculateDirectorySizeRecursively() {
		let dir = NSFileManager.getOrCreateSubDirectory(NSFileManager.documentsDirectory, subDirName: "DirSizeTestRecursive")!
		
		let firstData = "first data".dataUsingEncoding(NSUTF8StringEncoding)!
		let secondData = "second data".dataUsingEncoding(NSUTF8StringEncoding)!
		
		let firstFile = dir.URLByAppendingPathComponent("first.dat")
		firstData.writeToURL(firstFile, atomically: true)
		let secondFile = dir.URLByAppendingPathComponent("second.dat")
		secondData.writeToURL(secondFile, atomically: true)
		
		let subDir = NSFileManager.getOrCreateSubDirectory(dir, subDirName: "SubDirSizeTest")!
		let subDirFirstFile = subDir.URLByAppendingPathComponent("sub first.dat")
		firstData.writeToURL(subDirFirstFile, atomically: true)
		let subDirSecondFile = subDir.URLByAppendingPathComponent("sub second.dat")
		secondData.writeToURL(subDirSecondFile, atomically: true)
		
		XCTAssertEqual(NSFileManager.defaultManager().getDirectorySize(dir, recursive: true), 2 * (UInt64(firstData.length) + UInt64(secondData.length)))
		
		dir.deleteFile()
	}
	
	func testReturnContentsOfDirectory() {
		let dir = NSFileManager.getOrCreateSubDirectory(NSFileManager.documentsDirectory, subDirName: "DirSizeTestRecursive")!
		
		let firstData = "first data".dataUsingEncoding(NSUTF8StringEncoding)!
		let secondData = "second data".dataUsingEncoding(NSUTF8StringEncoding)!
		
		let firstFile = dir.URLByAppendingPathComponent("first.dat")
		firstData.writeToURL(firstFile, atomically: true)
		let secondFile = dir.URLByAppendingPathComponent("second.dat")
		secondData.writeToURL(secondFile, atomically: true)
		
		let contents = NSFileManager.defaultManager().contentsOfDirectoryAtURL(dir)
		XCTAssertEqual(firstFile, contents?[0])
		XCTAssertEqual(secondFile, contents?[1])
		
		dir.deleteFile()
	}
}
