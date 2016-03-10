//
//  OAuthResourceTests.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 09.03.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import XCTest
@testable import CloudMusicPlayer

class FakeNSUserDefaults: NSUserDefaultsProtocol {
	var localCache: [String: AnyObject] = ["testResource": OAuthResourceBase(id: "testResource", authUrl: "https://test", clientId: nil, tokenId: nil)]
	
	func saveData(object: AnyObject, forKey: String) {
		localCache[forKey] = object
	}
	
	func loadData<T>(forKey: String) -> T? {
		return loadRawData(forKey) as? T
	}
	
	func loadRawData(forKey: String) -> AnyObject? {
		return localCache[forKey]
	}
	
	func setObject(value: AnyObject?, forKey: String) {
		guard let value = value else { return }
		saveData(value, forKey: forKey)
	}
	
	func objectForKey(forKey: String) -> AnyObject? {
		return loadRawData(forKey)
	}
}

class OAuthResourceTests: XCTestCase {
	
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
	}
	
	func testYandexCorrectUrlParse() {
		let resource = YandexOAuthResource()
		let token = "b1f893dee2394a85ab1fa90f4a356b2e"
		let url = "oauthyandex://com.AntonEfimenko.CloudMusicPlayer#attr1=asdf&access_token=\(token)&attr2=test"
		XCTAssertEqual(token, resource.parseCallbackUrl(url))
	}
	
	func testYandexIncorrectUrlParse() {
		let resource = YandexOAuthResource()
		let token = "b1f893dee2394a85ab1fa90f4a356b2e"
		let url = "oauthyandex://com.AntonEfimenko.CloudMusicPlayer#attr1=asdf&wrong_token=\(token)&attr2=test"
		XCTAssertNil(resource.parseCallbackUrl(url))
	}
	
	func testCheckNotCachedResource() {
		XCTAssertNil(OAuthResourceManager.getResourceFromLocalCache("notexisted"))
	}
	
	func testAddNewResource() {
		OAuthResourceManager.addResource(YandexOAuthResource())
		XCTAssertEqual(1, OAuthResourceManager.resources.count)
	}
	
	func testLoadNotExistedResource() {
		let userDefaults = FakeNSUserDefaults()
		XCTAssertNil(OAuthResourceManager.loadResourceFromUserDefaults("notExisted", userDefaults: userDefaults))
	}
	
	func testLoadExistedResource() {
		let defaults = FakeNSUserDefaults()
		XCTAssertEqual("testResource", OAuthResourceManager.loadResourceFromUserDefaults("testResource", userDefaults: defaults)?.id)
	}
	
	func testCreatingYandexResource() {
		let defaults = FakeNSUserDefaults()
		let yandex = OAuthResourceManager.getYandexResource(defaults)
		XCTAssertEqual(2, defaults.localCache.count)
		XCTAssertEqual(yandex.id, OAuthResourceManager.loadResourceFromUserDefaults(yandex.id, userDefaults: defaults)?.id)
	}
}
