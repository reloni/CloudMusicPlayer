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
	func createDownloadObservable(identifier: StreamResourceIdentifier, priority: PendingTaskPriority) -> Observable<StreamTaskResult>
	var saveData: Bool { get }
	var fileStorage: LocalStorageType { get }
}

public enum DownloadManagerErrors : CustomErrorType {
	case unsupportedUrlSchemeOrFileNotExists(url: String?, uid: String)
	
	public func errorDomain() -> String {
		return "DownloadManagerDomain"
	}
	
	public func errorCode() -> Int {
		switch self {
		case .unsupportedUrlSchemeOrFileNotExists: return 1
		}
	}
	
	public func errorDescription() -> String {
		return "Unable to download data"
	}
	
	public func userInfo() -> Dictionary<String, String> {
		switch self {
		case .unsupportedUrlSchemeOrFileNotExists(let url, let uid): return [NSLocalizedDescriptionKey: errorDescription(), "url": url ?? "", "uid": uid]
		}
	}
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
	
	internal func createDownloadTaskUnsafe(identifier: StreamResourceIdentifier, priority: PendingTaskPriority) -> Observable<StreamDataTaskProtocol?> {
		return Observable.create { [weak self] observer in
			guard let object = self else { observer.onCompleted(); return NopDisposable.instance }
			
			if let runningTask = object.pendingTasks[identifier.streamResourceUid] {
				runningTask.taskDependenciesCount += 1
				if runningTask.priority.rawValue < priority.rawValue {
					runningTask.priority = priority
				}
				//return Observable.just(runningTask.task)
				//return runningTask.task
				observer.onNext(runningTask.task)
				observer.onCompleted()
				return NopDisposable.instance
			}
			
			if let file = object.fileStorage.getFromStorage(identifier.streamResourceUid), path = file.path {
				let task = LocalFileStreamDataTask(uid: identifier.streamResourceUid, filePath: path, provider: object.fileStorage.createCacheProvider(identifier.streamResourceUid,
					targetMimeType: identifier.streamResourceContentType?.definition.MIME))
				if let task = task {
					object.pendingTasks[identifier.streamResourceUid] = PendingTask(task: task, priority: priority)
					//return task
					//return Observable.just(task)
					observer.onNext(task)
					observer.onCompleted()
					return NopDisposable.instance
				}
				
				observer.onNext(task)
				observer.onCompleted()
				return NopDisposable.instance
				//return Observable.empty()
				
				//return task
			}
			
			let disposable = Observable<Void>.combineLatest(identifier.streamResourceUrl,
			identifier.streamResourceType) { result in
				
				let resourceType = result.1
				let resourceUrl = result.0
				
				if resourceType == .LocalResource {
					let task = LocalFileStreamDataTask(uid: identifier.streamResourceUid, filePath: resourceUrl,
						provider: object.fileStorage.createCacheProvider(identifier.streamResourceUid,
							targetMimeType: identifier.streamResourceContentType?.definition.MIME))
					if let task = task {
						object.pendingTasks[identifier.streamResourceUid] = PendingTask(task: task, priority: priority)
						
						observer.onNext(task)
						return
					} else {
						observer.onNext(nil)
						return
					}
				}
				
				guard resourceType == .HttpResource || resourceType == .HttpsResource else { return }
				
				guard let urlRequest = object.httpUtilities.createUrlRequest(resourceUrl, parameters: nil, headers: (identifier as? StreamHttpResourceIdentifier)?.streamHttpHeaders) else {
					observer.onNext(nil)
					return
				}
				
				let task = object.httpUtilities.createStreamDataTask(identifier.streamResourceUid, request: urlRequest,
					sessionConfiguration: NSURLSession.defaultConfig,
					cacheProvider: object.fileStorage.createCacheProvider(identifier.streamResourceUid,
						targetMimeType: identifier.streamResourceContentType?.definition.MIME))
				
				object.pendingTasks[identifier.streamResourceUid] = PendingTask(task: task, priority: priority)
				observer.onNext(task)
				//observer.onCompleted()
			}.doOnCompleted { observer.onCompleted() }.subscribeOn(object.serialScheduler).subscribe()
			
			return AnonymousDisposable {
				disposable.dispose()
			}
			}.subscribeOn(serialScheduler)
		//
		//		let resourceType = identifier.streamResourceType
		//		let resourceUrl = identifier.streamResourceUrl
		//		if let path = resourceUrl where resourceType == .LocalResource {
		//			let task = LocalFileStreamDataTask(uid: identifier.streamResourceUid, filePath: path, provider: fileStorage.createCacheProvider(identifier.streamResourceUid,
		//				targetMimeType: identifier.streamResourceContentType?.definition.MIME))
		//			if let task = task {
		//				pendingTasks[identifier.streamResourceUid] = PendingTask(task: task, priority: priority)
		//				return task
		//			} else {
		//				return nil
		//			}
		//		}
		//
		//		guard resourceType == .HttpResource || resourceType == .HttpsResource else { return nil }
		//
		//		guard let url = resourceUrl,
		//			urlRequest = httpUtilities.createUrlRequest(url, parameters: nil, headers: (identifier as? StreamHttpResourceIdentifier)?.streamHttpHeaders) else {
		//				return nil
		//		}
		//
		//		let task = httpUtilities.createStreamDataTask(identifier.streamResourceUid, request: urlRequest,
		//		                                              sessionConfiguration: NSURLSession.defaultConfig,
		//		                                              cacheProvider: fileStorage.createCacheProvider(identifier.streamResourceUid,
		//																										targetMimeType: identifier.streamResourceContentType?.definition.MIME))
		//
		//		pendingTasks[identifier.streamResourceUid] = PendingTask(task: task, priority: priority)
		//
		//		return task
	}
	
	//	public func createDownloadTaskSync(identifier: StreamResourceIdentifier, priority: PendingTaskPriority) -> StreamDataTaskProtocol? {
	//		var result: StreamDataTaskProtocol?
	//		dispatch_sync(queue) {
	//			result = self.createDownloadTaskUnsafe(identifier, priority: priority)
	//		}
	//		return result
	//	}
	
	internal func monitorTask(identifier: StreamResourceIdentifier,
	                          monitoringInterval: Observable<Int>) -> Observable<Void> {
		return Observable<Void>.create { [weak self] observer in
			guard let object = self, pendingTask = object.pendingTasks[identifier.streamResourceUid] else { observer.onCompleted(); return NopDisposable.instance }
			
			if (object.pendingTasks.filter { $0.1.task.resumed &&
				$0.1.priority.rawValue >= pendingTask.priority.rawValue }.count < Int(object.simultaneousTasksCount)) {
				dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {	pendingTask.task.resume() }
				observer.onNext()
				observer.onCompleted()
				return NopDisposable.instance
			}
			
			return monitoringInterval.observeOn(object.serialScheduler).bindNext { _ in
				guard !pendingTask.task.resumed else { return }
				
				if (object.pendingTasks.filter { $0.1.task.resumed &&
					$0.1.priority.rawValue >= pendingTask.priority.rawValue }.count < Int(object.simultaneousTasksCount)) {
					pendingTask.task.resume()
					observer.onNext()
					observer.onCompleted()
				}
			}
		}
	}
}

extension DownloadManager : DownloadManagerType {
	public func createDownloadObservable(identifier: StreamResourceIdentifier, priority: PendingTaskPriority) -> Observable<StreamTaskResult> {
		//return Observable.empty()
		
		return Observable<StreamTaskResult>.create { [weak self] observer in
			guard let object = self else { observer.onCompleted(); return NopDisposable.instance }
			
			let disposable = object.createDownloadTaskUnsafe(identifier, priority: priority).flatMapLatest { result -> Observable<Void> in
				guard let task = result else {
					print("not url: \(identifier.streamResourceUid)")
					observer.onNext(DownloadManagerErrors.unsupportedUrlSchemeOrFileNotExists(url: "", uid: identifier.streamResourceUid).asResult())
					observer.onCompleted()
					return Observable.empty()
				}
				
				let streamTask = task.taskProgress.observeOn(object.serialScheduler).doOnError { error in
					object.removePendingTaskUnsafe(identifier.streamResourceUid, force: true); observer.onNext(Result.error(error)); observer.onCompleted()
					}.doOnNext { result in
						if case Result.success(let event) = result {
							if case .Success(let provider) = event.value {
								object.saveData(provider)
								object.removePendingTaskUnsafe(identifier.streamResourceUid, force: true)
								observer.onNext(result)
							} else {
								observer.onNext(result)
							}
						} else if case Result.error = result {
							self?.removePendingTaskUnsafe(identifier.streamResourceUid, force: true)
							observer.onNext(result)
						}
				}
				
				let monitoring = object.monitorTask(identifier, monitoringInterval: Observable<Int>.interval(object.runningTaskCheckTimeout,
					scheduler: object.serialScheduler))
				
				return Observable<Void>.combineLatest(streamTask, monitoring) { combineResult in
					
				}
				}.subscribeOn(object.serialScheduler).subscribe()
			
			return AnonymousDisposable {
				print("download observable dispose")
				disposable.dispose()
				self?.removePendingTaskUnsafe(identifier.streamResourceUid)
			}
			}.subscribeOn(serialScheduler)
		
		//		return Observable<StreamTaskResult>.create { [weak self] observer in
		//			//var result: Disposable?
		//
		//			guard let object = self else { observer.onCompleted(); return NopDisposable.instance }
		//
		//			let disposable = object.createDownloadTaskUnsafe(identifier, priority: priority).flatMapLatest { [weak self] result -> Observable<Void> in
		//				//guard let object = self else { return Observable.just() } //{ observer.onCompleted(); return NopDisposable.instance }
		//
		//				guard let task = result else {
		//					print("not url: \(identifier.streamResourceUid)")
		//					//return Observable.just(DownloadManagerErrors.unsupportedUrlSchemeOrFileNotExists(url: "", uid: identifier.streamResourceUid).asResult())
		//					observer.onNext(DownloadManagerErrors.unsupportedUrlSchemeOrFileNotExists(url: "", uid: identifier.streamResourceUid).asResult())
		//					observer.onCompleted()
		//					return Observable.empty()
		//				}
		//
		//				let a =  task.taskProgress.observeOn(object.serialScheduler).doOnError { error in
		//					self?.removePendingTaskUnsafe(identifier.streamResourceUid, force: true); //observer.onNext(Result.error(error));
		//					}.doOnNext { result in
		//						if case Result.success(let event) = result {
		//							if case .Success(let provider) = event.value {
		//								object.saveData(provider)
		//								object.removePendingTaskUnsafe(identifier.streamResourceUid, force: true)
		//								//observer.onNext(result)
		//							} else {
		//								//observer.onNext(result)
		//							}
		//						} else if case Result.error = result {
		//							self?.removePendingTaskUnsafe(identifier.streamResourceUid, force: true)
		//							//observer.onNext(result)
		//						}
		//				}
		//			}
		//		}
		//			dispatch_sync(object.queue) {
		//				guard let task = object.createDownloadTaskUnsafe(identifier, priority: priority) else {
		//					print("not url: \(identifier.streamResourceUid)")
		//					observer.onNext(DownloadManagerErrors.unsupportedUrlSchemeOrFileNotExists(url: identifier.streamResourceUrl ?? "", uid: identifier.streamResourceUid).asResult())
		//					result = NopDisposable.instance; return;
		//				}
		//
		//				let disposable = task.taskProgress.observeOn(object.serialScheduler).catchError { error in
		//					self?.removePendingTaskUnsafe(identifier.streamResourceUid, force: true); observer.onNext(Result.error(error));
		//					return Observable.empty()
		//					}.doOnCompleted { observer.onCompleted() }.bindNext { result in
		//						if case Result.success(let event) = result {
		//							if case .Success(let provider) = event.value {
		//								object.saveData(provider)
		//								object.removePendingTaskUnsafe(identifier.streamResourceUid, force: true)
		//								observer.onNext(result)
		//							} else {
		//								observer.onNext(result)
		//							}
		//						} else if case Result.error = result {
		//							self?.removePendingTaskUnsafe(identifier.streamResourceUid, force: true)
		//							observer.onNext(result)
		//						}
		//				}
		//
		//				let monitoring = object.monitorTask(identifier, monitoringInterval: Observable<Int>.interval(object.runningTaskCheckTimeout,
		//					scheduler: object.serialScheduler)).subscribe()
		//
		//				result = AnonymousDisposable {
		//					monitoring.dispose()
		//					disposable.dispose()
		//					self?.removePendingTaskUnsafe(identifier.streamResourceUid)
		//				}
		//			}
		
		//return result!
		
		
		
	}
}