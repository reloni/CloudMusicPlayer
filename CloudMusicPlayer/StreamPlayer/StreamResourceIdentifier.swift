//
//  StreamResourceIdentifier.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 29.03.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import RxSwift

public protocol StreamResourceIdentifier {
	var uid: String { get }
	func getCacheTaskForResource() -> Observable<CacheDataResult>
}

public class StreamUrlResourceIdentifier {
	internal let urlRequest: NSMutableURLRequestProtocol
	internal let httpClient: HttpClientProtocol
	internal let sessionConfiguration: NSURLSessionConfiguration
	internal let saveCachedData: Bool
	internal let targetMimeType: String?
	public init(urlRequest: NSMutableURLRequestProtocol, httpClient: HttpClientProtocol = HttpClient.instance,
	            sessionConfiguration: NSURLSessionConfiguration = NSURLSession.defaultConfig, saveCachedData: Bool = true,
	            targetMimeType: String? = nil) {
		self.urlRequest = urlRequest
		self.httpClient = httpClient
		self.sessionConfiguration = sessionConfiguration
		self.saveCachedData = saveCachedData
		self.targetMimeType = targetMimeType
	}
}
extension StreamUrlResourceIdentifier : StreamResourceIdentifier {
	public var uid: String {
		return urlRequest.URL!.absoluteString
	}
	
	public func getCacheTaskForResource() -> Observable<CacheDataResult> {
		return httpClient.loadAndCacheData(urlRequest, sessionConfiguration: sessionConfiguration, saveCacheData: saveCachedData,
		                                              targetMimeType: targetMimeType)
	}
}