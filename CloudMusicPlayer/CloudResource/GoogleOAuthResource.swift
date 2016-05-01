//
//  GoogleOAuthResource.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 01.05.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation

public class GoogleOAuthResource : OAuthResourceBase {
	public static let id = "com.antonefimenko.cloudmusicplayer"
	internal init() {
		super.init(id: GoogleOAuthResource.id, authUrl: "https://accounts.google.com/o/oauth2/v2/auth?response_type=code",
		           clientId: "904693090582-807d6m390ms26lis6opjfbrjnr0qns7k.apps.googleusercontent.com", tokenId: nil)
	}
	
	@objc required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	public func getAuthUrl() -> NSURL? {
		if let clientId = clientId {
			return NSURL(string: "\(authBaseUrl)&client_id=\(clientId)&redirect_uri=\(id):/cmp.ru&scope=openid%20email")
		}
		return nil
	}
	
	public func parseCallbackUrl(url: String) -> String? {
		if let start = url.rangeOfString("code=")?.endIndex {
			let substring = url.substringFromIndex(start)
			let end = substring.rangeOfString("&")?.startIndex ?? substring.endIndex
			return substring.substringWithRange(substring.startIndex..<end)
		}
		return nil
	}
}

extension OAuthResourceManager {
	public static func getGoogleResource(userDefaults: NSUserDefaultsProtocol = NSUserDefaults.standardUserDefaults(),
	                                     manager: OAuthResourceManager = OAuthResourceManager()) -> OAuthResource {
		return manager.loadResource(GoogleOAuthResource.id, userDefaults: userDefaults) ?? {
			let newResource = GoogleOAuthResource()
			manager.addResource(newResource)
			newResource.saveResource(userDefaults)
			return newResource
			}()
	}
}