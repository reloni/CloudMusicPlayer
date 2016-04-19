//
//  NSFileManager.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 04.03.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation

public protocol NSFileManagerType {
	func isFileExistsAtPath(pathToFile: String) -> Bool
	func isDirectoryExistsAtPath(pathtoDir: String) -> Bool
	func getDirectorySize(directory: NSURL, recursive: Bool) -> UInt64
}

extension NSFileManager {
	public static func fileExistsAtPath(path: String, isDirectory: Bool = false) -> Bool {
		var isDir = ObjCBool(isDirectory)
		return NSFileManager.defaultManager().fileExistsAtPath(path, isDirectory: &isDir)
	}
	
	public static func getDirectory(directory: NSSearchPathDirectory) -> NSURL {
		return NSFileManager.defaultManager().URLsForDirectory(directory, inDomains: .UserDomainMask)[0]
	}
	
	public static var documentsDirectory: NSURL {
		return NSFileManager.getDirectory(.DocumentDirectory)
	}
	
	public static var temporaryDirectory: NSURL {
		return NSURL(fileURLWithPath: NSTemporaryDirectory())
	}
	
	public static func getOrCreateSubDirectory(directoryUrl: NSURL, subDirName: String) -> NSURL? {
		let newDir = directoryUrl.URLByAppendingPathComponent(subDirName)
		guard let path = newDir.path else { return nil }
		
		guard !NSFileManager.fileExistsAtPath(path, isDirectory: true) else { return newDir }
		
		do
		{
			try NSFileManager.defaultManager().createDirectoryAtPath(path, withIntermediateDirectories: false, attributes: nil)
			return newDir
		} catch {
			return nil
		}
	}
	
	public func getDirectorySize(directory: NSURL, recursive: Bool = false) -> UInt64 {
		var result: UInt64 = 0
		if fileOrDirectoryExistsAtPath(directory.path ?? "", isDirectory: true) {
			guard let contents = try? contentsOfDirectoryAtURL(directory, includingPropertiesForKeys: nil, options: .SkipsHiddenFiles) else {
				return result
			}
			
			for content in contents {
				if let path = content.path {
					// if file
					if isFileExistsAtPath(path) {
						if let attrs: NSDictionary = try? attributesOfItemAtPath(path) {
							result += attrs.fileSize()
						}
					} else if isDirectoryExistsAtPath(path) && recursive {
						// if directory
						result += getDirectorySize(content, recursive: recursive)
					}
				}
			}
		}
		return result
	}
}

extension NSFileManager: NSFileManagerType {
	public func isFileExistsAtPath(pathToFile: String) -> Bool {
		return fileOrDirectoryExistsAtPath(pathToFile, isDirectory: false)
	}
	
	public func isDirectoryExistsAtPath(pathtoDir: String) -> Bool {
		return fileOrDirectoryExistsAtPath(pathtoDir, isDirectory: true)
	}
	
	public func fileOrDirectoryExistsAtPath(path: String, isDirectory: Bool) -> Bool {
		var isDir = ObjCBool(isDirectory)
		if fileExistsAtPath(path, isDirectory: &isDir) && isDirectory == isDir.boolValue {
			return true
		}
		return false
	}
}