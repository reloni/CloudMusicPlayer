//
//  StreamPlayerCacheManager.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 01.04.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import RxSwift

public class PlayerCache {
	internal let httpClient: HttpClientProtocol
	public let saveCachedData: Bool
	internal init(saveCachedData: Bool = false, httpClient: HttpClientProtocol = HttpClient.instance) {
		self.saveCachedData = saveCachedData
		self.httpClient = httpClient
	}
	
	public func getCacheItem(url: String, customHttpHeaders: [String: String]? = nil, resourceMimeType: String? = nil) -> CacheItem? {
		guard let urlRequest = httpClient.httpUtilities.createUrlRequest(url, parameters: nil, headers: customHttpHeaders) else {
			return nil
		}
		return UrlCacheItem(urlRequest: urlRequest, httpClient: httpClient, saveCachedData: saveCachedData, targetMimeType: resourceMimeType)
	}
}

public protocol CacheItem {
	var uid: String { get }
	//var cacheTask: Observable<CacheDataResult> { get }
	func getCacheTask() -> Observable<CacheDataResult>
}

public class UrlCacheItem : CacheItem {
	internal let urlRequest: NSMutableURLRequestProtocol
	internal let httpClient: HttpClientProtocol
	internal let saveCachedData: Bool
	internal let targetMimeType: String?
	public let uid: String
	
	public init(uid: String, urlRequest: NSMutableURLRequestProtocol, httpClient: HttpClientProtocol = HttpClient.instance,
	            saveCachedData: Bool = true, targetMimeType: String? = nil) {
		self.urlRequest = urlRequest
		self.httpClient = httpClient
		self.saveCachedData = saveCachedData
		self.targetMimeType = targetMimeType
		self.uid = uid
	}
	
	public convenience init(urlRequest: NSMutableURLRequestProtocol, httpClient: HttpClientProtocol = HttpClient.instance,
	                        saveCachedData: Bool = true, targetMimeType: String? = nil) {
		self.init(uid: urlRequest.URL?.absoluteString ?? NSUUID().UUIDString, urlRequest: urlRequest, httpClient: httpClient,
		          saveCachedData: saveCachedData, targetMimeType: targetMimeType)
	}
	
	public func getCacheTask() -> Observable<CacheDataResult> {
		return self.httpClient.loadAndCacheData(self.urlRequest, sessionConfiguration: self.httpClient.urlSession.configuration,
			saveCacheData: self.saveCachedData, targetMimeType: self.targetMimeType).map { result in
				if case .Success = result {
					print("Success!!!")
				} else if case .SuccessWithCache = result {
					print("SuccessWithCache!!")
				}
				return result
			}.shareReplay(1)
	}
}