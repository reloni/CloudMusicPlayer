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
	func loadJsonData(request: NSMutableURLRequestProtocol, session: NSURLSessionProtocol) -> Observable<HttpRequestResult>
	func loadData(request: NSMutableURLRequestProtocol, session: NSURLSessionProtocol) -> Observable<HttpRequestResult>
	func loadDataForCloudResource(resource: CloudResource, session: NSURLSessionProtocol, httpUtilities: HttpUtilitiesProtocol) -> Observable<HttpRequestResult>?
}
public class HttpRequest {
	private static var _instance: HttpRequestProtocol?
	private static var token: dispatch_once_t = 0
	
	public static var instance: HttpRequestProtocol  {
		initWithInstance()
		return HttpRequest._instance!
	}
	
	internal static func initWithInstance(instance: HttpRequestProtocol? = nil) {
		dispatch_once(&token) {
			_instance = instance ?? HttpRequest()
		}
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
	public func loadJsonData(request: NSMutableURLRequestProtocol, session: NSURLSessionProtocol = NSURLSession.sharedSession())
		-> Observable<HttpRequestResult> {
			return Observable.create { [unowned self] observer in
				let task = self.loadData(request, session: session).bindNext { result in
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
	
	public func loadData(request: NSMutableURLRequestProtocol, session: NSURLSessionProtocol = NSURLSession.sharedSession())
		-> Observable<HttpRequestResult> {
			return Observable.create { observer in
				
				let task = session.dataTaskWithRequest(request) { data, response, error in
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
	
	public func loadDataForCloudResource(resource: CloudResource, session: NSURLSessionProtocol = NSURLSession.sharedSession(),
		httpUtilities: HttpUtilitiesProtocol = HttpUtilities.instance) -> Observable<HttpRequestResult>? {
		guard let request = createRequestForCloudResource(resource, httpUtilities: httpUtilities) else { return nil }
		return loadJsonData(request, session: session)
	}
}