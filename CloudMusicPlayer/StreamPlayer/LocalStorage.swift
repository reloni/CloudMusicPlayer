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

public enum CacheState {
	case inPermanentStorage
	case inTempStorage
	case notExisted
}

public enum StorageType {
	case temp
	case permanent
}

public protocol LocalStorageType {
	var itemStateChanged: Observable<(uid: String, from: CacheState, to: CacheState)> { get }
	var storageCleared: Observable<StorageType> { get }
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
	func getItemState(uid: String) -> CacheState
	func deleteItem(uid: String)
	func moveToPermanentStorage(uid: String)
	func clearTempStorage()
	func clearPermanentStorage()
	func clearTemporaryDirectory()
	func clearStorage()
}

public class LocalNsUserDefaultsStorage {
	internal static let tempFileStorageId = "CMP_TempFileStorageDictionary"
	internal static let permanentFileStorageId = "CMP_PermanentFileStorageDictionary"
	
	internal let itemStateChangedSubject = PublishSubject<(uid: String, from: CacheState, to: CacheState)>()
	internal let storageClearedSubject = PublishSubject<StorageType>()
	internal var tempStorageDictionary = [String: String]()
	internal var permanentStorageDictionary = [String: String]()
	internal let saveData: Bool
	internal let userDefaults: NSUserDefaultsProtocol
	public let tempStorageDiskSpace: UInt = 0
	
	public let temporaryDirectory: NSURL
	public let tempStorageDirectory: NSURL
	public let permanentStorageDirectory: NSURL
	
	internal init(tempStorageDirectory: NSURL, permanentStorageDirectory: NSURL, temporaryDirectory: NSURL,
	              persistInformationAboutSavedFiles: Bool = false, userDefaults: NSUserDefaultsProtocol = NSUserDefaults.standardUserDefaults()) {
		
		self.userDefaults = userDefaults
		self.tempStorageDirectory = tempStorageDirectory
		self.permanentStorageDirectory = permanentStorageDirectory
		self.temporaryDirectory = temporaryDirectory
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
	
	public convenience init(persistInformationAboutSavedFiles: Bool = false, userDefaults: NSUserDefaultsProtocol = NSUserDefaults.standardUserDefaults()) {
		let temporaryDir = NSFileManager.getOrCreateSubDirectory(NSFileManager.temporaryDirectory, subDirName: "LocalStorageTemp") ??
			NSFileManager.temporaryDirectory
		
		let tempStorageDir = NSFileManager.getOrCreateSubDirectory(NSFileManager.documentsDirectory, subDirName: "TempStorage") ??
			NSFileManager.documentsDirectory
		let permanentStorageDir = NSFileManager.getOrCreateSubDirectory(NSFileManager.documentsDirectory, subDirName: "PermanentStorage") ??
			NSFileManager.documentsDirectory
		
		self.init(tempStorageDirectory: tempStorageDir, permanentStorageDirectory: permanentStorageDir, temporaryDirectory: temporaryDir,
		          persistInformationAboutSavedFiles: persistInformationAboutSavedFiles, userDefaults: userDefaults)
	}
}

extension LocalNsUserDefaultsStorage : LocalStorageType {
	public var storageCleared: Observable<StorageType> {
		return storageClearedSubject.observeOn(ConcurrentDispatchQueueScheduler(globalConcurrentQueueQOS: DispatchQueueSchedulerQOS.Utility))
	}
	
	public var itemStateChanged: Observable<(uid: String, from: CacheState, to: CacheState)> {
		return itemStateChangedSubject.observeOn(ConcurrentDispatchQueueScheduler(globalConcurrentQueueQOS: DispatchQueueSchedulerQOS.Utility))
	}
	
	public func getItemState(uid: String) -> CacheState {
		if tempStorageDictionary.keys.contains(uid) {
			return .inTempStorage
		} else if permanentStorageDictionary.keys.contains(uid) {
			return .inPermanentStorage
		} else {
			return .notExisted
		}
	}
	
	public func deleteItem(uid: String) {
		let currentState = getItemState(uid)
		
		if let url = getFromStorage(uid) {
			url.deleteFile()
			
			if currentState == .inTempStorage {
				tempStorageDictionary[uid] = nil
			} else {
				permanentStorageDictionary[uid] = nil
			}
			
			itemStateChangedSubject.onNext((uid: uid, from: currentState, to: CacheState.notExisted))
		}
	}
	
	public func moveToPermanentStorage(uid: String) {
		guard let url = getFromStorage(uid), fileName = url.lastPathComponent where getItemState(uid) == .inTempStorage else { return }
		
		do {
			try NSFileManager.defaultManager().moveItemAtURL(url, toURL: permanentStorageDirectory.URLByAppendingPathComponent(fileName))
			moveFileInformationToPermanentDictionary(uid)
			itemStateChangedSubject.onNext((uid: uid, from: CacheState.inTempStorage, to: CacheState.inPermanentStorage))
		} catch let error as NSError {
			NSLog("Error while moving to permanent storage: %@", error.localizedDescription)
		}
	}
	
	internal func saveTo(destination: NSURL, provider: CacheProvider) -> NSURL? {
		return provider.saveData(destination,
		                                   fileExtension: ContentTypeDefinition.getFileExtensionFromMime(provider.contentMimeType ?? ""))
	}
	
	public func createCacheProvider(uid: String, targetMimeType: String?) -> CacheProvider {
		return MemoryCacheProvider(uid: uid, contentMimeType: targetMimeType)
	}
	
	public func saveToTempStorage(provider: CacheProvider) -> NSURL? {
		let currentState = getItemState(provider.uid)
		
		if let file = saveTo(tempStorageDirectory, provider: provider), fileName = file.lastPathComponent {
			tempStorageDictionary[provider.uid] = fileName
			itemStateChangedSubject.onNext((uid: provider.uid, from: currentState, to: CacheState.inTempStorage))
			
			if saveData {
				userDefaults.saveData(tempStorageDictionary, forKey: LocalNsUserDefaultsStorage.tempFileStorageId)
			}
			
			return file
		}
		
		return nil
	}
	
	public func saveToPermanentStorage(provider: CacheProvider) -> NSURL? {
		let currentState = getItemState(provider.uid)
		
		if let file = saveTo(permanentStorageDirectory, provider: provider), fileName = file.lastPathComponent {
			permanentStorageDictionary[provider.uid] = fileName
			itemStateChangedSubject.onNext((uid: provider.uid, from: currentState, to: CacheState.inPermanentStorage))

			if saveData {
				userDefaults.saveData(permanentStorageDictionary, forKey: LocalNsUserDefaultsStorage.permanentFileStorageId)
			}
			
			return file
		}
		
		return nil
	}
	
	internal func moveFileInformationToPermanentDictionary(uid: String) {
		if let path = tempStorageDictionary[uid] {
			permanentStorageDictionary[uid] = path
		}
		tempStorageDictionary[uid] = nil
		
		userDefaults.saveData(tempStorageDictionary, forKey: LocalNsUserDefaultsStorage.tempFileStorageId)
		userDefaults.saveData(permanentStorageDictionary, forKey: LocalNsUserDefaultsStorage.permanentFileStorageId)
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
	
	public func clearTempStorage() {
		clearDirectory(tempStorageDirectory)
		tempStorageDictionary.removeAll()
		if saveData {
			userDefaults.saveData(tempStorageDictionary, forKey: LocalNsUserDefaultsStorage.tempFileStorageId)
		}
		storageClearedSubject.onNext(.temp)
	}
	
	public func clearPermanentStorage() {
		clearDirectory(permanentStorageDirectory)
		permanentStorageDictionary.removeAll()
		if saveData {
			userDefaults.saveData(permanentStorageDictionary, forKey: LocalNsUserDefaultsStorage.permanentFileStorageId)
		}
		storageClearedSubject.onNext(.permanent)
	}
	
	public func clearTemporaryDirectory() {
		clearDirectory(temporaryDirectory)
	}
	
	public func clearStorage() {
		clearTemporaryDirectory()
		clearPermanentStorage()
		clearTempStorage()
	}
	
	internal func clearDirectory(directory: NSURL) {
		guard let contents = try? NSFileManager.defaultManager()
			.contentsOfDirectoryAtURL(directory, includingPropertiesForKeys: nil, options: NSDirectoryEnumerationOptions()) else {
			return
		}
		
		for c in contents {
			c.deleteFile()
		}
	}
}