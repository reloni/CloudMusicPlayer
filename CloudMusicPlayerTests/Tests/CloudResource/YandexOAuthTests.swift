//
//  YandexOAuthTests.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 17.05.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import XCTest
import CloudMusicPlayer

class YandexOAuthTests: XCTestCase {
	
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
	}
	
	func testCanParseUrl() {
		let oauth = YandexOAuth(clientId: "test_client_id", urlScheme: "yandex_oauth_scheme")
		let token = "b1f893dee2394a85ab1fa90f4a356b2e"
		let url = "yandex_oauth_scheme://com.AntonEfimenko.CloudMusicPlayer#attr1=asdf&access_token=\(token)&attr2=test"
		XCTAssertTrue(oauth.canParseCallbackUrl(url))
	}
	
	func testCannotParseIncorrectUrl() {
		let oauth = YandexOAuth(clientId: "test_client_id", urlScheme: "yandex_oauth_scheme")
		let token = "b1f893dee2394a85ab1fa90f4a356b2e"
		let url = "yandex_oauth_scheme_wrong://com.AntonEfimenko.CloudMusicPlayer#attr1=asdf&access_token=\(token)&attr2=test"
		XCTAssertFalse(oauth.canParseCallbackUrl(url))
	}
}
