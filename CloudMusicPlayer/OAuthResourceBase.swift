//
//  OAuthResource.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 07.02.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation

@objc public protocol OAuthResource {
	var id: String { get }
	var authBaseUrl: String { get }
	var clientId: String? { get set }
	var tokenId: String? { get set }
	optional func getAuthUrl() -> NSURL?
	optional func parseCallbackUrlAndSaveToken(url: String)
}

public class OAuthResourceBase : NSObject, NSCoding, OAuthResource {
	internal static var resources = [String: OAuthResource]()
	public let id: String
	public let authBaseUrl: String
	public var clientId: String?
	public var tokenId: String?
	
	public init(id: String, authUrl: String, clientId: String?, tokenId: String?) {
		self.id = id
		self.authBaseUrl = authUrl
		self.clientId = clientId
		self.tokenId = tokenId
	}
	
	@objc required public init?(coder aDecoder: NSCoder) {
		self.id = aDecoder.decodeObjectForKey("id") as! String
		self.authBaseUrl = aDecoder.decodeObjectForKey("authUrl") as! String
		self.clientId = aDecoder.decodeObjectForKey("clientId") as? String
		self.tokenId = Keychain.stringForAccount("\(self.id)_tokenId")
	}
	
	@objc public func encodeWithCoder(aCoder: NSCoder) {
		aCoder.encodeObject(self.id, forKey: "id")
		aCoder.encodeObject(self.authBaseUrl, forKey: "authUrl")
		aCoder.encodeObject(self.clientId, forKey: "clientId")
		Keychain.setString(self.tokenId, forAccount: "\(self.id)_tokenId", synchronizable: true, background: false)
	}
}

extension OAuthResourceBase {
	/// Load OAuth resource from local cache.
	/// If not exists in cache load from NSUserDefaults and save in local cache and return.
	/// If not exists in NSUserDefaults too, returns nil.
	public static func loadResourceById(id: String) -> OAuthResource? {
		return resources[id] ?? {
			if let loaded = NSUserDefaults.loadData(id) as? OAuthResource {
				resources[id] = loaded
				return loaded
			}
			return nil
		}()
	}
	
	public static func parseCallbackUrlAndSaveToken(url: String) -> OAuthResource? {
		if let schemeEnding = url.rangeOfString(":")?.first {
			print(url.substringToIndex(schemeEnding))
			if let resource = loadResourceById(url.substringToIndex(schemeEnding)) {
				resource.parseCallbackUrlAndSaveToken?(url)
				return resource
			}
		}
		return nil
	}
}

extension OAuthResource {
	public func saveResource() {
		NSUserDefaults.saveData(self, forKey: id)
	}
}