//
//  HttpRequest.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 14.03.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import RxSwift
import SwiftyJSON

public enum HttpRequestResult {
	case success
	case successData(NSData)
	case error(ErrorType)
}

public protocol HttpClientProtocol {
	var httpUtilities: HttpUtilitiesProtocol { get }
	func loadJsonData(request: NSMutableURLRequestProtocol) -> Observable<Result<JSON>>
	func loadData(request: NSMutableURLRequestProtocol) -> Observable<HttpRequestResult>
	func loadStreamData(request: NSMutableURLRequestProtocol, cacheProvider: CacheProvider?) -> Observable<StreamTaskResult>
}

public class HttpClient {
	public let httpUtilities: HttpUtilitiesProtocol
	internal let scheduler = ConcurrentDispatchQueueScheduler(globalConcurrentQueueQOS: DispatchQueueSchedulerQOS.Utility)
	
	public init(httpUtilities: HttpUtilitiesProtocol = HttpUtilities()) {
		
		self.httpUtilities = httpUtilities
	}
}

extension HttpClient : HttpClientProtocol {
	public func loadJsonData(request: NSMutableURLRequestProtocol)
		-> Observable<Result<JSON>> {
			return Observable.create { [weak self] observer in
				guard let object = self else { observer.onCompleted(); return NopDisposable.instance }
				let task = object.loadData(request).bindNext { result in
					if case .successData(let data) = result {
						observer.onNext(Result.success(Box(value: JSON(data: data))))
					} else if case .error(let error) = result {
						observer.onNext(Result.error(error))
						observer.onCompleted()
					}
					
					observer.onCompleted()
				}
				
				return AnonymousDisposable {
					task.dispose()
				}
			}.shareReplay(0)
	}
	
	public func loadData(request: NSMutableURLRequestProtocol)
		-> Observable<HttpRequestResult> {
			return Observable.create { [weak self] observer in
				guard let object = self else { observer.onCompleted(); return NopDisposable.instance }
				
				let task = object.httpUtilities.createStreamDataTask(NSUUID().UUIDString,
					request: request, sessionConfiguration: NSURLSession.defaultConfig, cacheProvider: nil)
				
				let receivedData = NSMutableData()
				
				let disposable = task.taskProgress.catchError { error in
					observer.onNext(.error(error))
					observer.onCompleted()
					return Observable.empty()
					}.doOnCompleted { observer.onCompleted() }.bindNext { result in
						if case Result.success(let box) = result {
							if case StreamTaskEvents.ReceiveData(let data) = box.value {
								receivedData.appendData(data)
							} else if case StreamTaskEvents.Success = box.value {
								if receivedData.length > 0 {
									observer.onNext(.successData(receivedData))
								} else {
									observer.onNext(.success)
								}
							}
						} else if case Result.error(let error) = result {
							observer.onNext(.error(error))
						}
				}
				
				task.resume()
				
				return AnonymousDisposable {
					task.cancel()
					disposable.dispose()
				}
			}.observeOn(scheduler).shareReplay(0)
	}
	
	public func loadStreamData(request: NSMutableURLRequestProtocol, cacheProvider: CacheProvider?)
		-> Observable<StreamTaskResult> {
		return Observable.create { [weak self] observer in
			guard let object = self else { observer.onCompleted(); return NopDisposable.instance }
			
			let task = object.httpUtilities.createStreamDataTask(NSUUID().UUIDString, request: request, sessionConfiguration: NSURLSession.defaultConfig,
				cacheProvider: cacheProvider)
				
			let disposable = task.taskProgress.catchError { error in
				observer.onNext(Result.error(error))
				observer.onCompleted()
				return Observable.empty()
			}.bindNext { result in
				observer.onNext(result)
				
				if case Result.success(let box) = result, case .Success = box.value {
					observer.onCompleted()
				}
			}
			
			task.resume()
			
			return AnonymousDisposable {
				task.cancel()
				disposable.dispose()
			}
		}.observeOn(scheduler).shareReplay(0)
	}
}