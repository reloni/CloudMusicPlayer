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
	func getUrlDownloadTask(identifier: StreamResourceIdentifier) -> Observable<StreamTaskEvents>
	var saveData: Bool { get }
}

public class DownloadManager {
	private static var _instance: DownloadManagerType!
	private static var token: dispatch_once_t = 0
	
	internal var pendingTasks = [String: StreamDataTaskProtocol]()
	
	public let saveData: Bool
	internal let fileStorage: LocalStorageProtocol
	internal let httpUtilities: HttpUtilitiesProtocol
	
	internal static var instance: DownloadManagerType  {
		initWithInstance()
		return DownloadManager._instance
	}
	
	internal static func initWithInstance(instance: DownloadManagerType? = nil) {
		dispatch_once(&token) {
			_instance = instance ?? DownloadManager()
		}
	}
	
	internal init(saveData: Bool = false, fileStorage: LocalStorageProtocol = LocalStorage(), httpUtilities: HttpUtilitiesProtocol = HttpUtilities()) {
		self.saveData = saveData
		self.fileStorage = fileStorage
		self.httpUtilities = httpUtilities
	}
	
	internal func createDownloadTask(identifier: StreamResourceIdentifier) -> StreamDataTaskProtocol? {
		if let runningTask = pendingTasks[identifier.streamResourceUid] { return runningTask }
		
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
	
	internal func saveData(cacheProvider: CacheProvider?) {
		if let cacheProvider = cacheProvider where saveData {
			fileStorage.saveToTempStorage(cacheProvider)
		}
	}
}

extension DownloadManager : DownloadManagerType {
	public func getUrlDownloadTask(identifier: StreamResourceIdentifier) -> Observable<StreamTaskEvents> {
		return Observable<StreamTaskEvents>.create { [unowned self] observer in
			guard let task = self.createDownloadTask(identifier) else { observer.onCompleted(); return NopDisposable.instance }
			
			self.pendingTasks[identifier.streamResourceUid] = task
			
			let disposable = task.taskProgress.bindNext { result in
				observer.onNext(result)
				
				if case .Success(let provider) = result {
					self.saveData(provider)
					self.pendingTasks[identifier.streamResourceUid] = nil
					observer.onCompleted()
				} else if case .Error = result {
					self.pendingTasks[identifier.streamResourceUid] = nil
					observer.onCompleted()
				}
			}
			
			task.resume()
			
			return AnonymousDisposable {
				task.cancel()
				disposable.dispose()
				self.pendingTasks[identifier.streamResourceUid] = nil
			}
		}
	}
}