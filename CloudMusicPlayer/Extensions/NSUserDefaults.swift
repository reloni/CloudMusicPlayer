//
//  Extensions.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 07.02.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation

public protocol NSUserDefaultsProtocol {
	func saveData(object: AnyObject, forKey: String)
	func loadData<T>(forKey: String) -> T?
	func loadRawData(forKey: String) -> AnyObject?
	func setObject(value: AnyObject?, forKey: String)
	func objectForKey(forKey: String) -> AnyObject?
}

extension NSUserDefaults : NSUserDefaultsProtocol {
	public func saveData(object: AnyObject, forKey: String) {
		let data = NSKeyedArchiver.archivedDataWithRootObject(object)
		NSUserDefaults.standardUserDefaults().setObject(data, forKey: forKey)
	}
	
	public func loadData<T>(forKey: String) -> T? {
		return loadRawData(forKey) as? T
	}
	
	public func loadRawData(forKey: String) -> AnyObject? {
		if let loadedData = NSUserDefaults.standardUserDefaults().objectForKey(forKey) {
			return NSKeyedUnarchiver.unarchiveObjectWithData(loadedData as! NSData)
		}
		return nil
	}
}

extension NSUserDefaults {
	public static func saveData(object: AnyObject, forKey: String, userDefaults: NSUserDefaultsProtocol = NSUserDefaults.standardUserDefaults()) {
		let data = NSKeyedArchiver.archivedDataWithRootObject(object)
		userDefaults.setObject(data, forKey: forKey)
	}
	
	public static func loadData<T>(forKey: String, userDefaults: NSUserDefaultsProtocol = NSUserDefaults.standardUserDefaults()) -> T? {
		return loadRawData(forKey) as? T
	}
	
	public static func loadRawData(forKey: String, userDefaults: NSUserDefaultsProtocol = NSUserDefaults.standardUserDefaults()) -> AnyObject? {
		if let loadedData = userDefaults.objectForKey(forKey) {
			return NSKeyedUnarchiver.unarchiveObjectWithData(loadedData as! NSData)
		}
		return nil
	}
}