//
//  CacheProvider.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 01.04.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation

public protocol CacheProvider {
	var currentDataLength: UInt64 { get }
	func appendData(data: NSData)
	func getData() -> NSData
	func getData(offset: Int, length: Int) -> NSData
	func saveData() -> NSURL?
	func saveData(fileExtension: String?) -> NSURL?
}

public class MemoryCacheProvider {
	internal let cacheData = NSMutableData()
}

extension MemoryCacheProvider : CacheProvider {
	public var currentDataLength: UInt64 {
		return UInt64(cacheData.length)
	}
	
	public func appendData(data: NSData) {
		cacheData.appendData(data)
	}
	
	public func getData() -> NSData {
		return cacheData
	}
	
	public func getData(offset: Int, length: Int) -> NSData {
		return cacheData.subdataWithRange(NSMakeRange(Int(offset), Int(length)))
	}
	
	public func saveData(fileExtension: String?) -> NSURL? {
		let path = NSFileManager.streamCacheDirectory.URLByAppendingPathComponent("\(NSUUID().UUIDString).\(fileExtension ?? "dat")")
		if cacheData.writeToURL(path, atomically: true) {
			return path
		}
		return nil
	}
	
	public func saveData() -> NSURL? {
		return saveData()
	}
}