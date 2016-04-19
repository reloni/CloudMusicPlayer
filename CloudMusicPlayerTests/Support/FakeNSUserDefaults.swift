//
//  FakeNSUserDefaults.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 13.04.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import CloudMusicPlayer

class FakeNSUserDefaults: NSUserDefaultsProtocol {
	var localCache: [String: AnyObject]
		//["testResource": OAuthResourceBase(id: "testResource", authUrl: "https://test", clientId: nil, tokenId: nil)]
	
	init(localCache: [String: AnyObject]) {
		self.localCache = localCache
	}
	
	convenience init() {
		self.init(localCache: [String: AnyObject]())
	}
	
	func saveData(object: AnyObject, forKey: String) {
		localCache[forKey] = object
	}
	
	func loadData<T>(forKey: String) -> T? {
		return loadRawData(forKey) as? T
	}
	
	func loadRawData(forKey: String) -> AnyObject? {
		return localCache[forKey]
	}
	
	func setObject(value: AnyObject?, forKey: String) {
		guard let value = value else { return }
		saveData(value, forKey: forKey)
	}
	
	func objectForKey(forKey: String) -> AnyObject? {
		return loadRawData(forKey)
	}
}