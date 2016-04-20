//
//  UserDefaultsCacheProviderTests.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 20.04.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import XCTest
@testable import CloudMusicPlayer

class UserDefaultsCacheProviderTests: XCTestCase {
	
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
	}
	
	func testLoadDataFromUserDefaults() {
		let fakeData = "some data".dataUsingEncoding(NSUTF8StringEncoding)!
		let fakeUserDefaults = FakeNSUserDefaults(localCache: [CloudResourceNsUserDefaultsCacheProvider.userDefaultsId: ["disk:\\": fakeData]])
		let cacheProvider = CloudResourceNsUserDefaultsCacheProvider(loadData: true, userDefaults: fakeUserDefaults)
		let rootCloudResource = FakeCloudResource()
		rootCloudResource.path = "disk:\\"
		let dataFromCache = cacheProvider.getCachedChilds(rootCloudResource)
		XCTAssertEqual(true, dataFromCache?.isEqualToData(fakeData))
	}
	
	func testNotLoadInitialDataFromUserDefaults() {
		let fakeData = "some data".dataUsingEncoding(NSUTF8StringEncoding)!
		let fakeUserDefaults = FakeNSUserDefaults(localCache: [CloudResourceNsUserDefaultsCacheProvider.userDefaultsId: ["disk:\\": fakeData]])
		let cacheProvider = CloudResourceNsUserDefaultsCacheProvider(loadData: false, userDefaults: fakeUserDefaults)
		let rootCloudResource = FakeCloudResource()
		rootCloudResource.path = "disk:\\"
		let dataFromCache = cacheProvider.getCachedChilds(rootCloudResource)
		XCTAssertNil(dataFromCache)
	}
	
	func testClearCachedData() {
		let fakeData = "some data".dataUsingEncoding(NSUTF8StringEncoding)!
		let fakeUserDefaults = FakeNSUserDefaults(localCache: [CloudResourceNsUserDefaultsCacheProvider.userDefaultsId: ["disk:\\": fakeData]])
		let cacheProvider = CloudResourceNsUserDefaultsCacheProvider(loadData: false, userDefaults: fakeUserDefaults)
		cacheProvider.clearCache()
		XCTAssertEqual(0, (fakeUserDefaults.localCache.first?.1 as! [String: NSData]).count)
	}
	
	func testSaveData() {
		let fakeUserDefaults = FakeNSUserDefaults()
		let cacheProvider = CloudResourceNsUserDefaultsCacheProvider(loadData: true, userDefaults: fakeUserDefaults)
		let fakeData = "some data".dataUsingEncoding(NSUTF8StringEncoding)!
		let rootCloudResource = FakeCloudResource()
		rootCloudResource.path = "disk:\\"
		cacheProvider.cacheChilds(rootCloudResource, childsData: fakeData)
		XCTAssertEqual(1, (fakeUserDefaults.localCache.first?.1 as! [String: NSData]).count)
		XCTAssertEqual(rootCloudResource.uid, (fakeUserDefaults.localCache.first?.1 as! [String: NSData]).first?.0)
		XCTAssertEqual(true, (fakeUserDefaults.localCache.first?.1 as! [String: NSData]).first?.1.isEqualToData(fakeData))
	}
	
	func testOwerwriteData() {
		let fakeData = "some data".dataUsingEncoding(NSUTF8StringEncoding)!
		let fakeUserDefaults = FakeNSUserDefaults(localCache: [CloudResourceNsUserDefaultsCacheProvider.userDefaultsId: ["disk:\\": fakeData]])
		let cacheProvider = CloudResourceNsUserDefaultsCacheProvider(loadData: true, userDefaults: fakeUserDefaults)
		let rootCloudResource = FakeCloudResource()
		rootCloudResource.path = "disk:\\"
		let newFakeData = "New data for cache".dataUsingEncoding(NSUTF8StringEncoding)!
		cacheProvider.cacheChilds(rootCloudResource, childsData: newFakeData)
		XCTAssertEqual(true, (fakeUserDefaults.localCache.first?.1 as! [String: NSData]).first?.1.isEqualToData(newFakeData))
	}
}
