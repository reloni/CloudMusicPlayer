//
//  OAuthTypes.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 17.05.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import RxSwift

public struct YandexOAuth {
	public static let id = "YandexOAuthResource"
	public let clientId: String
	public let baseAuthUrl: String
	public let urlScheme: String
	public let urlParameters: [String: String]
	public let keychain: KeychainType
	
	internal var tokenKeychainId: String {
		return "\(YandexOAuth.id)_accessToken"
	}
	
	internal var refreshTokenKeychainId: String {
		return "\(YandexOAuth.id)_refreshToken"
	}
	
	public init(baseAuthUrl: String, urlParameters: [String: String], urlScheme: String, clientId: String, keychain: KeychainType) {
		self.baseAuthUrl = baseAuthUrl
		self.urlParameters = urlParameters
		self.urlScheme = urlScheme
		self.clientId = clientId
		self.keychain = keychain
	}
	
	public init(clientId: String, urlScheme: String, keychain: KeychainType) {
		self.init(baseAuthUrl: "https://oauth.yandex.ru/authorize", urlParameters: ["response_type": "token"],
		          urlScheme: urlScheme, clientId:  clientId, keychain: keychain)
	}
}

extension YandexOAuth : OAuthType {
	public var oauthTypeId: String {
		return "\(YandexOAuth.id)_\(clientId)"
	}
	
	public var authUrl: NSURL? {
		var params = urlParameters
		params["client_id"] = clientId
		return NSURL(baseUrl: baseAuthUrl, parameters: params)
	}
	
	public var accessToken: String? {
		return keychain.stringForAccount(tokenKeychainId)
	}
	
	public var refreshToken: String? {
		return keychain.stringForAccount(refreshTokenKeychainId)
	}
	
	public func canParseCallbackUrl(url: String) -> Bool {
		if let schemeEnding = url.rangeOfString(":")?.first {
			return url.substringToIndex(schemeEnding) == urlScheme
		}
		return false
	}
	
	public func authenticate(url: String) -> Observable<OAuthType> {
		return Observable.create { observer in
			if let start = url.rangeOfString("access_token=")?.endIndex {
				let substring = url.substringFromIndex(start)
				let end = substring.rangeOfString("&")?.startIndex ?? substring.endIndex
				
				self.keychain.setString(substring.substringWithRange(substring.startIndex..<end), forAccount: self.tokenKeychainId, synchronizable: true, background: false)
				observer.onNext(self)
			}
			
			observer.onCompleted()
			
			return NopDisposable.instance
		}
	}
	
	public func updateToken() -> Observable<OAuthType> {
		return Observable.empty()
	}
	
	public func clearTokens() {
		keychain.setString(nil, forAccount: tokenKeychainId, synchronizable: true, background: false)
		keychain.setString(nil, forAccount: refreshTokenKeychainId, synchronizable: true, background: false)
		OAuthAuthenticator.sharedInstance.newAuthenticationSubject.onNext(self)
	}
}

public struct GoogleOAuth {
	public static let id = "GoogleOAuthResource"
	public let clientId: String
	public let baseAuthUrl: String
	public let urlScheme: String
	public let urlParameters: [String: String]
	public let redirectUri: String
	public let scopes: [String]
	public let tokenUrl: String
	public let keychain: KeychainType
	
	internal var tokenKeychainId: String {
		return "\(YandexOAuth.id)_accessToken"
	}
	
	internal var refreshTokenKeychainId: String {
		return "\(YandexOAuth.id)_refreshToken"
	}
	
	public init(baseAuthUrl: String, urlParameters: [String: String], urlScheme: String, redirectUri: String,
	            scopes: [String], tokenUrl: String, clientId: String, keychain: KeychainType) {
		self.baseAuthUrl = baseAuthUrl
		self.urlParameters = urlParameters
		self.urlScheme = urlScheme
		self.redirectUri = redirectUri
		self.scopes = scopes
		self.clientId = clientId
		self.tokenUrl = tokenUrl
		self.keychain = keychain
	}
	
	public init(clientId: String, urlScheme: String, redirectUri: String, scopes: [String], keychain: KeychainType) {
		self.init(baseAuthUrl: "https://accounts.google.com/o/oauth2/v2/auth", urlParameters: ["response_type": "code"],
		          urlScheme: urlScheme, redirectUri: redirectUri, scopes: scopes, tokenUrl: "https://www.googleapis.com/oauth2/v4/token",
		          clientId:  clientId, keychain: keychain)
	}
}

extension GoogleOAuth : OAuthType {
	public var oauthTypeId: String {
		return "\(GoogleOAuth.id)_\(clientId)"
	}
	
	public var authUrl: NSURL? {
		var params = urlParameters
		params["client_id"] = clientId
		params["redirect_uri"] = redirectUri
		params["scope"] = scopes.joinWithSeparator(" ")
		return NSURL(baseUrl: baseAuthUrl, parameters: params)
	}
	
	public var accessToken: String? {
		return keychain.stringForAccount(tokenKeychainId)
	}
	
	public var refreshToken: String? {
		return keychain.stringForAccount(refreshTokenKeychainId)
	}
	
	public func canParseCallbackUrl(url: String) -> Bool {
		if let schemeEnding = url.rangeOfString(":")?.first {
			return url.substringToIndex(schemeEnding) == urlScheme
		}
		return false
	}
	
	public func authenticate(url: String) -> Observable<OAuthType> {
		if let start = url.rangeOfString("code=")?.endIndex {
			let substring = url.substringFromIndex(start)
			let end = substring.rangeOfString("&")?.startIndex ?? substring.endIndex
			let code = substring.substringWithRange(substring.startIndex..<end)
			
			// perform second request in order to finally receive access token
			if let tokenUrl = NSURL(baseUrl: self.tokenUrl,
			                        parameters: ["code": code, "client_id": self.clientId, "redirect_uri": self.redirectUri, "grant_type": "authorization_code"]) {
				let request = HttpUtilities().createUrlRequest(tokenUrl)
				request.setHttpMethod("POST")
				let httpClient = HttpClient()
				return httpClient.loadJsonData(request).flatMapLatest { response -> Observable<OAuthType> in
					print(response)
					if let accessToken = response["access_token"].string {
						self.keychain.setString(accessToken, forAccount: self.tokenKeychainId, synchronizable: true, background: false)
					}
					if let refreshToken = response["refresh_token"].string {
						self.keychain.setString(refreshToken, forAccount: self.refreshTokenKeychainId, synchronizable: true, background: false)
					}
					return Observable.just(self)
				}
			}
		}
		
		return Observable.empty()
	}
	
	public func updateToken() -> Observable<OAuthType> {
		// TODO: implement refresh request for Google
		return Observable.empty()
	}
	
	public func clearTokens() {
		keychain.setString(nil, forAccount: tokenKeychainId, synchronizable: true, background: false)
		keychain.setString(nil, forAccount: refreshTokenKeychainId, synchronizable: true, background: false)
		OAuthAuthenticator.sharedInstance.newAuthenticationSubject.onNext(self)
	}
}