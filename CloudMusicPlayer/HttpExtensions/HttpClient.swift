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
	case Success
	case SuccessData(NSData)
}

public protocol HttpClientProtocol {
	var urlSession: NSURLSessionProtocol { get }
	var httpUtilities: HttpUtilitiesProtocol { get }
	func loadJsonData(request: NSMutableURLRequestProtocol) -> Observable<JSON>
	func loadData(request: NSMutableURLRequestProtocol) -> Observable<HttpRequestResult>
	func loadDataForCloudResource(resource: CloudResource) -> Observable<JSON>
	func loadStreamData(request: NSMutableURLRequestProtocol, cacheProvider: CacheProvider?) -> Observable<StreamTaskEvents>
}

public class HttpClient {
	public let urlSession: NSURLSessionProtocol
	public let httpUtilities: HttpUtilitiesProtocol
	
	public init(urlSession: NSURLSessionProtocol = NSURLSession(configuration: NSURLSession.defaultConfig),
	            httpUtilities: HttpUtilitiesProtocol = HttpUtilities()) {
		self.urlSession = urlSession
		self.httpUtilities = httpUtilities
	}
	
	internal func createRequestForCloudResource(resource: CloudResource) -> NSMutableURLRequestProtocol? {
		guard let request: NSMutableURLRequestProtocol =
			httpUtilities.createUrlRequest(resource.resourcesUrl, parameters: resource.getRequestParameters()) else {
				return nil
		}
		resource.getRequestHeaders()?.forEach { request.addValue($1, forHTTPHeaderField: $0) }
		return request
	}
}

extension HttpClient : HttpClientProtocol {
	public func loadJsonData(request: NSMutableURLRequestProtocol)
		-> Observable<JSON> {
			return Observable.create { [unowned self] observer in
				let task = self.loadData(request).doOnError { observer.onError($0) }.bindNext { result in
					if case .SuccessData(let data) = result {
						observer.onNext(JSON(data: data))
					} //else if case .Success = result {
						//observer.onNext(nil)
					//}
					observer.onCompleted()
				}
				
				return AnonymousDisposable {
					task.dispose()
				}
			}.shareReplay(1)
	}
	
	public func loadData(request: NSMutableURLRequestProtocol)
		-> Observable<HttpRequestResult> {
			return Observable.create { [unowned self] observer in
				
				let task = self.urlSession.dataTaskWithRequest(request) { data, response, error in
					if let error = error {
						observer.onError(error)
						return
					}
					
					guard let data = data else {
						observer.onNext(.Success)
						observer.onCompleted()
						return
					}
					
					observer.onNext(.SuccessData(data))
					observer.onCompleted()
				}
				
				task.resume()
				
				return AnonymousDisposable {
					task.cancel()
				}
			}.shareReplay(1)
	}
	
	public func loadDataForCloudResource(resource: CloudResource) -> Observable<JSON> {
		guard let request = createRequestForCloudResource(resource) else { return Observable.empty() }
		return loadJsonData(request)
	}
	
	public func loadStreamData(request: NSMutableURLRequestProtocol, cacheProvider: CacheProvider?)
		-> Observable<StreamTaskEvents> {
		return Observable.create { [unowned self] observer in
			let task = self.httpUtilities.createStreamDataTask(NSUUID().UUIDString, request: request, sessionConfiguration: self.urlSession.configuration,
				cacheProvider: cacheProvider)
				
			let disposable = task.taskProgress.doOnError { observer.onError($0) }.bindNext { result in
				observer.onNext(result)
				
				if case .Success = result {
					observer.onCompleted()
				}
			}
			
			task.resume()
			
			return AnonymousDisposable {
				task.cancel()
				disposable.dispose()
			}
		}.shareReplay(1)
	}
}