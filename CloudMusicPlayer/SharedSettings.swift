//
//  SharedSettings.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 24.01.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation

public class SharedSettings {
	public static let Instance: SharedSettings = SharedSettings()
	
	public var cloudResources: [String: CloudResource]
	
	private init() {
		if let savedResources = NSUserDefaults.standardUserDefaults().objectForKey("cloudResources") {
			cloudResources = NSKeyedUnarchiver.unarchiveObjectWithData(savedResources as! NSData) as! [String: CloudResource]
		} else {
			cloudResources = [String: CloudResource]()
		}
	}
	
	deinit {
		saveData()
	}
	
	public func addCloudResource(resourceId: String, token: String) -> Void {
		if !cloudResources.keys.contains(resourceId) {
			cloudResources[resourceId] = CloudResource(resourceId: resourceId, token: token)
		}
	}
	
	public func removeCloudResource(resourceId: String) {
		cloudResources[resourceId] = nil
	}
	
	public func getCloudResource(resourceId: String) -> CloudResource? {
		return cloudResources[resourceId]
	}
	
	public func saveData() {
		let data = NSKeyedArchiver.archivedDataWithRootObject(cloudResources)
		NSUserDefaults.standardUserDefaults().setObject(data, forKey: "cloudResources")
	}
}

public class CloudResource : NSObject, NSCoding {
	let token: String
	let resourceId: String
	
	init(resourceId: String, token: String) {
		self.resourceId = resourceId
		self.token = token
	}
	
	@objc required public init?(coder aDecoder: NSCoder) {
		self.token = aDecoder.decodeObjectForKey("token") as! String
		self.resourceId = aDecoder.decodeObjectForKey("resourceId") as! String
	}
	
	@objc public func encodeWithCoder(aCoder: NSCoder) {
		aCoder.encodeObject(self.token, forKey: "token")
		aCoder.encodeObject(self.resourceId, forKey: "resourceId")
	}
}