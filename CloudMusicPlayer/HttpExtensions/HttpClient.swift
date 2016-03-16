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

public protocol HttpClientProtocol {
	var urlSession: NSURLSessionProtocol { get }
	var httpUtilities: HttpUtilitiesProtocol { get }
	func loadJsonData(request: NSMutableURLRequestProtocol) -> Observable<HttpRequestResult>
	func loadData(request: NSMutableURLRequestProtocol) -> Observable<HttpRequestResult>
	func loadDataForCloudResource(resource: CloudResource) -> Observable<HttpRequestResult>?
}
public class HttpClient {
	public let urlSession: NSURLSessionProtocol
	public let httpUtilities: HttpUtilitiesProtocol
	private static var _instance: HttpClientProtocol?
	private static var token: dispatch_once_t = 0
	
	public static var instance: HttpClientProtocol  {
		initWithInstance()
		return HttpClient._instance!
	}
	
	internal static func initWithInstance(instance: HttpClientProtocol? = nil, urlSession: NSURLSessionProtocol = NSURLSession.sharedSession(),
		httpUtilities: HttpUtilitiesProtocol = HttpUtilities.instance) {
		dispatch_once(&token) {
			_instance = instance ?? HttpClient(urlSession: urlSession)
		}
	}
	
	public init(urlSession: NSURLSessionProtocol = NSURLSession.sharedSession(), httpUtilities: HttpUtilitiesProtocol = HttpUtilities.instance) {
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
		guard let request = createRequestForCloudResource(resource) else { return nil }
		return loadJsonData(request)
	}
}