//
//  YandexOAuthTests.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 17.05.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import XCTest
@testable import CloudMusicPlayer

extension YandexOAuth {
	public init(clientId: String, urlScheme: String) {
		self.init(clientId: clientId, urlScheme: urlScheme, keychain: FakeKeychain())
	}
}

class YandexOAuthTests: XCTestCase {
	
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
	}
	
//	func testAuthUrl() {
//		let oauth = YandexOAuth(baseAuthUrl: "http://base.com", urlParameters: ["param1": "value1", "param2": "value2"], urlScheme: "testchheme",
//		                        clientId: "fake_id", keychain: FakeKeychain())
//		XCTAssertEqual(oauth.authUrl, NSURL(baseUrl: "http://base.com", parameters: ["client_id": "fake_id", "param1": "value1", "param2": "value2"]))
//	}
	
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
	
	func testReadExistedTokenFromKeychain() {
		let keychain = FakeKeychain()
		let oauth = YandexOAuth(clientId: "test_client_id", urlScheme: "yandex_oauth_scheme", keychain: keychain)
		keychain.keychain[oauth.tokenKeychainId] = "some token".dataUsingEncoding(NSUTF8StringEncoding)
		XCTAssertEqual(oauth.accessToken, "some token")
	}
	
	func testAuthenticate() {
		let keychain = FakeKeychain()
		let oauth = YandexOAuth(clientId: "test_client_id", urlScheme: "yandex_oauth_scheme", keychain: keychain)
		let token = "b1f893dee2394a85ab1fa90f4a356b2e"
		let url = "yandex_oauth_scheme_wrong://com.AntonEfimenko.CloudMusicPlayer#attr1=asdf&access_token=\(token)&attr2=test"
		try! oauth.authenticate(url).toBlocking().first()
		XCTAssertEqual(keychain.keychain.count, 1)
		XCTAssertEqual(String(data: keychain.keychain.first?.1 ?? NSData(), encoding: NSUTF8StringEncoding), token)
		XCTAssertEqual(oauth.accessToken, token)
		XCTAssertNil(oauth.refreshToken)
		XCTAssertEqual(keychain.keychain.first?.0, oauth.tokenKeychainId)
	}
	
	func testAuthenticateAndOverwriteExistedToken() {
		let keychain = FakeKeychain()
		let oauth = YandexOAuth(clientId: "test_client_id", urlScheme: "yandex_oauth_scheme", keychain: keychain)
		keychain.keychain[oauth.tokenKeychainId] = "old token".dataUsingEncoding(NSUTF8StringEncoding)
		let token = "b1f893dee2394a85ab1fa90f4a356b2e"
		let url = "yandex_oauth_scheme://com.AntonEfimenko.CloudMusicPlayer#attr1=asdf&access_token=\(token)&attr2=test"
		try! oauth.authenticate(url).toBlocking().first()
		XCTAssertEqual(keychain.keychain.count, 1)
		XCTAssertEqual(String(data: keychain.keychain.first?.1 ?? NSData(), encoding: NSUTF8StringEncoding), token)
		XCTAssertEqual(oauth.accessToken, token)
		XCTAssertNil(oauth.refreshToken)
		XCTAssertEqual(keychain.keychain.first?.0, oauth.tokenKeychainId)
	}
	
	func testNotAuthenticateWithIncorrectUrl() {
		let keychain = FakeKeychain()
		let oauth = YandexOAuth(clientId: "test_client_id", urlScheme: "yandex_oauth_scheme", keychain: keychain)
		let token = "b1f893dee2394a85ab1fa90f4a356b2e"
		let url = "yandex_oauth_scheme://com.AntonEfimenko.CloudMusicPlayer#attr1=asdf&access_token_wrong=\(token)&attr2=test"
		let authenticated = try! oauth.authenticate(url).toBlocking().first()
		XCTAssertNil(authenticated)
		XCTAssertEqual(keychain.keychain.count, 0)
		XCTAssertNil(oauth.accessToken)
	}
}
