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
	
	public func parseCallbackUrlAndSaveToken(url: String) {
		if let start = url.rangeOfString("access_token=")?.endIndex, end = url.rangeOfString("&token_type=")?.startIndex {
			self.tokenId = url.substringWithRange(Range<String.Index>(start: start, end: end))
			saveResource()
		}
	}
}

extension OAuthResourceBase {
	public static var Yandex: OAuthResource {
		return loadResourceById(YandexOAuthResource.id) ?? {
			let newResource = YandexOAuthResource()
			OAuthResourceBase.resources[YandexOAuthResource.id] = newResource
			newResource.saveResource()
			return newResource
		}()
	}
}