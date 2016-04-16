//
//  OAuthResourceTests.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 09.03.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import XCTest
@testable import CloudMusicPlayer

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
		XCTAssertNil(OAuthResourceManager().getResourceFromLocalCache("notexisted"))
	}

	func testAddNewResource() {
		let manager = OAuthResourceManager()
		manager.addResource(YandexOAuthResource())
		XCTAssertEqual(1, manager.resources.count)
	}
	
	func testLoadNotExistedResource() {
		let userDefaults = FakeNSUserDefaults(localCache: ["testResource": OAuthResourceBase(id: "testResource", authUrl: "https://test", clientId: nil, tokenId: nil)])
			XCTAssertNil(OAuthResourceManager().loadResourceFromUserDefaults("notExisted", userDefaults: userDefaults))
	}

	func testLoadExistedResource() {
		let defaults = FakeNSUserDefaults(localCache: ["testResource": OAuthResourceBase(id: "testResource", authUrl: "https://test", clientId: nil, tokenId: nil)])
			XCTAssertEqual("testResource", OAuthResourceManager().loadResourceFromUserDefaults("testResource", userDefaults: defaults)?.id)
	}
	
	func testCreatingYandexResource() {
		let manager = OAuthResourceManager()
		let defaults = FakeNSUserDefaults(localCache: ["testResource": OAuthResourceBase(id: "testResource", authUrl: "https://test", clientId: nil, tokenId: nil)])
			let yandex = OAuthResourceManager.getYandexResource(defaults, manager: manager)
			XCTAssertEqual(2, defaults.localCache.count)
			XCTAssertEqual(1, manager.resources.count)
			XCTAssertEqual(yandex.id, manager.loadResourceFromUserDefaults(yandex.id, userDefaults: defaults)?.id)
	}
}
