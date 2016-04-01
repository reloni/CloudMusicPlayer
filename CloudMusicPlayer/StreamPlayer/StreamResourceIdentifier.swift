////
////  StreamResourceIdentifier.swift
////  CloudMusicPlayer
////
////  Created by Anton Efimenko on 29.03.16.
////  Copyright © 2016 Anton Efimenko. All rights reserved.
////
//
//import Foundation
//import RxSwift
//
//public protocol StreamResourceIdentifier {
//	var uid: String { get }
//	func getCacheTaskForResource() -> Observable<CacheDataResult>
//}
//
//public class StreamUrlResourceIdentifier {
//	internal let urlRequest: NSMutableURLRequestProtocol
//	internal let httpClient: HttpClientProtocol
//	internal let saveCachedData: Bool
//	internal let targetMimeType: String?
//	public let uid: String
//	
//	public init(uid: String, urlRequest: NSMutableURLRequestProtocol, httpClient: HttpClientProtocol = HttpClient.instance,
//	            saveCachedData: Bool = true, targetMimeType: String? = nil) {
//		self.urlRequest = urlRequest
//		self.httpClient = httpClient
//		self.saveCachedData = saveCachedData
//		self.targetMimeType = targetMimeType
//		self.uid = uid
//	}
//	
//	public convenience init(urlRequest: NSMutableURLRequestProtocol, httpClient: HttpClientProtocol = HttpClient.instance,
//	                        saveCachedData: Bool = true, targetMimeType: String? = nil) {
//		self.init(uid: urlRequest.URL?.absoluteString ?? NSUUID().UUIDString, urlRequest: urlRequest, httpClient: httpClient,
//		          saveCachedData: saveCachedData, targetMimeType: targetMimeType)
//	}
//}
//extension StreamUrlResourceIdentifier : StreamResourceIdentifier {	
//	public func getCacheTaskForResource() -> Observable<CacheDataResult> {
//		return httpClient.loadAndCacheData(urlRequest, sessionConfiguration: httpClient.urlSession.configuration, saveCacheData: saveCachedData,
//		                                              targetMimeType: targetMimeType)
//	}
//}