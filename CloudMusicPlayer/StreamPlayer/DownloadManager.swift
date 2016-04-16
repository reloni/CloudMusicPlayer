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
	func createDownloadObservable(identifier: StreamResourceIdentifier, checkInPendingTasks: Bool) -> Observable<StreamTaskEvents>
	func createDownloadTask(identifier: StreamResourceIdentifier, checkInPendingTasks: Bool) -> StreamDataTaskProtocol?
	var saveData: Bool { get }
	var fileStorage: LocalStorageType { get }
}

public enum DownloadManagerError : Int {
	case UnsupportedUrlSchemeIrFileNotExists = 1
}

public class DownloadManager {
	private static let errorDomain = "DownloadManager"
	
	internal var pendingTasks = [String: StreamDataTaskProtocol]()
	
	public let saveData: Bool
	public let fileStorage: LocalStorageType
	internal let httpUtilities: HttpUtilitiesProtocol
	internal let queue = dispatch_queue_create("com.cloudmusicplayer.downloadmanager.serialqueue", DISPATCH_QUEUE_SERIAL)
	
	public init(saveData: Bool = false, fileStorage: LocalStorageType = LocalNsUserDefaultsStorage(), httpUtilities: HttpUtilitiesProtocol = HttpUtilities()) {
		self.saveData = saveData
		self.fileStorage = fileStorage
		self.httpUtilities = httpUtilities
	}
	
	internal func saveData(cacheProvider: CacheProvider?) -> NSURL? {
		if let cacheProvider = cacheProvider where saveData {
			return fileStorage.saveToTempStorage(cacheProvider)
		}
		
		return nil
	}
}

extension DownloadManager : DownloadManagerType {
	public func createDownloadTask(identifier: StreamResourceIdentifier, checkInPendingTasks: Bool) -> StreamDataTaskProtocol? {
		var result: StreamDataTaskProtocol?
		dispatch_sync(queue) {
			result = self.createDownloadTaskUnsafe(identifier, checkInPendingTasks: checkInPendingTasks)
		}
		return result
	}
		
	internal func createDownloadTaskUnsafe(identifier: StreamResourceIdentifier, checkInPendingTasks: Bool) -> StreamDataTaskProtocol? {
		if checkInPendingTasks {
			if let runningTask = pendingTasks[identifier.streamResourceUid] { return runningTask }
		}
		
		if let file = fileStorage.getFromStorage(identifier.streamResourceUid), path = file.path {
			print("Find in storage: \(identifier.streamResourceUid)")
			let task = LocalFileStreamDataTask(uid: identifier.streamResourceUid, filePath: path, provider: fileStorage.createCacheProvider(identifier.streamResourceUid,
				targetMimeType: identifier.streamResourceContentType?.definition.MIME))
			if checkInPendingTasks {
				pendingTasks[identifier.streamResourceUid] = task
			}
			return task
		}
		
		if let path = identifier.streamResourceUrl where identifier.streamResourceType == .LocalResource {
			let task = LocalFileStreamDataTask(uid: identifier.streamResourceUid, filePath: path, provider: fileStorage.createCacheProvider(identifier.streamResourceUid,
				targetMimeType: identifier.streamResourceContentType?.definition.MIME))
			if checkInPendingTasks {
				pendingTasks[identifier.streamResourceUid] = task
			}
			return task
		}
		
		guard identifier.streamResourceType == .HttpResource || identifier.streamResourceType == .HttpsResource else { return nil }
		
		guard let url = identifier.streamResourceUrl,
			urlRequest = httpUtilities.createUrlRequest(url, parameters: nil, headers: (identifier as? StreamHttpResourceIdentifier)?.streamHttpHeaders) else {
				return nil
		}
		
		let task = httpUtilities.createStreamDataTask(identifier.streamResourceUid, request: urlRequest,
		                                          sessionConfiguration: NSURLSession.defaultConfig,
		                                          cacheProvider: fileStorage.createCacheProvider(identifier.streamResourceUid,
																								targetMimeType: identifier.streamResourceContentType?.definition.MIME))
		if checkInPendingTasks {
			pendingTasks[identifier.streamResourceUid] = task
		}
		return task
	}
	
	public func createDownloadObservable(identifier: StreamResourceIdentifier, checkInPendingTasks: Bool) -> Observable<StreamTaskEvents> {
		return Observable<StreamTaskEvents>.create { [weak self] observer in
			guard let task = self?.createDownloadTask(identifier, checkInPendingTasks: checkInPendingTasks) else {
				let	message = "Unable to download data"
				let	code = DownloadManagerError.UnsupportedUrlSchemeIrFileNotExists.rawValue
				let error = NSError(domain: DownloadManager.errorDomain, code: code, userInfo: [NSLocalizedDescriptionKey: message,
					"Url": identifier.streamResourceUrl ?? "", "Uid": identifier.streamResourceUid])
				observer.onNext(StreamTaskEvents.Error(error)); observer.onCompleted(); return NopDisposable.instance
			}
			
			let disposable = task.taskProgress.bindNext { result in
				observer.onNext(result)
				
				if case .Success(let provider) = result {
					self?.saveData(provider)
					if checkInPendingTasks {
						self?.pendingTasks[identifier.streamResourceUid] = nil
					}
					observer.onCompleted()
				} else if case .Error = result {
					if checkInPendingTasks {
						self?.pendingTasks[identifier.streamResourceUid] = nil
					}
					observer.onCompleted()
				}
			}
			
			task.resume()
			
			return AnonymousDisposable {
				print("Dispose download task")
				task.cancel()
				disposable.dispose()
				if checkInPendingTasks {
					self?.pendingTasks[identifier.streamResourceUid] = nil
				}
			}
		}
	}
}