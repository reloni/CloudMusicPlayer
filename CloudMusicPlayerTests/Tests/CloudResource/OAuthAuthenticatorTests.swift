//
//  NewOAuthTests.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 17.05.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import XCTest
@testable import CloudMusicPlayer

class OAuthAuthenticatorTests: XCTestCase {
	
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
	}
	
	func testAuthenticateYandex() {
		let keychain = FakeKeychain()
		let oauth = YandexOAuth(clientId: "test_client_id", urlScheme: "yandex_oauth_scheme", keychain: keychain)
		let token = "b1f893dee2394a85ab1fa90f4a356b2e"
		let url = "yandex_oauth_scheme://com.AntonEfimenko.CloudMusicPlayer#attr1=asdf&access_token=\(token)&attr2=test"
		
		let authenticator = OAuthAuthenticator()
		authenticator.addConnection(oauth)
		authenticator.addConnection(GoogleOAuth(clientId: "test", urlScheme: "test", redirectUri: "test", scopes: [], keychain: keychain))
		
		try! authenticator.processCallbackUrl(url).toBlocking().first()
		
		XCTAssertEqual(keychain.keychain.count, 1)
		XCTAssertEqual(String(data: keychain.keychain.first?.1 ?? NSData(), encoding: NSUTF8StringEncoding), token)
		XCTAssertEqual(oauth.accessToken, token)
		XCTAssertNil(oauth.refreshToken)
		XCTAssertEqual(keychain.keychain.first?.0, oauth.tokenKeychainId)
	}
	
	func testNotAuthenticateYandexIfConnectionNotExisted() {
		let keychain = FakeKeychain()
		let authenticator = OAuthAuthenticator()
		authenticator.addConnection(GoogleOAuth(clientId: "test", urlScheme: "test", redirectUri: "test", scopes: [], keychain: keychain))
		
		let token = "b1f893dee2394a85ab1fa90f4a356b2e"
		let url = "yandex_oauth_scheme://com.AntonEfimenko.CloudMusicPlayer#attr1=asdf&access_token=\(token)&attr2=test"
		let authenticated = try! authenticator.processCallbackUrl(url).toBlocking().first()
		
		XCTAssertNil(authenticated)
		XCTAssertEqual(keychain.keychain.count, 0)
	}
}
