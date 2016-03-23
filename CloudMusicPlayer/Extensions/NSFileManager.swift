//
//  NSFileManager.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 04.03.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation

extension NSFileManager {
	public static func getDirectory(directory: NSSearchPathDirectory) -> NSURL {
		return NSFileManager.defaultManager().URLsForDirectory(directory, inDomains: .UserDomainMask)[0]
	}
	
	public static var documentsDirectory: NSURL {
		return NSFileManager.getDirectory(.DocumentDirectory)
	}
	
	public static var streamCacheDirectory: NSURL {
		return getDocumentsSubDirectory("StreamCache")
	}
	
	public static func getDocumentsSubDirectory(dirName: String) -> NSURL {
		let cache = documentsDirectory.URLByAppendingPathComponent(dirName)
		guard let path = cache.path else {
			return documentsDirectory
		}
		
		var isDir: ObjCBool = true
		if NSFileManager.defaultManager().fileExistsAtPath(path, isDirectory: &isDir) {
			return cache
		}
		
		do
		{
			try NSFileManager.defaultManager().createDirectoryAtPath(path, withIntermediateDirectories: false, attributes: nil)
			return cache
		} catch {
			return documentsDirectory
		}
	}
}