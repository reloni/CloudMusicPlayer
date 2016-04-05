//
//  LocalStorage.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 05.04.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation

public protocol LocalStorageProtocol {
	func createCacheProvider(uid: String) -> CacheProvider
	func saveToTempStorage(provider: CacheProvider) -> NSURL?
	func saveToPermanentStorage(provider: CacheProvider) -> NSURL?
	func getFromStorage(uid: String) -> NSURL?
	var tempCacheDirectory: NSURL { get }
	var tempSaveStorageDirectory: NSURL { get }
	var permanentSaveStorageDirectory: NSURL { get }
}

public class LocalStorage {
	internal var localFileStorage = [String: NSURL]()
	
	public let tempCacheDirectory: NSURL
	public let tempSaveStorageDirectory: NSURL
	public let permanentSaveStorageDirectory: NSURL
	public init() {
		tempCacheDirectory = NSFileManager.getOrCreateSubDirectory(NSFileManager.temporaryDirectory, subDirName: "LocalStorageTemp") ??
			NSFileManager.temporaryDirectory
		tempSaveStorageDirectory = NSFileManager.getOrCreateSubDirectory(NSFileManager.documentsDirectory, subDirName: "TempStorage") ??
			NSFileManager.documentsDirectory
		permanentSaveStorageDirectory = NSFileManager.getOrCreateSubDirectory(NSFileManager.documentsDirectory, subDirName: "PermanentStorage") ??
			NSFileManager.documentsDirectory	}
}

extension LocalStorage : LocalStorageProtocol {
	internal func saveTo(destination: NSURL, provider: CacheProvider) -> NSURL? {
		guard let file = provider.saveData(destination,
		                                   fileExtension: ContentTypeDefinition.getFileExtensionFromMime(provider.contentMimeType ?? "")) else { return nil }
		
		localFileStorage[provider.uid] = file
		return file
	}
	
	public func createCacheProvider(uid: String) -> CacheProvider {
		return MemoryCacheProvider(uid: uid)
	}
	
	public func saveToTempStorage(provider: CacheProvider) -> NSURL? {
		return saveTo(tempSaveStorageDirectory, provider: provider)
	}
	
	public func saveToPermanentStorage(provider: CacheProvider) -> NSURL? {
		return saveTo(permanentSaveStorageDirectory, provider: provider)
	}
	
	public func getFromStorage(uid: String) -> NSURL? {
		return localFileStorage[uid]
	}
}