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

public protocol OAuthResource {
	var id: CloudResourceType { get }
	var authBaseUrl: String { get }
	var clientId: String? { get set }
	var tokenId: String? { get set }
	func getAuthUrl() -> NSURL?
	func saveResource()
}

public class OAuthResourceBase : NSObject, NSCoding, OAuthResource {
	private static var resources = [String: OAuthResource]()
	public let id: CloudResourceType
	public let authBaseUrl: String
	public var clientId: String?
	public var tokenId: String?
	
	public init(id: CloudResourceType, authUrl: String, clientId: String?, tokenId: String?) {
		self.id = id
		self.authBaseUrl = authUrl
		self.clientId = clientId
		self.tokenId = tokenId
	}
	
	deinit {
		print("deinit")
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
	
	public func saveResource() {
		NSUserDefaults.saveData(self, forKey: self.id.rawValue)
	}
}

extension OAuthResourceBase {
	private static func loadResourceById(id: CloudResourceType) -> OAuthResource? {
		var resource: OAuthResource?
		
		resource = resources[id.rawValue]
		
		if resource == nil {
			resource = NSUserDefaults.loadData(id.rawValue) as? OAuthResource
		}
		
		if resource == nil {
			if id == .Yandex {
				resource = self.Yandex
			} else {
				return nil
			}
		}
		if resource != nil && !resources.keys.contains(id.rawValue)
		{
			resources[id.rawValue] = resource
		}
		
		return resource
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
}