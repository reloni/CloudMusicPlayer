//
//  LocalStorage.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 05.04.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import RxSwift

public struct StorageSize {
	let temporary: UInt64
	let tempStorage: UInt64
	let permanentStorage: UInt64
}

public protocol LocalStorageType {
	func createCacheProvider(uid: String, targetMimeType: String?) -> CacheProvider
	/// Directory for temp storage.
	/// Data may be deleted from this directory if it's size exceeds allowable size (set by tempStorageDiskSpace)
	func saveToTempStorage(provider: CacheProvider) -> NSURL?
	func saveToPermanentStorage(provider: CacheProvider) -> NSURL?
	func getFromStorage(uid: String) -> NSURL?
	var temporaryDirectory: NSURL { get }
	var tempStorageDirectory: NSURL { get }
	func saveToTemporaryFolder(provider: CacheProvider) -> NSURL?
	var permanentStorageDirectory: NSURL { get }
	var tempStorageDiskSpace: UInt { get }
	func calculateSize() -> Observable<StorageSize>
}

public class LocalNsUserDefaultsStorage {
	internal static let tempFileStorageId = "CMP_TempFileStorageDictionary"
	internal static let permanentFileStorageId = "CMP_PermanentFileStorageDictionary"
	
	internal var tempStorageDictionary = [String: String]()
	internal var permanentStorageDictionary = [String: String]()
	internal let saveData: Bool
	internal let userDefaults: NSUserDefaultsProtocol
	public let tempStorageDiskSpace: UInt = 0
	
	public let temporaryDirectory: NSURL
	public let tempStorageDirectory: NSURL
	public let permanentStorageDirectory: NSURL
	public init(persistInformationAboutSavedFiles: Bool = false, userDefaults: NSUserDefaultsProtocol = NSUserDefaults.standardUserDefaults()) {
		self.userDefaults = userDefaults

		temporaryDirectory = NSFileManager.getOrCreateSubDirectory(NSFileManager.temporaryDirectory, subDirName: "LocalStorageTemp") ??
			NSFileManager.temporaryDirectory
		
		tempStorageDirectory = NSFileManager.getOrCreateSubDirectory(NSFileManager.documentsDirectory, subDirName: "TempStorage") ??
			NSFileManager.documentsDirectory
		permanentStorageDirectory = NSFileManager.getOrCreateSubDirectory(NSFileManager.documentsDirectory, subDirName: "PermanentStorage") ??
			NSFileManager.documentsDirectory
		
		self.saveData = persistInformationAboutSavedFiles
		if saveData {
			if let loadedData = userDefaults.loadRawData(LocalNsUserDefaultsStorage.tempFileStorageId) as? [String: String] {
				tempStorageDictionary = loadedData
			}
			
			if let loadedData = userDefaults.loadRawData(LocalNsUserDefaultsStorage.permanentFileStorageId) as? [String: String] {
				permanentStorageDictionary = loadedData
			}
		}
	}
}

extension LocalNsUserDefaultsStorage : LocalStorageType {
	internal func saveTo(destination: NSURL, provider: CacheProvider) -> NSURL? {
		return provider.saveData(destination,
		                                   fileExtension: ContentTypeDefinition.getFileExtensionFromMime(provider.contentMimeType ?? ""))
	}
	
	public func createCacheProvider(uid: String, targetMimeType: String?) -> CacheProvider {
		return MemoryCacheProvider(uid: uid, contentMimeType: targetMimeType)
	}
	
	public func saveToTempStorage(provider: CacheProvider) -> NSURL? {
		if let file = saveTo(tempStorageDirectory, provider: provider), fileName = file.lastPathComponent {
			tempStorageDictionary[provider.uid] = fileName
			
			if saveData {
				userDefaults.saveData(tempStorageDictionary, forKey: LocalNsUserDefaultsStorage.tempFileStorageId)
			}
			
			return file
		}
		
		return nil
	}
	
	public func saveToPermanentStorage(provider: CacheProvider) -> NSURL? {
		if let file = saveTo(permanentStorageDirectory, provider: provider), fileName = file.lastPathComponent {
			permanentStorageDictionary[provider.uid] = fileName
			
			if saveData {
				userDefaults.saveData(permanentStorageDictionary, forKey: LocalNsUserDefaultsStorage.permanentFileStorageId)
			}
			
			return file
		}
		
		return nil
	}
	
	public func saveToTemporaryFolder(provider: CacheProvider) -> NSURL? {
		return saveTo(temporaryDirectory, provider: provider)
	}
	
	public func getFromStorage(uid: String) -> NSURL? {
		if let fileName = tempStorageDictionary[uid], path = tempStorageDirectory.URLByAppendingPathComponent(fileName, isDirectory: false).path {
			if NSFileManager.fileExistsAtPath(path, isDirectory: false) {
				return NSURL(fileURLWithPath: path)
			} else {
				tempStorageDictionary[uid] = nil
			}
		}
		
		if let fileName = permanentStorageDictionary[uid], path = permanentStorageDirectory.URLByAppendingPathComponent(fileName, isDirectory: false).path {
			if NSFileManager.fileExistsAtPath(path, isDirectory: false) {
				return NSURL(fileURLWithPath: path)
			} else {
				permanentStorageDictionary[uid] = nil
			}
		}
		
		return nil
	}
	
	public func calculateSize() -> Observable<StorageSize> {
		return calculateSize(NSFileManager.defaultManager())
	}
	
	internal func calculateSize(fileManager: NSFileManagerType) -> Observable<StorageSize> {
		return Observable.create { [unowned self] observer in
			observer.onNext(StorageSize(temporary: fileManager.getDirectorySize(self.temporaryDirectory, recursive: true),
				tempStorage: fileManager.getDirectorySize(self.tempStorageDirectory, recursive: true),
				permanentStorage: fileManager.getDirectorySize(self.permanentStorageDirectory, recursive: true)))
			observer.onCompleted()
			
			return NopDisposable.instance
		}
	}
}