//
//  CloudResourceCacheProvider.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 20.04.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation

public protocol CloudResourceCacheProviderType {
	func getCachedChilds(parent: CloudResource) -> NSData?
	func getCachedChilds(parentUid: String) -> NSData?
	func cacheChilds(parent: CloudResource, childsData: NSData)
	func cacheChilds(parentUid: String, childsData: NSData)
	func clearCache()
}

public class CloudResourceNsUserDefaultsCacheProvider {
	internal static let userDefaultsId = "CMP_CloudResourceCache"
	internal var cachedData = [String: NSData]()
	internal let userDefaults: NSUserDefaultsProtocol
	
	public convenience init(loadCachedData loadData: Bool = false) {
		self.init(loadData: loadData, userDefaults: NSUserDefaults.standardUserDefaults())
	}
	
	internal init(loadData: Bool = false, userDefaults: NSUserDefaultsProtocol = NSUserDefaults.standardUserDefaults()) {
		self.userDefaults = userDefaults
		if loadData {
			if let data = self.userDefaults.loadRawData(CloudResourceNsUserDefaultsCacheProvider.userDefaultsId) as? [String: NSData] {
				cachedData = data
			}
		}
	}
}

extension CloudResourceNsUserDefaultsCacheProvider: CloudResourceCacheProviderType {
	public func getCachedChilds(parent: CloudResource) -> NSData? {
		return getCachedChilds(parent.uid)
	}
	
	public func getCachedChilds(parentUid: String) -> NSData? {
		return cachedData[parentUid]
	}
	
	public func cacheChilds(parent: CloudResource, childsData: NSData) {
		return cacheChilds(parent.uid, childsData: childsData)
	}
	
	public func cacheChilds(parentUid: String, childsData: NSData) {
		cachedData[parentUid] = childsData
		userDefaults.saveData(cachedData, forKey: CloudResourceNsUserDefaultsCacheProvider.userDefaultsId)
	}
	
	public func clearCache() {
		cachedData.removeAll()
		userDefaults.saveData(cachedData, forKey: CloudResourceNsUserDefaultsCacheProvider.userDefaultsId)
	}
}