//
//  DownloadManager.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 10.04.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import RxSwift

public protocol DownloadManagerType {
	func getUrlDownloadTask(identifier: StreamResourceIdentifier, checkInPendingTasks: Bool) -> Observable<StreamTaskEvents>
	func createDownloadTask(identifier: StreamResourceIdentifier, checkInPendingTasks: Bool) -> StreamDataTaskProtocol?
	var saveData: Bool { get }
	var fileStorage: LocalStorageType { get }
}

public class DownloadManager {
	private static var _instance: DownloadManagerType!
	private static var token: dispatch_once_t = 0
	
	internal var pendingTasks = [String: StreamDataTaskProtocol]()
	
	public let saveData: Bool
	public let fileStorage: LocalStorageType
	internal let httpUtilities: HttpUtilitiesProtocol
	
	internal static var instance: DownloadManagerType  {
		initWithInstance()
		return DownloadManager._instance
	}
	
	public static var isInitialized: Bool {
		return DownloadManager._instance != nil
	}
	
	internal static func initWithInstance(instance: DownloadManagerType? = nil) {
		dispatch_once(&token) {
			_instance = instance ?? DownloadManager()
		}
	}
	
	internal init(saveData: Bool = false, fileStorage: LocalStorageType = LocalNsUserDefaultsStorage(), httpUtilities: HttpUtilitiesProtocol = HttpUtilities()) {
		self.saveData = saveData
		self.fileStorage = fileStorage
		self.httpUtilities = httpUtilities
	}
	
	internal func saveData(cacheProvider: CacheProvider?) {
		if let cacheProvider = cacheProvider where saveData {
			fileStorage.saveToTempStorage(cacheProvider)
		}
	}
}

extension DownloadManager : DownloadManagerType {
	public func createDownloadTask(identifier: StreamResourceIdentifier, checkInPendingTasks: Bool) -> StreamDataTaskProtocol? {
		if checkInPendingTasks {
			if let runningTask = pendingTasks[identifier.streamResourceUid] { return runningTask }
		}
		
		if let file = fileStorage.getFromStorage(identifier.streamResourceUid), path = file.path {
			print("Find in storage: \(identifier.streamResourceUid)")
			return LocalFileStreamDataTask(uid: identifier.streamResourceUid, filePath: path, provider: fileStorage.createCacheProvider(identifier.streamResourceUid,
				targetMimeType: identifier.streamResourceContentType?.definition.MIME))
		}
		
		if let path = identifier.streamResourceUrl where identifier.streamResourceType == .LocalResource {
			return LocalFileStreamDataTask(uid: identifier.streamResourceUid, filePath: path, provider: fileStorage.createCacheProvider(identifier.streamResourceUid,
				targetMimeType: identifier.streamResourceContentType?.definition.MIME))
		}
		
		guard identifier.streamResourceType == .HttpResource || identifier.streamResourceType == .HttpsResource else { return nil }
		
		guard let url = identifier.streamResourceUrl,
			urlRequest = httpUtilities.createUrlRequest(url, parameters: nil, headers: (identifier as? StreamHttpResourceIdentifier)?.streamHttpHeaders) else {
				return nil
		}
		
		return httpUtilities.createStreamDataTask(identifier.streamResourceUid, request: urlRequest,
		                                          sessionConfiguration: NSURLSession.defaultConfig,
		                                          cacheProvider: fileStorage.createCacheProvider(identifier.streamResourceUid,
																								targetMimeType: identifier.streamResourceContentType?.definition.MIME))
	}
	
	public func getUrlDownloadTask(identifier: StreamResourceIdentifier, checkInPendingTasks: Bool) -> Observable<StreamTaskEvents> {
		return Observable<StreamTaskEvents>.create { [unowned self] observer in
			guard let task = self.createDownloadTask(identifier, checkInPendingTasks: checkInPendingTasks) else {
				observer.onNext(StreamTaskEvents.Success(cache: nil)); observer.onCompleted(); return NopDisposable.instance
			}
			
			if checkInPendingTasks {
				self.pendingTasks[identifier.streamResourceUid] = task
			}
			
			let disposable = task.taskProgress.bindNext { result in
				observer.onNext(result)
				
				if case .Success(let provider) = result {
					self.saveData(provider)
					if checkInPendingTasks {
						self.pendingTasks[identifier.streamResourceUid] = nil
					}
					observer.onCompleted()
				} else if case .Error = result {
					if checkInPendingTasks {
						self.pendingTasks[identifier.streamResourceUid] = nil
					}
					observer.onCompleted()
				}
			}
			
			task.resume()
			
			return AnonymousDisposable {
				task.cancel()
				disposable.dispose()
				if checkInPendingTasks {
					self.pendingTasks[identifier.streamResourceUid] = nil
				}
			}
		}
	}
}