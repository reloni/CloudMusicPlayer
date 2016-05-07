//
//  CloudResourceCacheProvider.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 20.04.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import Realm
import RealmSwift
import SwiftyJSON

public protocol CloudResourceCacheProviderType {
	func getCachedChilds(parent: CloudResource) -> [CloudResource]
	func cacheChilds(parent: CloudResource, childs: [CloudResource])
	func clearCache()
}

public class RealmCloudResource : Object {
	public internal(set) dynamic var uid: String
	public internal(set) dynamic var rawData: NSData
	public internal (set) dynamic var parent: RealmCloudResource?
	public let childs = List<RealmCloudResource>()
	
	required public init(uid: String, rawData: NSData = NSData()) {
		self.uid = uid
		self.rawData = rawData
		super.init()
	}
	
	public required init(realm: RLMRealm, schema: RLMObjectSchema) {
		uid = NSUUID().UUIDString
		rawData = NSData()
		super.init(realm: realm, schema: schema)
	}
	
	public required init(value: AnyObject, schema: RLMSchema) {
		uid = NSUUID().UUIDString
		rawData = NSData()
		super.init(value: value, schema: schema)
	}
	
	public required init() {
		uid = NSUUID().UUIDString
		rawData = NSData()
		super.init()
	}
	
	override public static func primaryKey() -> String? {
		return "uid"
	}
}

public class RealmCloudResourceCacheProvider {
	
}

extension RealmCloudResourceCacheProvider : CloudResourceCacheProviderType {
	public func getCachedChilds(parent: CloudResource) -> [CloudResource] {
		var result = [CloudResource]()
		autoreleasepool {
			let realm = try? Realm()
			if let realm = realm {
				guard let parentObject = realm.objects(RealmCloudResource).filter("uid = %@", parent.uid).first else {
					return
				}
				result = parentObject.childs.map { o in
					return parent.wrapRawData(JSON(data: o.rawData))
					}.flatMap { $0 }
			}
		}
		
		return result
	}
	
	public func cacheChilds(parent: CloudResource, childs: [CloudResource]) {
		autoreleasepool {
			let realm = try? Realm()
			if let realm = realm {
				let _ = try! realm.write {
					let parentObject = createResource(realm, resource: parent, parentObjectUid: parent.parent?.uid ?? "")
					parentObject.childs.removeAll()
					childs.forEach { child in
						parentObject.childs.append(createResource(realm, resource: child, parentObjectUid: parentObject.uid))
					}
					realm.add(parentObject)
				}
			}
		}
	}
	
	internal func createResource(realm: Realm, resource: CloudResource, parentObjectUid: String) -> RealmCloudResource {
		let parentObject = realm.objects(RealmCloudResource).filter("uid = %@", parentObjectUid).first
		if let existedResource = realm.objects(RealmCloudResource).filter("uid = %@", resource.uid).first {
			existedResource.parent = parentObject
			existedResource.rawData = resource.raw.safeRawData() ?? NSData()
			return existedResource
		}
		
		let newResource = RealmCloudResource(uid: resource.uid, rawData: resource.raw.safeRawData() ?? NSData())
		newResource.parent = parentObject
		
		return newResource
	}
	
	public func clearCache() {
		autoreleasepool {
			let realm = try? Realm()
			if let realm = realm {
				let _ = try? realm.write {
					realm.delete(realm.objects(RealmCloudResource))
				}
			}
		}
	}
}

//public class CloudResourceNsUserDefaultsCacheProvider {
//	internal static let userDefaultsId = "CMP_CloudResourceCache"
//	internal var cachedData = [String: NSData]()
//	internal let userDefaults: NSUserDefaultsProtocol
//	
//	public convenience init(loadCachedData loadData: Bool = false) {
//		self.init(loadData: loadData, userDefaults: NSUserDefaults.standardUserDefaults())
//	}
//	
//	internal init(loadData: Bool = false, userDefaults: NSUserDefaultsProtocol = NSUserDefaults.standardUserDefaults()) {
//		self.userDefaults = userDefaults
//		if loadData {
//			if let data = self.userDefaults.loadRawData(CloudResourceNsUserDefaultsCacheProvider.userDefaultsId) as? [String: NSData] {
//				cachedData = data
//			}
//		}
//	}
//}
//
//extension CloudResourceNsUserDefaultsCacheProvider: CloudResourceCacheProviderType {
//	public func getCachedChilds(parent: CloudResource) -> NSData? {
//		return getCachedChilds(parent.uid)
//	}
//	
//	public func getCachedChilds(parentUid: String) -> NSData? {
//		return cachedData[parentUid]
//	}
//	
//	public func cacheChilds(parent: CloudResource, childsData: NSData) {
//		return cacheChilds(parent.uid, childsData: childsData)
//	}
//	
//	public func cacheChilds(parentUid: String, childsData: NSData) {
//		cachedData[parentUid] = childsData
//		userDefaults.saveData(cachedData, forKey: CloudResourceNsUserDefaultsCacheProvider.userDefaultsId)
//	}
//	
//	public func clearCache() {
//		cachedData.removeAll()
//		userDefaults.saveData(cachedData, forKey: CloudResourceNsUserDefaultsCacheProvider.userDefaultsId)
//	}
//}