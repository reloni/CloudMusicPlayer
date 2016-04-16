//
//  Yandex.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 13.02.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation

public class YandexOAuthResource : OAuthResourceBase {
	public static let id = "oauthyandex"
	internal init() {
		super.init(id: YandexOAuthResource.id, authUrl: "https://oauth.yandex.ru/authorize?response_type=token", clientId: "6556b9ed6fb146ea824d2e1f0d98f09b", tokenId: nil)
	}
	
	@objc required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	public func getAuthUrl() -> NSURL? {
		if let clientId = clientId {
			return NSURL(string: "\(authBaseUrl)&client_id=\(clientId)")
		}
		return nil
	}
	
	public func parseCallbackUrl(url: String) -> String? {
		if let start = url.rangeOfString("access_token=")?.endIndex {
			let substring = url.substringFromIndex(start)
			let end = substring.rangeOfString("&")?.startIndex ?? substring.endIndex
			return substring.substringWithRange(substring.startIndex..<end)
		}
		return nil
	}
}

extension OAuthResourceManager {
	public static func getYandexResource(userDefaults: NSUserDefaultsProtocol = NSUserDefaults.standardUserDefaults(),
	                                     manager: OAuthResourceManager = OAuthResourceManager()) -> OAuthResource {
		return manager.loadResource(YandexOAuthResource.id, userDefaults: userDefaults) ?? {
			let newResource = YandexOAuthResource()
			manager.addResource(newResource)
			newResource.saveResource(userDefaults)
			return newResource
		}()
	}
}