//
//  NewOAuthTests.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 17.05.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import XCTest
import RxSwift
@testable import CloudMusicPlayer

class OAuthAuthenticatorTests: XCTestCase {
	let bag = DisposeBag()
	
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
	}
	
	func testAddConnection() {
		let authenticator = OAuthAuthenticator()
		authenticator.addConnection(YandexOAuth())
		XCTAssertEqual(authenticator.connections.count, 1)
	}
	
	func testRemoveConnection() {
		let authenticator = OAuthAuthenticator()
		authenticator.addConnection(YandexOAuth())
		authenticator.removeConnection(YandexOAuth())
		XCTAssertEqual(authenticator.connections.count, 0)
	}
	
	func testAuthenticateYandex() {
		let keychain = FakeKeychain()
		let oauth = YandexOAuth(clientId: "test_client_id", urlScheme: "yandex_oauth_scheme", keychain: keychain)
		let token = "b1f893dee2394a85ab1fa90f4a356b2e"
		let url = "yandex_oauth_scheme://com.AntonEfimenko.CloudMusicPlayer#attr1=asdf&access_token=\(token)&attr2=test"
		
		let authenticator = OAuthAuthenticator()
		authenticator.addConnection(oauth)
		authenticator.addConnection(GoogleOAuth(clientId: "test", urlScheme: "test", redirectUri: "test", scopes: [], keychain: keychain))
		
		let expectation = expectationWithDescription("Should send notification with authenticated OAuth object")
		authenticator.processedAuthentications.bindNext {
			if $0.accessToken == token { expectation.fulfill() }
		}.addDisposableTo(bag)
		
		try! authenticator.processCallbackUrl(url).toBlocking().first()
		waitForExpectationsWithTimeout(1, handler: nil)
		
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
		
		authenticator.processedAuthentications.bindNext { _ in
			XCTFail("Should not send event")
			}.addDisposableTo(bag)
		
		let authenticated = try! authenticator.processCallbackUrl(url).toBlocking().first()
		
		XCTAssertNil(authenticated)
		XCTAssertEqual(keychain.keychain.count, 0)
	}
	
	func testYandexClearKeychainAndSendNotofication() {
		let keychain = FakeKeychain()
		let authenticator = OAuthAuthenticator()
		let oauth = YandexOAuth(clientId: "test_client_id", urlScheme: "yandex_oauth_scheme", keychain: keychain, authenticator: authenticator)
		keychain.keychain[oauth.tokenKeychainId] = "old token".dataUsingEncoding(NSUTF8StringEncoding)
		
		let expectation = expectationWithDescription("Should send event with OAuth object")
		authenticator.processedAuthentications.bindNext {
			if $0.accessToken == nil { expectation.fulfill() }
		}.addDisposableTo(bag)
		
		oauth.clearTokens()
		waitForExpectationsWithTimeout(1, handler: nil)
		XCTAssertEqual(keychain.keychain.count, 0)
	}
	
	func testYandexUpdateTokenDoNothing() {
		let authenticator = OAuthAuthenticator()
		let oauth = YandexOAuth(clientId: "id", urlScheme: "scheme", authenticator: authenticator)
		let expectation = expectationWithDescription("Should complete and don't send any data")
		authenticator.processedAuthentications.bindNext { _ in
			XCTFail("Should not send any data")
			}.addDisposableTo(bag)
		oauth.updateToken().doOnCompleted { expectation.fulfill() }.bindNext { _ in XCTFail("Should not send any data") }.addDisposableTo(bag)
		
		waitForExpectationsWithTimeout(1, handler: nil)
	}
}
