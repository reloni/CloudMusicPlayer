//
//  OAuthResource.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 07.02.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation

public enum CloudResourceType: String {
	case Yandex = "oauthYandex"
	case Google = "oauthGoogle"
}

public enum OAuthError: ErrorType {
	case NotImplemented
}

public class OAuthResourceBase : NSObject, NSCoding, OAuthResource {
	public let id: CloudResourceType
	public let authBaseUrl: String
	public var clientId: String?
	public var tokenId: String?
	
	private init(id: CloudResourceType, authUrl: String, clientId: String?, tokenId: String?) {
		self.id = id
		self.authBaseUrl = authUrl
		self.clientId = clientId
		self.tokenId = tokenId
	}
	
	@objc required public init?(coder aDecoder: NSCoder) {
		self.id = CloudResourceType.init(rawValue: aDecoder.decodeObjectForKey("id") as! String)!
		self.authBaseUrl = aDecoder.decodeObjectForKey("authUrl") as! String
		self.clientId = aDecoder.decodeObjectForKey("clientId") as? String
		self.tokenId = Keychain.stringForAccount("\(self.id)_tokenId")
	}
	
	@objc public func encodeWithCoder(aCoder: NSCoder) {
		aCoder.encodeObject(self.id.rawValue, forKey: "id")
		aCoder.encodeObject(self.authBaseUrl, forKey: "authUrl")
		aCoder.encodeObject(self.clientId, forKey: "clientId")
		Keychain.setString(self.tokenId, forAccount: "\(self.id)_tokenId", synchronizable: true, background: false)
	}
	
	public func getAuthUrl() -> NSURL? {
		return nil
	}
}

public protocol OAuthResource {
	var id: CloudResourceType { get }
	var authBaseUrl: String { get }
	var clientId: String? { get set }
	var tokenId: String? { get set }
	func getAuthUrl() -> NSURL?
}

public class YandexOAuthResource : OAuthResourceBase {
	init() {
		super.init(id: .Yandex, authUrl: "https://oauth.yandex.ru/authorize?response_type=token", clientId: "6556b9ed6fb146ea824d2e1f0d98f09b", tokenId: nil)
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
	static public var Yandex: OAuthResource {
//		return OAuthResourceBase(id: .Yandex,
//			authUrl: "https://oauth.yandex.ru/authorize?response_type=token",
//			clientId: "6556b9ed6fb146ea824d2e1f0d98f09b",
//			tokenId: nil)
		return getResourceById(.Yandex) ?? YandexOAuthResource()
	}
	
	private static func loadResourceById(id: CloudResourceType) -> OAuthResource? {
		//if let resource: OAuthResourceBase? = NSUserDefaults.loadData(id.rawValue) {
		if let resource = NSUserDefaults.loadData(id.rawValue) as? OAuthResource {
			return resource
		}
		if id == .Yandex {
			return self.Yandex
		} else {
			return nil
		}
	}
	
	public static func getResourceById(id: CloudResourceType) -> OAuthResource? {
		return loadResourceById(id)
	}
	
	public static func parseCallbackUrl(url: String) -> OAuthResource? {
		if url.lowercaseString.hasPrefix(CloudResourceType.Yandex.rawValue.lowercaseString) {
			return parseYandexCallbackUrl(url)
		}
		return nil
	}
	
	public static func parseYandexCallbackUrl(url: String) -> OAuthResource? {
		if let start = url.rangeOfString("access_token=")?.endIndex, end = url.rangeOfString("&token_type=")?.startIndex {
			let token = url.substringWithRange(Range<String.Index>(start: start, end: end))
			if let resource = getResourceById(.Yandex) as? OAuthResourceBase {
				resource.tokenId = token
				NSUserDefaults.saveData(resource, forKey: resource.id.rawValue)
				return resource
			}
		}
		
		return nil
	}
}