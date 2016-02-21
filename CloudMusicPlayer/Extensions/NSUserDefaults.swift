//
//  Extensions.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 07.02.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation

extension NSUserDefaults {
	public static func saveData(object: AnyObject, forKey: String) {
		let data = NSKeyedArchiver.archivedDataWithRootObject(object)
		NSUserDefaults.standardUserDefaults().setObject(data, forKey: forKey)
	}
	
	public static func loadData<T>(forKey: String) -> T? {
		if let loadedData = NSUserDefaults.standardUserDefaults().objectForKey(forKey) {
			let data = NSKeyedUnarchiver.unarchiveObjectWithData(loadedData as! NSData) as! T
			return data
		}
		return nil
	}
	
	public static func loadRawData(forKey: String) -> AnyObject? {
		if let loadedData = NSUserDefaults.standardUserDefaults().objectForKey(forKey) {
			return NSKeyedUnarchiver.unarchiveObjectWithData(loadedData as! NSData)
		}
		return nil
	}
}