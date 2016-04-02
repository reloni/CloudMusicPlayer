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
	
	public func getCacheItem(identifier: StreamResourceIdentifier, customHttpHeaders: [String: String]? = nil, targetContentType: ContentType? = nil) -> CacheItem? {
		guard let url = identifier.streamResourceUrl, urlRequest = httpClient.httpUtilities.createUrlRequest(url, parameters: nil, headers: customHttpHeaders) else {
			return nil
		}
		return UrlCacheItem(urlRequest: urlRequest, httpClient: httpClient, saveCachedData: saveCachedData, targetContentType: targetContentType)
	}
}

public protocol CacheItem {
	var uid: String { get }
	var targetContentType: ContentType? { get }
	func getLoadTask() -> Observable<StreamTaskEvents>
}

public class UrlCacheItem : CacheItem {
	internal let urlRequest: NSMutableURLRequestProtocol
	internal let httpClient: HttpClientProtocol
	internal let saveCachedData: Bool
	//internal let targetMimeType: String?
	public let targetContentType: ContentType?
	public let uid: String
	
	public init(identifier: StreamResourceIdentifier, urlRequest: NSMutableURLRequestProtocol, httpClient: HttpClientProtocol = HttpClient.instance,
	            saveCachedData: Bool = true, targetContentType: ContentType? = nil) {
		self.urlRequest = urlRequest
		self.httpClient = httpClient
		self.saveCachedData = saveCachedData
		self.targetContentType = targetContentType
		self.uid = identifier.streamResourceUid
	}
	
	public convenience init(urlRequest: NSMutableURLRequestProtocol, httpClient: HttpClientProtocol = HttpClient.instance,
	                        saveCachedData: Bool = true, targetContentType: ContentType? = nil) {
		self.init(identifier: urlRequest.URL?.absoluteString.streamResourceUid ?? NSUUID().UUIDString, urlRequest: urlRequest, httpClient: httpClient,
		          saveCachedData: saveCachedData, targetContentType: targetContentType)
	}
	
//	public func getCacheTask() -> Observable<CacheDataResult> {
//		return self.httpClient.loadAndCacheData(self.urlRequest, sessionConfiguration: self.httpClient.urlSession.configuration,
//			saveCacheData: self.saveCachedData, targetMimeType: self.targetMimeType).map { result in
//				if case .Success = result {
//					print("Success!!!")
//				} else if case .SuccessWithCache = result {
//					print("SuccessWithCache!!")
//				}
//				return result
//			}.shareReplay(1)
//	}
	public func getLoadTask() -> Observable<StreamTaskEvents> {
		return self.httpClient.loadStreamData(urlRequest, cacheProvider: MemoryCacheProvider()).map { result in
			if case .Success = result {
				print("Success!!!")
			}
			return result
		}.shareReplay(1)
	}
}