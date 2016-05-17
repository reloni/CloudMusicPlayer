//
//  OAuth.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 17.05.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import RxSwift

public protocol OAuthType {
	var oauthTypeId: String { get }
	var authUrl: NSURL? { get }
	var clientId: String { get }
	var accessToken: String? { get }
	var refreshToken: String? { get }
	func canParseCallbackUrl(url: String) -> Bool
	func authenticate(url: String) -> Observable<OAuthType>
	func updateToken() -> Observable<OAuthType>
	func clearTokens()
}

public class OAuthAuthenticator {
	public init() { }
	public static let sharedInstance = OAuthAuthenticator()
	public var connections = [String: OAuthType]()
	internal let newAuthenticationSubject = PublishSubject<OAuthType>()
	
	public var authentications: Observable<OAuthType> {
		return newAuthenticationSubject
	}
	
	public func addConnection(oauth: OAuthType) {
		connections[oauth.oauthTypeId] = oauth
	}
	
	public func removeConnection(oauth: OAuthType) {
		connections[oauth.oauthTypeId] = nil
	}
	
	public func processCallbackUrl(url: String) -> Observable<OAuthType> {
		for connection in connections.values {
			if connection.canParseCallbackUrl(url) {
				return connection.authenticate(url).doOnNext { [weak self] oauth in self?.newAuthenticationSubject.onNext(oauth) }
			}
		}
		return Observable.empty()
	}
}