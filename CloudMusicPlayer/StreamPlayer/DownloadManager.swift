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
	func createDownloadObservable(identifier: StreamResourceIdentifier, priority: PendingTaskPriority) -> Observable<StreamTaskEvents>
	var saveData: Bool { get }
	var fileStorage: LocalStorageType { get }
}

public enum DownloadManagerError : Int {
	case UnsupportedUrlSchemeOrFileNotExists = 1
}

public enum PendingTaskPriority: Int {
	case Low = 0
	case Normal = 1
	case High = 2
}

public class PendingTask {
	internal let task: StreamDataTaskProtocol
	public internal(set) var priority: PendingTaskPriority
	public internal(set) var taskDependenciesCount: UInt = 1
	public init(task: StreamDataTaskProtocol, priority: PendingTaskPriority = .Normal) {
		self.task = task
		self.priority = priority
	}
}

public class DownloadManager {
	private static let errorDomain = "DownloadManager"
	
	internal let serialScheduler: SerialDispatchQueueScheduler = SerialDispatchQueueScheduler(globalConcurrentQueueQOS: DispatchQueueSchedulerQOS.Utility)
	internal var pendingTasks = [String: PendingTask]()
	internal let simultaneousTasksCount: UInt
	internal let runningTaskCheckTimeout: Double
	
	public let saveData: Bool
	public let fileStorage: LocalStorageType
	internal let httpUtilities: HttpUtilitiesProtocol
	internal let queue = dispatch_queue_create("com.cloudmusicplayer.downloadmanager.serialqueue", DISPATCH_QUEUE_SERIAL)
	
	internal init(saveData: Bool = false, fileStorage: LocalStorageType = LocalNsUserDefaultsStorage(), httpUtilities: HttpUtilitiesProtocol = HttpUtilities(),
	            simultaneousTasksCount: UInt, runningTaskCheckTimeout: Double) {
		self.saveData = saveData
		self.fileStorage = fileStorage
		self.httpUtilities = httpUtilities
		self.simultaneousTasksCount = simultaneousTasksCount == 0 ? 1 : simultaneousTasksCount
		self.runningTaskCheckTimeout = runningTaskCheckTimeout <= 0.0 ? 1.0 : runningTaskCheckTimeout
	}
	
	public convenience init(saveData: Bool = false, fileStorage: LocalStorageType = LocalNsUserDefaultsStorage(), httpUtilities: HttpUtilitiesProtocol = HttpUtilities()) {
		self.init(saveData: saveData, fileStorage: fileStorage, httpUtilities: httpUtilities, simultaneousTasksCount: 1, runningTaskCheckTimeout: 5)
	}
	
	internal func saveData(cacheProvider: CacheProvider?) -> NSURL? {
		if let cacheProvider = cacheProvider where saveData {
			return fileStorage.saveToTempStorage(cacheProvider)
		}
		
		return nil
	}
	
	internal func removePendingTaskSync(uid: String, force: Bool = false) {
		dispatch_sync(queue) {
			self.removePendingTaskSync(uid, force: force)
		}
	}
	
	internal func removePendingTaskUnsafe(uid: String, force: Bool = false) {
		guard let pendingTask = self.pendingTasks[uid] else {
			self.pendingTasks[uid] = nil
			return
		}
		
		pendingTask.taskDependenciesCount -= 1
		if pendingTask.taskDependenciesCount <= 0 || force {
			pendingTask.task.cancel()
			self.pendingTasks[uid] = nil
		}
	}
	
	internal func createDownloadTaskUnsafe(identifier: StreamResourceIdentifier, priority: PendingTaskPriority) -> StreamDataTaskProtocol? {
		if let runningTask = pendingTasks[identifier.streamResourceUid] {
			runningTask.taskDependenciesCount += 1
			if runningTask.priority.rawValue < priority.rawValue {
				runningTask.priority = priority
			}
			return runningTask.task
		}

		if let file = fileStorage.getFromStorage(identifier.streamResourceUid), path = file.path {
			let task = LocalFileStreamDataTask(uid: identifier.streamResourceUid, filePath: path, provider: fileStorage.createCacheProvider(identifier.streamResourceUid,
				targetMimeType: identifier.streamResourceContentType?.definition.MIME))
			if let task = task {
				pendingTasks[identifier.streamResourceUid] = PendingTask(task: task, priority: priority)
				return task
			}
			return task
		}
		
		let resourceType = identifier.streamResourceType
		if let path = identifier.streamResourceUrl where identifier.streamResourceType == .LocalResource {
			let task = LocalFileStreamDataTask(uid: identifier.streamResourceUid, filePath: path, provider: fileStorage.createCacheProvider(identifier.streamResourceUid,
				targetMimeType: identifier.streamResourceContentType?.definition.MIME))
			if let task = task {
				pendingTasks[identifier.streamResourceUid] = PendingTask(task: task, priority: priority)
				return task
			} else {
				return nil
			}
		}
		
		guard resourceType == .HttpResource || resourceType == .HttpsResource else { print("not http or https!!"); return nil }
		
		guard let url = identifier.streamResourceUrl,
			urlRequest = httpUtilities.createUrlRequest(url, parameters: nil, headers: (identifier as? StreamHttpResourceIdentifier)?.streamHttpHeaders) else {
				return nil
		}
		
		let task = httpUtilities.createStreamDataTask(identifier.streamResourceUid, request: urlRequest,
		                                              sessionConfiguration: NSURLSession.defaultConfig,
		                                              cacheProvider: fileStorage.createCacheProvider(identifier.streamResourceUid,
																										targetMimeType: identifier.streamResourceContentType?.definition.MIME))

		pendingTasks[identifier.streamResourceUid] = PendingTask(task: task, priority: priority)
		
		return task
	}
	
	public func createDownloadTaskSync(identifier: StreamResourceIdentifier, priority: PendingTaskPriority) -> StreamDataTaskProtocol? {
		var result: StreamDataTaskProtocol?
		dispatch_sync(queue) {
			result = self.createDownloadTaskUnsafe(identifier, priority: priority)
		}
		return result
	}
	
	internal func monitorTask(identifier: StreamResourceIdentifier,
	                          monitoringInterval: Observable<Int>) -> Observable<Void> {
		return Observable<Void>.create { [weak self] observer in
			guard let object = self, pendingTask = object.pendingTasks[identifier.streamResourceUid] else { observer.onCompleted(); return NopDisposable.instance }
			
			if (object.pendingTasks.filter { $0.1.task.resumed &&
				$0.1.priority.rawValue >= pendingTask.priority.rawValue }.count < Int(object.simultaneousTasksCount)) {
				dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {	pendingTask.task.resume() }
				observer.onCompleted()
				return NopDisposable.instance
			}
			
			return monitoringInterval.bindNext { _ in
				guard !pendingTask.task.resumed else { return }
				
				if (object.pendingTasks.filter { $0.1.task.resumed &&
					$0.1.priority.rawValue >= pendingTask.priority.rawValue }.count < Int(object.simultaneousTasksCount)) {
					
					pendingTask.task.resume()
					observer.onCompleted()
				}
			}
		}
	}
}

extension DownloadManager : DownloadManagerType {
	public func createDownloadObservable(identifier: StreamResourceIdentifier, priority: PendingTaskPriority) -> Observable<StreamTaskEvents> {
		return Observable<StreamTaskEvents>.create { [weak self] observer in
			var result: Disposable?
			
			guard let object = self else { observer.onCompleted(); return NopDisposable.instance }

			dispatch_sync(object.queue) {
				guard let task = object.createDownloadTaskUnsafe(identifier, priority: priority) else {
					let	message = "Unable to download data"
					let	code = DownloadManagerError.UnsupportedUrlSchemeOrFileNotExists.rawValue
					let error = NSError(domain: DownloadManager.errorDomain, code: code, userInfo: [NSLocalizedDescriptionKey: message,
						"Url": identifier.streamResourceUrl ?? "", "Uid": identifier.streamResourceUid])
					observer.onError(error); result = NopDisposable.instance; return;
				}
				
				let disposable = task.taskProgress.observeOn(object.serialScheduler).doOnError {
					self?.removePendingTaskUnsafe(identifier.streamResourceUid, force: true); observer.onError($0)
					}.doOnCompleted { observer.onCompleted() }.bindNext { result in
						if case .Success(let provider) = result {
							object.saveData(provider)
							object.removePendingTaskUnsafe(identifier.streamResourceUid, force: true)
							observer.onNext(result)
							//observer.onCompleted()
						} else {
							observer.onNext(result)
						}
				}
				
				let monitoring = object.monitorTask(identifier, monitoringInterval: Observable<Int>.interval(object.runningTaskCheckTimeout,
					scheduler: object.serialScheduler)).subscribe()
				
				result = AnonymousDisposable {
					monitoring.dispose()
					disposable.dispose()
					self?.removePendingTaskUnsafe(identifier.streamResourceUid)
				}
			}
			
			return result!
		}
	}
}