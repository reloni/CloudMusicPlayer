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
	func createDownloadObservable(identifier: StreamResourceIdentifier) -> Observable<StreamTaskEvents>
	var saveData: Bool { get }
	var fileStorage: LocalStorageType { get }
}

public enum DownloadManagerError : Int {
	case UnsupportedUrlSchemeIrFileNotExists = 1
}

public class PendingTask {
	internal let task: StreamDataTaskProtocol
	public internal(set) var taskDependenciesCount: UInt = 1
	public init(task: StreamDataTaskProtocol) {
		self.task = task
	}
}

public class DownloadManager {
	private static let errorDomain = "DownloadManager"
	
	internal var pendingTasks = [String: PendingTask]()
	
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
	
	internal func removePendingTaskSync(uid: String, force: Bool = false) {
		dispatch_sync(queue) {
			guard let pendingTask = self.pendingTasks[uid] else {
				self.pendingTasks[uid] = nil
				return
			}
			
			pendingTask.taskDependenciesCount -= 1
			if pendingTask.taskDependenciesCount <= 0 || force {
				print("cancel pending task!!!!")
				pendingTask.task.cancel()
				self.pendingTasks[uid] = nil
			}
		}
		
		//print("Pending tasks: \(pendingTasks.count)")
	}
	
	internal func createDownloadTaskUnsafe(identifier: StreamResourceIdentifier) -> StreamDataTaskProtocol? {
		if let runningTask = pendingTasks[identifier.streamResourceUid] {
			print("return running task: \(identifier.streamResourceUid)")
			runningTask.taskDependenciesCount += 1
			return runningTask.task
		}

		if let file = fileStorage.getFromStorage(identifier.streamResourceUid), path = file.path {
			print("Find in storage: \(identifier.streamResourceUid)")
			let task = LocalFileStreamDataTask(uid: identifier.streamResourceUid, filePath: path, provider: fileStorage.createCacheProvider(identifier.streamResourceUid,
				targetMimeType: identifier.streamResourceContentType?.definition.MIME))
			if let task = task {
				pendingTasks[identifier.streamResourceUid] = PendingTask(task: task)
				return task
			}
			return task
		}
		
		if let path = identifier.streamResourceUrl where identifier.streamResourceType == .LocalResource {
			let task = LocalFileStreamDataTask(uid: identifier.streamResourceUid, filePath: path, provider: fileStorage.createCacheProvider(identifier.streamResourceUid,
				targetMimeType: identifier.streamResourceContentType?.definition.MIME))
			if let task = task {
				pendingTasks[identifier.streamResourceUid] = PendingTask(task: task)
				return task
			} else {
				return nil
			}
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
		
		pendingTasks[identifier.streamResourceUid] = PendingTask(task: task)
		
		return task
	}
	
	public func createDownloadTaskSync(identifier: StreamResourceIdentifier) -> StreamDataTaskProtocol? {
		var result: StreamDataTaskProtocol?
		dispatch_sync(queue) {
			result = self.createDownloadTaskUnsafe(identifier)
		}
		return result
	}
}

extension DownloadManager : DownloadManagerType {
	public func createDownloadObservable(identifier: StreamResourceIdentifier) -> Observable<StreamTaskEvents> {
		return Observable<StreamTaskEvents>.create { [weak self] observer in
			guard let task = self?.createDownloadTaskSync(identifier) else {
				let	message = "Unable to download data"
				let	code = DownloadManagerError.UnsupportedUrlSchemeIrFileNotExists.rawValue
				let error = NSError(domain: DownloadManager.errorDomain, code: code, userInfo: [NSLocalizedDescriptionKey: message,
					"Url": identifier.streamResourceUrl ?? "", "Uid": identifier.streamResourceUid])
				observer.onNext(StreamTaskEvents.Error(error)); observer.onCompleted(); return NopDisposable.instance
			}
			
			let disposable = task.taskProgress.bindNext { result in
				if case .Success(let provider) = result {
					self?.saveData(provider)
					self?.removePendingTaskSync(identifier.streamResourceUid, force: true)
					observer.onNext(result)
					observer.onCompleted()
				} else if case .Error = result {
					self?.removePendingTaskSync(identifier.streamResourceUid, force: true)
					observer.onNext(result)
					observer.onCompleted()
				} else {
					observer.onNext(result)
				}
			}
			
			task.resume()
			
			return AnonymousDisposable {
				print("Dispose download task")
				disposable.dispose()
				self?.removePendingTaskSync(identifier.streamResourceUid)
			}
		}
	}
}