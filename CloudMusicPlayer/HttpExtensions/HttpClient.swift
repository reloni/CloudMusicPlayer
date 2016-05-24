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
	var urlSession: NSURLSessionProtocol { get }
	var httpUtilities: HttpUtilitiesProtocol { get }
	func loadJsonData(request: NSMutableURLRequestProtocol) -> Observable<Result<JSON>>
	func loadData(request: NSMutableURLRequestProtocol) -> Observable<HttpRequestResult>
	func loadStreamData(request: NSMutableURLRequestProtocol, cacheProvider: CacheProvider?) -> Observable<StreamTaskResult>
}

public class HttpClient {
	public let urlSession: NSURLSessionProtocol
	public let httpUtilities: HttpUtilitiesProtocol
	internal let scheduler = ConcurrentDispatchQueueScheduler(globalConcurrentQueueQOS: DispatchQueueSchedulerQOS.Utility)
	
	public init(urlSession: NSURLSessionProtocol = NSURLSession(configuration: NSURLSession.defaultConfig),
	            httpUtilities: HttpUtilitiesProtocol = HttpUtilities()) {
		self.urlSession = urlSession
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
			//print("loadData: \(request.URL)")
			return Observable.create { [weak self] observer in
				guard let object = self else { observer.onCompleted(); return NopDisposable.instance }
				
				let task = object.urlSession.dataTaskWithRequest(request) { data, response, error in
					if let error = error {
						observer.onNext(.error(error))
						observer.onCompleted()
						return
					}
					
					guard let data = data else {
						observer.onNext(.success)
						observer.onCompleted()
						return
					}
					
					observer.onNext(.successData(data))
					observer.onCompleted()
				}
				
				task.resume()
				
				return AnonymousDisposable {
					task.cancel()
				}
			}.observeOn(scheduler).shareReplay(0)
	}
	
	public func loadStreamData(request: NSMutableURLRequestProtocol, cacheProvider: CacheProvider?)
		-> Observable<StreamTaskResult> {
		return Observable.create { [weak self] observer in
			guard let object = self else { observer.onCompleted(); return NopDisposable.instance }
			
			let task = object.httpUtilities.createStreamDataTask(NSUUID().UUIDString, request: request, sessionConfiguration: object.urlSession.configuration,
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