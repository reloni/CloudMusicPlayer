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
	case SuccessJson(JSON)
	case Error(NSError?)
}

public protocol HttpRequestProtocol {
	var urlSession: NSURLSessionProtocol { get }
	func loadJsonData(request: NSMutableURLRequestProtocol) -> Observable<HttpRequestResult>
	func loadData(request: NSMutableURLRequestProtocol) -> Observable<HttpRequestResult>
	func loadDataForCloudResource(resource: CloudResource) -> Observable<HttpRequestResult>?
}
public class HttpRequest {
	public let urlSession: NSURLSessionProtocol
	private static var _instance: HttpRequestProtocol?
	private static var token: dispatch_once_t = 0
	
	public static var instance: HttpRequestProtocol  {
		initWithInstance()
		return HttpRequest._instance!
	}
	
	internal static func initWithInstance(instance: HttpRequestProtocol? = nil, urlSession: NSURLSessionProtocol = NSURLSession.sharedSession()) {
		dispatch_once(&token) {
			_instance = instance ?? HttpRequest(urlSession: urlSession)
		}
	}
	
	public init(urlSession: NSURLSessionProtocol = NSURLSession.sharedSession()) {
		self.urlSession = urlSession
	}
	
	internal func createRequestForCloudResource(resource: CloudResource, httpUtilities: HttpUtilitiesProtocol = HttpUtilities.instance) -> NSMutableURLRequestProtocol? {
		guard let request: NSMutableURLRequestProtocol =
			httpUtilities.createUrlRequest(resource.resourcesUrl, parameters: resource.getRequestParameters()) else {
				return nil
		}
		resource.getRequestHeaders()?.forEach { request.addValue($1, forHTTPHeaderField: $0) }
		return request
	}
}

extension HttpRequest : HttpRequestProtocol {
	public func loadJsonData(request: NSMutableURLRequestProtocol)
		-> Observable<HttpRequestResult> {
			return Observable.create { [unowned self] observer in
				let task = self.loadData(request).bindNext { result in
					if case .SuccessData(let data) = result {
						observer.onNext(.SuccessJson(JSON(data: data)))
					} else {
						observer.onNext(result)
					}
					observer.onCompleted()
				}
				
				return AnonymousDisposable {
					task.dispose()
				}
			}
	}
	
	public func loadData(request: NSMutableURLRequestProtocol)
		-> Observable<HttpRequestResult> {
			return Observable.create { [unowned self] observer in
				
				let task = self.urlSession.dataTaskWithRequest(request) { data, response, error in
					if let error = error {
						observer.onNext(.Error(error))
						observer.onCompleted()
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
					task.suspend()
				}
			}
	}
	
	public func loadDataForCloudResource(resource: CloudResource) -> Observable<HttpRequestResult>? {
		guard let request = createRequestForCloudResource(resource, httpUtilities: resource.httpUtilities) else { return nil }
		return loadJsonData(request)
	}
}