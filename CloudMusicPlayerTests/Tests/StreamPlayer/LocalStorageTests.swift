//
//  LocalStorageTests.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 05.04.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import XCTest
@testable import CloudMusicPlayer

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
	
	func testSaveNewDatFileToTempStorage() {
		let storage = LocalNsUserDefaultsStorage()
		let provider = MemoryCacheProvider(uid: NSUUID().UUIDString)
		provider.appendData("some data".dataUsingEncoding(NSUTF8StringEncoding)!)
		let file = storage.saveToTempStorage(provider)
		if let file = file {
			XCTAssertEqual(true, file.fileExists(), "Check file existance")
			XCTAssertEqual("dat", file.pathExtension, "Check default extension of file")
			if let savedData = NSData(contentsOfURL: file) {
				XCTAssertTrue(savedData.isEqualToData(provider.getData()), "Check saved data equal to cached data")
			} else {
				XCTFail("Unable to load saved data")
			}
			XCTAssertTrue(storage.tempSaveStorageDirectory.URLByAppendingPathComponent(file.lastPathComponent!, isDirectory: false).fileExists(),
			              "Check file saved in temp storage directory")
			let _ = try? NSFileManager.defaultManager().removeItemAtURL(file)
		} else {
			XCTFail("Should save file")
		}
	}
	
	func testSaveNewFileToPermanentStorage() {
		let storage = LocalNsUserDefaultsStorage()
		let provider = MemoryCacheProvider(uid: NSUUID().UUIDString, contentMimeType: "audio/mpeg")
		provider.appendData("some data".dataUsingEncoding(NSUTF8StringEncoding)!)
		let file = storage.saveToPermanentStorage(provider)
		if let file = file {
			XCTAssertEqual(true, file.fileExists(), "Check file existance")
			XCTAssertEqual("mp3", file.pathExtension, "Check extension of file")
			if let savedData = NSData(contentsOfURL: file) {
				XCTAssertTrue(savedData.isEqualToData(provider.getData()), "Check saved data equal to cached data")
			} else {
				XCTFail("Unable to load saved data")
			}
			XCTAssertTrue(storage.permanentSaveStorageDirectory.URLByAppendingPathComponent(file.lastPathComponent!, isDirectory: false).fileExists(),
			              "Check file saved in permanent storage directory")
			let _ = try? NSFileManager.defaultManager().removeItemAtURL(file)
		} else {
			XCTFail("Should save file")
		}
	}
	
	func testGetCachedFile() {
		let storage = LocalNsUserDefaultsStorage()
		let provider = MemoryCacheProvider(uid: NSUUID().UUIDString)
		provider.appendData("some data".dataUsingEncoding(NSUTF8StringEncoding)!)
		let file = storage.saveToTempStorage(provider)
		let cachedFile = storage.getFromStorage(provider.uid)
		XCTAssertEqual(file, cachedFile, "Check file was cached")
	}
	
	func testNotGetNotExistedInCacheFile() {
		let storage = LocalNsUserDefaultsStorage()
		let cachedFile = storage.getFromStorage(NSUUID().UUIDString)
		XCTAssertNil(cachedFile, "Should not return anything")
	}
	
	func testLoadWithoutInitialData() {
		let storage = LocalNsUserDefaultsStorage(loadData: true, userDefaults: FakeNSUserDefaults(localCache: [String: AnyObject]()))
		XCTAssertEqual(0, storage.tempSaveStorageDictionary.count)
		XCTAssertEqual(0, storage.permanentSaveStorageDictionary.count)
	}
	
	func testLoadWithInitialData() {
		let tempDict = ["First file": "path", "Second file": "path"]
		let permanentDict = ["Third file": "path"]
		let userDefaults = FakeNSUserDefaults(localCache: [LocalNsUserDefaultsStorage.tempFileStorageId: tempDict,
			LocalNsUserDefaultsStorage.permanentFileStorageId: permanentDict])
		let storage = LocalNsUserDefaultsStorage(loadData: true, userDefaults: userDefaults)
		XCTAssertEqual(2, storage.tempSaveStorageDictionary.count)
		XCTAssertEqual(1, storage.permanentSaveStorageDictionary.count)
	}
	
	func testPreserveDataAcrossSessions() {
		let userDefaults = FakeNSUserDefaults(localCache: [String: AnyObject]())
		let storage = LocalNsUserDefaultsStorage(loadData: true, userDefaults: userDefaults)
		
		let provider = MemoryCacheProvider(uid: NSUUID().UUIDString, contentMimeType: "audio/mpeg")
		provider.appendData("some data".dataUsingEncoding(NSUTF8StringEncoding)!)
		let cachedFile = storage.saveToTempStorage(provider)
		
		if let savedFile = (userDefaults.localCache[LocalNsUserDefaultsStorage.tempFileStorageId] as? [String: AnyObject])?.first?.1 as? String {
			XCTAssertEqual(cachedFile?.lastPathComponent, savedFile, "Check correct data saved in user defaults")
		} else {
			XCTFail("Failed to save data to user defaults")
		}
		
		let newStorage = LocalNsUserDefaultsStorage(loadData: true, userDefaults: userDefaults)
		XCTAssertEqual(newStorage.tempSaveStorageDictionary.first?.1, cachedFile?.lastPathComponent, "Check cached file loaded in new storage")
		XCTAssertNotNil(newStorage.getFromStorage(provider.uid), "Check new storage return file, cached in previous version")
		
		if let cachedFile = cachedFile {
			let _ = try? NSFileManager.defaultManager().removeItemAtURL(cachedFile)
		}
	}
}
