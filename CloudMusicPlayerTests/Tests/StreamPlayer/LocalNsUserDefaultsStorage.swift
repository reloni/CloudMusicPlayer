//
//  LocalStorageTests.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 05.04.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import XCTest
import RxBlocking
import RxSwift
@testable import CloudMusicPlayer

class LocalNsUserDefaultsStorageTests: XCTestCase {
	var tempStorageDir: NSURL!
	var permanentStorageDir: NSURL!
	var temporaryDir: NSURL!
	
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
		
		tempStorageDir = NSFileManager.getOrCreateSubDirectory(NSFileManager.documentsDirectory, subDirName: "TempStorageDir")!
		permanentStorageDir = NSFileManager.getOrCreateSubDirectory(NSFileManager.documentsDirectory, subDirName: "PermanentStorageDir")!
		temporaryDir = NSFileManager.getOrCreateSubDirectory(NSFileManager.documentsDirectory, subDirName: "TemporaryDir")!
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
		
		tempStorageDir.deleteFile()
		permanentStorageDir.deleteFile()
		temporaryDir.deleteFile()
	}
	
	func testPaths() {
		let storage = LocalNsUserDefaultsStorage()
		XCTAssertTrue(NSFileManager.fileExistsAtPath(storage.temporaryDirectory.path!, isDirectory: true))
		XCTAssertTrue(NSFileManager.fileExistsAtPath(storage.tempStorageDirectory.path!, isDirectory: true))
		XCTAssertTrue(NSFileManager.fileExistsAtPath(storage.permanentStorageDirectory.path!, isDirectory: true))
	}
	
	func testSaveNewDatFileToTempStorage() {
		let storage = LocalNsUserDefaultsStorage(persistInformationAboutSavedFiles: false, userDefaults: FakeNSUserDefaults())
		let provider = MemoryCacheProvider(uid: NSUUID().UUIDString)
		provider.appendData("some data".dataUsingEncoding(NSUTF8StringEncoding)!)
		
		let bag = DisposeBag()
		let expectation = expectationWithDescription("Should send event about new cached item")
		storage.itemStateChanged.bindNext { result in
			if result.uid == provider.uid && result.from == CacheState.notExisted && result.to == .inTempStorage {
				expectation.fulfill()
			}
		}.addDisposableTo(bag)
		
		let file = storage.saveToTempStorage(provider)
		
		waitForExpectationsWithTimeout(1, handler: nil)
		
		if let file = file {
			XCTAssertEqual(true, file.fileExists(), "Check file existance")
			XCTAssertEqual("dat", file.pathExtension, "Check default extension of file")
			if let savedData = NSData(contentsOfURL: file) {
				XCTAssertTrue(savedData.isEqualToData(provider.getCurrentData()), "Check saved data equal to cached data")
			} else {
				XCTFail("Unable to load saved data")
			}
			XCTAssertTrue(storage.tempStorageDirectory.URLByAppendingPathComponent(file.lastPathComponent!, isDirectory: false).fileExists(),
			              "Check file saved in temp storage directory")
			let _ = try? NSFileManager.defaultManager().removeItemAtURL(file)
		} else {
			XCTFail("Should save file")
		}
	}
	
	func testSaveNewFileToPermanentStorage() {
		let storage = LocalNsUserDefaultsStorage(persistInformationAboutSavedFiles: false, userDefaults: FakeNSUserDefaults())
		let provider = MemoryCacheProvider(uid: NSUUID().UUIDString, contentMimeType: "audio/mpeg")
		provider.appendData("some data".dataUsingEncoding(NSUTF8StringEncoding)!)
		
		let bag = DisposeBag()
		let expectation = expectationWithDescription("Should send event about new cached item")
		storage.itemStateChanged.bindNext { result in
			if result.uid == provider.uid && result.from == CacheState.notExisted && result.to == .inPermanentStorage {
				expectation.fulfill()
			}
		}.addDisposableTo(bag)
		
		let file = storage.saveToPermanentStorage(provider)
		
		waitForExpectationsWithTimeout(1, handler: nil)
		
		if let file = file {
			XCTAssertEqual(true, file.fileExists(), "Check file existance")
			XCTAssertEqual("mp3", file.pathExtension, "Check extension of file")
			if let savedData = NSData(contentsOfURL: file) {
				XCTAssertTrue(savedData.isEqualToData(provider.getCurrentData()), "Check saved data equal to cached data")
			} else {
				XCTFail("Unable to load saved data")
			}
			XCTAssertTrue(storage.permanentStorageDirectory.URLByAppendingPathComponent(file.lastPathComponent!, isDirectory: false).fileExists(),
			              "Check file saved in permanent storage directory")
			let _ = try? NSFileManager.defaultManager().removeItemAtURL(file)
		} else {
			XCTFail("Should save file")
		}
	}
	
	func testGetCachedFileFromTemp() {
		let storage = LocalNsUserDefaultsStorage()
		let provider = MemoryCacheProvider(uid: NSUUID().UUIDString)
		provider.appendData("some data".dataUsingEncoding(NSUTF8StringEncoding)!)
		let file = storage.saveToTempStorage(provider)
		let cachedFile = storage.getFromStorage(provider.uid)
		XCTAssertEqual(file, cachedFile, "Check file was cached")
		file?.deleteFile()
	}
	
	func testNotReturnCacheTempFileThatWasDeleted() {
		let storage = LocalNsUserDefaultsStorage()
		let provider = MemoryCacheProvider(uid: NSUUID().UUIDString)
		provider.appendData("some data".dataUsingEncoding(NSUTF8StringEncoding)!)
		let file = storage.saveToTempStorage(provider)
		// delete file from disk
		file?.deleteFile()
		let cachedFile = storage.getFromStorage(provider.uid)
		XCTAssertNil(cachedFile, "Check not return file bacause it was deleted")
	}
	
	func testGetCachedFileFromPermanent() {
		let storage = LocalNsUserDefaultsStorage()
		let provider = MemoryCacheProvider(uid: NSUUID().UUIDString)
		provider.appendData("some data".dataUsingEncoding(NSUTF8StringEncoding)!)
		let file = storage.saveToPermanentStorage(provider)
		let cachedFile = storage.getFromStorage(provider.uid)
		XCTAssertEqual(file, cachedFile, "Check file was cached")
		file?.deleteFile()
	}
	
	func testNotReturnCachePermanentFileThatWasDeleted() {
		let storage = LocalNsUserDefaultsStorage()
		let provider = MemoryCacheProvider(uid: NSUUID().UUIDString)
		provider.appendData("some data".dataUsingEncoding(NSUTF8StringEncoding)!)
		let file = storage.saveToPermanentStorage(provider)
		// delete file from disk
		file?.deleteFile()
		let cachedFile = storage.getFromStorage(provider.uid)
		XCTAssertNil(cachedFile, "Check not return file bacause it was deleted")
	}
	
	func testNotGetNotExistedInCacheFile() {
		let storage = LocalNsUserDefaultsStorage()
		let cachedFile = storage.getFromStorage(NSUUID().UUIDString)
		XCTAssertNil(cachedFile, "Should not return anything")
	}
	
	func testLoadWithoutInitialData() {
		let storage = LocalNsUserDefaultsStorage(persistInformationAboutSavedFiles: true, userDefaults: FakeNSUserDefaults(localCache: [String: AnyObject]()))
		XCTAssertEqual(0, storage.tempStorageDictionary.count)
		XCTAssertEqual(0, storage.permanentStorageDictionary.count)
	}
	
	func testLoadWithInitialData() {
		let tempDict = ["First file": "path", "Second file": "path"]
		let permanentDict = ["Third file": "path"]
		let userDefaults = FakeNSUserDefaults(localCache: [LocalNsUserDefaultsStorage.tempFileStorageId: tempDict,
			LocalNsUserDefaultsStorage.permanentFileStorageId: permanentDict])
		let storage = LocalNsUserDefaultsStorage(persistInformationAboutSavedFiles: true, userDefaults: userDefaults)
		XCTAssertEqual(2, storage.tempStorageDictionary.count)
		XCTAssertEqual(1, storage.permanentStorageDictionary.count)
	}
	
	func testPreserveDataAcrossSessions() {
		let userDefaults = FakeNSUserDefaults(localCache: [String: AnyObject]())
		let storage = LocalNsUserDefaultsStorage(persistInformationAboutSavedFiles: true, userDefaults: userDefaults)
		
		let provider = MemoryCacheProvider(uid: NSUUID().UUIDString, contentMimeType: "audio/mpeg")
		provider.appendData("some data".dataUsingEncoding(NSUTF8StringEncoding)!)
		let cachedInTempFile = storage.saveToTempStorage(provider)
		let cachedInPermanentFile = storage.saveToPermanentStorage(provider)
		
		// check info about temp storage
		if let savedFile = (userDefaults.localCache[LocalNsUserDefaultsStorage.tempFileStorageId] as? [String: AnyObject])?.first?.1 as? String {
			XCTAssertEqual(cachedInTempFile?.lastPathComponent, savedFile, "Check correct data saved in user defaults")
		} else {
			XCTFail("Failed to save data to user defaults")
		}
		
		// check info about permanent storage
		if let savedFile = (userDefaults.localCache[LocalNsUserDefaultsStorage.permanentFileStorageId] as? [String: AnyObject])?.first?.1 as? String {
			XCTAssertEqual(cachedInPermanentFile?.lastPathComponent, savedFile, "Check correct data saved in user defaults")
		} else {
			XCTFail("Failed to save data to user defaults")
		}
		
		let newStorage = LocalNsUserDefaultsStorage(persistInformationAboutSavedFiles: true, userDefaults: userDefaults)
		
		XCTAssertEqual(newStorage.tempStorageDictionary.first?.1, cachedInTempFile?.lastPathComponent, "Check cached file loaded in new storage")
		XCTAssertNotNil(newStorage.getFromStorage(provider.uid), "Check new storage return temp file, cached in previous version")
		
		XCTAssertEqual(newStorage.permanentStorageDictionary.first?.1, cachedInPermanentFile?.lastPathComponent, "Check cached file loaded in new storage")
		XCTAssertNotNil(newStorage.getFromStorage(provider.uid), "Check new storage return permanent file, cached in previous version")
		
		cachedInPermanentFile?.deleteFile()
		cachedInTempFile?.deleteFile()
	}
	
	func testCalculateStorageSize() {	
		let firstData = "first data".dataUsingEncoding(NSUTF8StringEncoding)!
		let secondData = "second data".dataUsingEncoding(NSUTF8StringEncoding)!
		
		firstData.writeToURL(tempStorageDir.URLByAppendingPathComponent("first.dat"), atomically: true)
		secondData.writeToURL(tempStorageDir.URLByAppendingPathComponent("second.dat"), atomically: true)
		
		firstData.writeToURL(permanentStorageDir.URLByAppendingPathComponent("first.dat"), atomically: true)
		
		secondData.writeToURL(temporaryDir.URLByAppendingPathComponent("second.dat"), atomically: true)
		
		let storage = LocalNsUserDefaultsStorage(tempStorageDirectory: tempStorageDir, permanentStorageDirectory: permanentStorageDir,
		                                         temporaryDirectory: temporaryDir)
		
		let size = try! storage.calculateSize().toBlocking().toArray().first
		XCTAssertEqual(size?.tempStorage, UInt64(firstData.length + secondData.length))
		XCTAssertEqual(size?.permanentStorage, UInt64(firstData.length))
		XCTAssertEqual(size?.temporary, UInt64(secondData.length))
	}
	
	func testClearStorage() {
		//let firstData = "first data".dataUsingEncoding(NSUTF8StringEncoding)!
		let data = "second data".dataUsingEncoding(NSUTF8StringEncoding)!
		
		//firstData.writeToURL(tempStorageDir.URLByAppendingPathComponent("first.dat"), atomically: true)
		//secondData.writeToURL(tempStorageDir.URLByAppendingPathComponent("second.dat"), atomically: true)
		
		//firstData.writeToURL(permanentStorageDir.URLByAppendingPathComponent("first.dat"), atomically: true)
		
		data.writeToURL(temporaryDir.URLByAppendingPathComponent("test.dat"), atomically: true)
		
		let storage = LocalNsUserDefaultsStorage(tempStorageDirectory: tempStorageDir, permanentStorageDirectory: permanentStorageDir,
																						 temporaryDirectory: temporaryDir, persistInformationAboutSavedFiles: true, userDefaults: FakeNSUserDefaults())
		
		storage.saveToTempStorage(MemoryCacheProvider(uid: "firstfile"))
		storage.saveToTempStorage(MemoryCacheProvider(uid: "secondfile"))
		storage.saveToPermanentStorage(MemoryCacheProvider(uid: "thirdfile"))
		
		XCTAssertEqual(2, storage.tempStorageDictionary.count)
		XCTAssertEqual(1, storage.permanentStorageDictionary.count)
		
		XCTAssertEqual(2, NSFileManager.defaultManager().contentsOfDirectoryAtURL(tempStorageDir)?.count)
		XCTAssertEqual(1, NSFileManager.defaultManager().contentsOfDirectoryAtURL(permanentStorageDir)?.count)
		XCTAssertEqual(1, NSFileManager.defaultManager().contentsOfDirectoryAtURL(temporaryDir)?.count)
		
		let clearTempStorageExpectation = expectationWithDescription("Should send event when temp storage cleared")
		let clearPermanentStorageExpectation = expectationWithDescription("Should send event when permanent storage cleared")
		
		let bag = DisposeBag()
		storage.storageCleared.bindNext { type in
			if type == StorageType.permanent {
				clearPermanentStorageExpectation.fulfill()
			} else if type == StorageType.temp {
				clearTempStorageExpectation.fulfill()
			}
		}.addDisposableTo(bag)
		
		storage.clearStorage()
		
		waitForExpectationsWithTimeout(1, handler: nil)
		
		XCTAssertEqual(0, storage.tempStorageDictionary.count)
		XCTAssertEqual(0, storage.permanentStorageDictionary.count)
		
		XCTAssertEqual(0, NSFileManager.defaultManager().contentsOfDirectoryAtURL(tempStorageDir)?.count)
		XCTAssertEqual(0, NSFileManager.defaultManager().contentsOfDirectoryAtURL(permanentStorageDir)?.count)
		XCTAssertEqual(0, NSFileManager.defaultManager().contentsOfDirectoryAtURL(temporaryDir)?.count)
	}
	
	func testDeleteFileFromStorage() {
		let firstData = "first data".dataUsingEncoding(NSUTF8StringEncoding)!
		let cacheProvider = MemoryCacheProvider(uid: "test", contentMimeType: "audio/mpeg")
		cacheProvider.appendData(firstData)
	
		let storage = LocalNsUserDefaultsStorage(tempStorageDirectory: tempStorageDir, permanentStorageDirectory: permanentStorageDir,
		                                         temporaryDirectory: temporaryDir, persistInformationAboutSavedFiles: true, userDefaults: FakeNSUserDefaults())
		storage.saveToTempStorage(cacheProvider)
		
		let currentCacheState = storage.getItemState(cacheProvider.uid)
		XCTAssertEqual(CacheState.inTempStorage, currentCacheState)
		
		let bag = DisposeBag()
		let expectation = expectationWithDescription("Should change item cache state")
		
		storage.itemStateChanged.bindNext { result in
			if result.uid == cacheProvider.uid && result.from == currentCacheState && result.to == CacheState.notExisted {
				expectation.fulfill()
			}
		}.addDisposableTo(bag)
		
		storage.deleteItem(cacheProvider.uid)
		
		waitForExpectationsWithTimeout(1, handler: nil)
		
		XCTAssertEqual(0, storage.tempStorageDictionary.count)
		XCTAssertEqual(0, storage.permanentStorageDictionary.count)
	}
	
	func testMoveFileToPermanentStorage() {
		let firstData = "first data".dataUsingEncoding(NSUTF8StringEncoding)!
		let cacheProvider = MemoryCacheProvider(uid: "test", contentMimeType: "audio/mpeg")
		cacheProvider.appendData(firstData)
		
		let storage = LocalNsUserDefaultsStorage(tempStorageDirectory: tempStorageDir, permanentStorageDirectory: permanentStorageDir,
		                                         temporaryDirectory: temporaryDir, persistInformationAboutSavedFiles: true, userDefaults: FakeNSUserDefaults())
		
		XCTAssertEqual(0, NSFileManager.defaultManager().contentsOfDirectoryAtURL(tempStorageDir)?.count)
		XCTAssertEqual(0, NSFileManager.defaultManager().contentsOfDirectoryAtURL(permanentStorageDir)?.count)
		
		storage.saveToTempStorage(cacheProvider)
		
		XCTAssertEqual(1, NSFileManager.defaultManager().contentsOfDirectoryAtURL(tempStorageDir)?.count)
		XCTAssertEqual(0, NSFileManager.defaultManager().contentsOfDirectoryAtURL(permanentStorageDir)?.count)
		
		XCTAssertEqual(1, storage.tempStorageDictionary.count)
		XCTAssertEqual(0, storage.permanentStorageDictionary.count)
		
		let currentCacheState = storage.getItemState(cacheProvider.uid)
		XCTAssertEqual(CacheState.inTempStorage, currentCacheState)
		
		let bag = DisposeBag()
		let expectation = expectationWithDescription("Should change item cache state")
		
		storage.itemStateChanged.bindNext { result in
			if result.uid == cacheProvider.uid && result.from == currentCacheState && result.to == CacheState.inPermanentStorage {
				expectation.fulfill()
			}
		}.addDisposableTo(bag)
		
		storage.moveToPermanentStorage(cacheProvider.uid)
		
		waitForExpectationsWithTimeout(1, handler: nil)
		
		XCTAssertEqual(0, storage.tempStorageDictionary.count)
		XCTAssertEqual(1, storage.permanentStorageDictionary.count)
		
		XCTAssertEqual(CacheState.inPermanentStorage, storage.getItemState(cacheProvider.uid))
		
		XCTAssertEqual(0, NSFileManager.defaultManager().contentsOfDirectoryAtURL(tempStorageDir)?.count)
		XCTAssertEqual(1, NSFileManager.defaultManager().contentsOfDirectoryAtURL(permanentStorageDir)?.count)
	}
	
	func testCorrectCheckCacheStateOfNotExistedItem() {
		let storage = LocalNsUserDefaultsStorage(persistInformationAboutSavedFiles: false, userDefaults: FakeNSUserDefaults())
		XCTAssertEqual(CacheState.notExisted, storage.getItemState("notexisted"))
	}
}
