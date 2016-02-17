//
//  Yandex.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 13.02.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation

public class YandexOAuthResource : OAuthResourceBase {
	private init() {
		super.init(id: .Yandex, authUrl: "https://oauth.yandex.ru/authorize?response_type=token", clientId: "6556b9ed6fb146ea824d2e1f0d98f09b", tokenId: nil)
		OAuthResourceBase.resources[CloudResourceType.Yandex.rawValue] = self
		self.saveResource()
	}
	
	@objc required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	public override func getAuthUrl() -> NSURL? {
		if let clientId = clientId {
			return NSURL(string: "\(authBaseUrl)&client_id=\(clientId)")
		}
		return nil
	}
}

extension OAuthResourceBase {
	public static var Yandex: OAuthResource {
		return loadResourceById(.Yandex) ?? {
			return YandexOAuthResource()
		}()
	}
	
	public static func parseYandexCallbackUrl(url: String) -> OAuthResource? {
		if let start = url.rangeOfString("access_token=")?.endIndex, end = url.rangeOfString("&token_type=")?.startIndex {
			let token = url.substringWithRange(Range<String.Index>(start: start, end: end))
			var resource = getResourceById(.Yandex)
			resource?.tokenId = token
			print(token)
			resource?.saveResource()
			return resource
		}
		
		return nil
	}
}