//
//  HttpUtilities.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 15.03.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation

public protocol HttpUtilitiesProtocol {
	func createUrlRequest(baseUrl: String, parameters: [String: String]?) -> NSMutableURLRequestProtocol?
	func createUrlRequest(baseUrl: String, parameters: [String: String]?, headers: [String: String]?) -> NSMutableURLRequestProtocol?
	func createUrlRequest(url: NSURL, headers: [String: String]?) -> NSMutableURLRequestProtocol
	func createUrlSession(configuration: NSURLSessionConfiguration, delegate: NSURLSessionDelegate?, queue: NSOperationQueue?) -> NSURLSessionProtocol
	func createUrlSessionStreamObserver() -> UrlSessionStreamObserverProtocol
	func createStreamDataTask(taskUid: String, request: NSMutableURLRequestProtocol, sessionConfiguration: NSURLSessionConfiguration, cacheProvider: CacheProvider?) -> StreamDataTaskProtocol
	//func createCacheDataTask(request: NSMutableURLRequestProtocol, sessionConfiguration: NSURLSessionConfiguration, saveCachedData: Bool, targetMimeType: String?) -> StreamDataCacheTaskProtocol
}

public class HttpUtilities {
	private static var _instance: HttpUtilitiesProtocol?
	private static var token: dispatch_once_t = 0
	
	public static var instance: HttpUtilitiesProtocol  {
		initWithInstance()
		return HttpUtilities._instance!
	}
	
	internal static func initWithInstance(instance: HttpUtilitiesProtocol? = nil) {
		dispatch_once(&token) {
			_instance = instance ?? HttpUtilities()
		}
	}
	
	internal init() { }
}

extension HttpUtilities : HttpUtilitiesProtocol {
	public func createUrlRequest(baseUrl: String, parameters: [String : String]?) -> NSMutableURLRequestProtocol? {
		guard let url = NSURL(baseUrl: baseUrl, parameters: parameters) else {
			return nil
		}
		return createUrlRequest(url)
	}
	
	public func createUrlRequest(baseUrl: String, parameters: [String: String]?, headers: [String: String]?) -> NSMutableURLRequestProtocol? {
		guard let url = NSURL(baseUrl: baseUrl, parameters: parameters) else {
			return nil
		}
		
		return createUrlRequest(url, headers: headers)
	}
	
	public func createUrlRequest(url: NSURL, headers: [String : String]? = nil) -> NSMutableURLRequestProtocol {
		let request = NSMutableURLRequest(URL: url)
		headers?.forEach { request.addValue($1, forHTTPHeaderField: $0) }
		return request
	}
	
	public func createUrlSession(configuration: NSURLSessionConfiguration, delegate: NSURLSessionDelegate? = nil, queue: NSOperationQueue? = nil)
		-> NSURLSessionProtocol {
		return NSURLSession(configuration: configuration,
			delegate: delegate,
			delegateQueue: queue)
	}
	
	public func createUrlSessionStreamObserver() -> UrlSessionStreamObserverProtocol {
		return UrlSessionStreamObserver()
	}
	
	public func createStreamDataTask(taskUid: String, request: NSMutableURLRequestProtocol,
	                                 sessionConfiguration: NSURLSessionConfiguration = .defaultSessionConfiguration(), cacheProvider: CacheProvider?) -> StreamDataTaskProtocol {
		return StreamDataTask(taskUid: taskUid, request: request, httpUtilities: self, sessionConfiguration: sessionConfiguration, cacheProvider: cacheProvider)
	}
//	
//	public func createCacheDataTask(request: NSMutableURLRequestProtocol, sessionConfiguration: NSURLSessionConfiguration, saveCachedData: Bool, targetMimeType: String?) -> StreamDataCacheTaskProtocol {
//		return StreamDataCacheTask(streamDataTask: createStreamDataTask(request, sessionConfiguration: sessionConfiguration), saveCachedData: saveCachedData, targetMimeType: targetMimeType)
//	}
}