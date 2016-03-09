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
	private init() {
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
			return substring.substringWithRange(Range<String.Index>(start: substring.startIndex, end: end))
		}
		return nil
	}
}

extension OAuthResourceManager {
	public static var Yandex: OAuthResource {
		return OAuthResourceManager.loadResource(YandexOAuthResource.id) ?? {
			let newResource = YandexOAuthResource()
			OAuthResourceManager.addResource(newResource)
			newResource.saveResource()
			return newResource
		}()
	}
}