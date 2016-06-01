//
//  CacheProvider.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 01.04.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation

public protocol CacheProvider {
	var uid: String { get }
	var currentDataLength: UInt64 { get }
	var expectedDataLength: Int64 { get set }
	var contentMimeType: String? { get }
	func appendData(data: NSData)
	func getData() -> NSData
	func getData(offset: Int, length: Int) -> NSData
	func saveData() -> NSURL?
	func saveData(fileExtension: String?) -> NSURL?
	func saveData(destinationDirectory: NSURL, fileExtension: String?) -> NSURL?
	func saveData(destinationDirectory: NSURL) -> NSURL?
	func setContentMimeType(mimeType: String)
}

public class MemoryCacheProvider {
	public var expectedDataLength: Int64 = 0
	internal let cacheData = NSMutableData()
	public var contentMimeType: String?
	public let uid: String
	
	public init(uid: String, contentMimeType: String? = nil) {
		self.uid = uid
		self.contentMimeType = contentMimeType
	}
}

extension MemoryCacheProvider : CacheProvider {
	/// Set content MIME type. 
	///Only if now contentMimeType property is nil
	public func setContentMimeType(mimeType: String) {
		if contentMimeType == nil {
			contentMimeType = mimeType
		}
	}
	
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
		return saveData(NSFileManager.temporaryDirectory, fileExtension: fileExtension)
	}
	
	public func saveData() -> NSURL? {
		return saveData(nil)
	}
	
	public func saveData(destinationDirectory: NSURL) -> NSURL? {
		return saveData(destinationDirectory, fileExtension: nil)
	}
	
	public func saveData(destinationDirectory: NSURL, fileExtension: String?) -> NSURL? {
		let path = destinationDirectory.URLByAppendingPathComponent("\(NSUUID().UUIDString).\(fileExtension ?? ContentTypeDefinition.getFileExtensionFromMime(contentMimeType ?? "") ?? "dat")")
		print("save data length: \(cacheData.length) path: \(path)")
		if cacheData.writeToURL(path, atomically: true) { return path }
		print("something goes wrong while saving file")
		return nil
	}
}