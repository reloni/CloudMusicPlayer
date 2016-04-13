//
//  LocalStorage.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 05.04.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation

public protocol LocalStorageType {
	func createCacheProvider(uid: String, targetMimeType: String?) -> CacheProvider
	func saveToTempStorage(provider: CacheProvider) -> NSURL?
	func saveToPermanentStorage(provider: CacheProvider) -> NSURL?
	func getFromStorage(uid: String) -> NSURL?
	var tempCacheDirectory: NSURL { get }
	var tempSaveStorageDirectory: NSURL { get }
	var permanentSaveStorageDirectory: NSURL { get }
}

public class LocalNsUserDefaultsStorage {
	internal static let tempFileStorageId = "CMP_TempFileStorageDictionary"
	internal static let permanentFileStorageId = "CMP_PermanentFileStorageDictionary"
	
	internal var tempSaveStorageDictionary = [String: String]()
	internal var permanentSaveStorageDictionary = [String: String]()
	internal let saveData: Bool
	//internal var permanentFileStorageDictionary = [String: NSURL]()
	
	public let tempCacheDirectory: NSURL
	public let tempSaveStorageDirectory: NSURL
	public let permanentSaveStorageDirectory: NSURL
	public init(loadData: Bool = false) {
		tempCacheDirectory = NSFileManager.getOrCreateSubDirectory(NSFileManager.temporaryDirectory, subDirName: "LocalStorageTemp") ??
			NSFileManager.temporaryDirectory
		tempSaveStorageDirectory = NSFileManager.getOrCreateSubDirectory(NSFileManager.documentsDirectory, subDirName: "TempStorage") ??
			NSFileManager.documentsDirectory
		permanentSaveStorageDirectory = NSFileManager.getOrCreateSubDirectory(NSFileManager.documentsDirectory, subDirName: "PermanentStorage") ??
			NSFileManager.documentsDirectory
		
		self.saveData = loadData
		if saveData {
			if let loadedData = NSUserDefaults.loadRawData(LocalNsUserDefaultsStorage.tempFileStorageId) as? [String: String] {
				tempSaveStorageDictionary = loadedData
			}
			
			if let loadedData = NSUserDefaults.loadRawData(LocalNsUserDefaultsStorage.permanentFileStorageId) as? [String: String] {
				permanentSaveStorageDictionary = loadedData
			}
		}
	}
}

extension LocalNsUserDefaultsStorage : LocalStorageType {
	internal func saveTo(destination: NSURL, provider: CacheProvider) -> NSURL? {
		guard let file = provider.saveData(destination,
		                                   fileExtension: ContentTypeDefinition.getFileExtensionFromMime(provider.contentMimeType ?? "")) else { return nil }
		
		return file
	}
	
	public func createCacheProvider(uid: String, targetMimeType: String?) -> CacheProvider {
		return MemoryCacheProvider(uid: uid, contentMimeType: targetMimeType)
	}
	
	public func saveToTempStorage(provider: CacheProvider) -> NSURL? {
		if let file = saveTo(tempSaveStorageDirectory, provider: provider), fileName = file.lastPathComponent {
			tempSaveStorageDictionary[provider.uid] = fileName
			
			if saveData {
				NSUserDefaults.saveData(tempSaveStorageDictionary, forKey: LocalNsUserDefaultsStorage.tempFileStorageId)
			}
			
			return file
		}
		
		return nil
	}
	
	public func saveToPermanentStorage(provider: CacheProvider) -> NSURL? {
		if let file = saveTo(permanentSaveStorageDirectory, provider: provider), fileName = file.lastPathComponent {
			permanentSaveStorageDictionary[provider.uid] = fileName
			
			if saveData {
				NSUserDefaults.saveData(permanentSaveStorageDictionary, forKey: LocalNsUserDefaultsStorage.permanentFileStorageId)
			}
			
			return file
		}
		
		return nil
	}
	
	public func getFromStorage(uid: String) -> NSURL? {
		if let fileName = tempSaveStorageDictionary[uid], path = tempSaveStorageDirectory.URLByAppendingPathComponent(fileName, isDirectory: false).path {
			if NSFileManager.fileExistsAtPath(path, isDirectory: false) {
				return NSURL(fileURLWithPath: path)
			} else {
				tempSaveStorageDictionary[uid] = nil
			}
		}
		
		if let fileName = permanentSaveStorageDictionary[uid], path = permanentSaveStorageDirectory.URLByAppendingPathComponent(fileName, isDirectory: false).path {
			if NSFileManager.fileExistsAtPath(path, isDirectory: false) {
				return NSURL(fileURLWithPath: path)
			} else {
				permanentSaveStorageDictionary[uid] = nil
			}
		}
		
		return nil
	}
}