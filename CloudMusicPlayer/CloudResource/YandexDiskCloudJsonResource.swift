//
//  YandexDiskCloudResource.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 27.02.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import SwiftyJSON
import RxSwift

public class YandexDiskCloudJsonResource : CloudJsonResource {
	public static let apiUrl = "https://cloud-api.yandex.net:443/v1/disk"
	public static let resourcesApiUrl = apiUrl + "/resources"
	public private (set) var parent: CloudResource?
	public private (set) var httpClient: HttpClientProtocol
	public let oAuthResource: OAuthResource
	public var raw: JSON
	internal let cacheProvider: CloudResourceCacheProviderType?
	
	public var name: String {
		return raw["name"].stringValue
	}
	
	public var path: String {
		return raw["path"].stringValue
	}
	
	public var uid: String {
		return path
	}
	
	public var type: String {
		return raw["type"].stringValue
	}
	
	public var mediaType: String? {
		return raw["media_type"].string
	}
	
	public var mimeType: String? {
		return raw["mime_type"].string
	}
	
	public var rootUrl: String = {
		return YandexDiskCloudJsonResource.apiUrl
	}()
	
	public var resourcesUrl: String = {
		return YandexDiskCloudAudioJsonResource.resourcesApiUrl
	}()
	
	init (raw: JSON, oAuthResource: OAuthResource, parent: CloudResource?, httpClient: HttpClientProtocol = HttpClient(),
	      cacheProvider: CloudResourceCacheProviderType? = nil) {
		self.raw = raw
		self.parent = parent
		self.oAuthResource = oAuthResource
		self.httpClient = httpClient
		self.cacheProvider = cacheProvider
	}
	
	public func getRequestHeaders() -> [String : String]? {
		return ["Authorization": oAuthResource.tokenId ?? ""]
	}
	
	public func getRequestParameters() -> [String : String]? {
		return ["path": path]
	}
	
	public func loadChildResources() -> Observable<[CloudResource]> {
		guard let request = httpClient.httpUtilities.createUrlRequest(resourcesUrl, parameters: getRequestParameters(), headers: getRequestHeaders()) else {
			return Observable.just([CloudResource]())
		}
		
		return YandexDiskCloudJsonResource.loadResources(request, oauthResource: oAuthResource, httpClient: httpClient, forResource: self,
		                                                 cacheProvider: cacheProvider)
	}
	
	public static func deserializeResponseData(json: JSON?, res: OAuthResource, parent: CloudResource? = nil,
		httpClient: HttpClientProtocol = HttpClient()) -> [CloudResource]? {
		guard let items = json?["_embedded"]["items"].array else {
			return nil
		}
		
		return items.map { item in
			if item["media_type"].stringValue == "audio" {
				return YandexDiskCloudAudioJsonResource(raw: item, oAuthResource: res, parent: parent, httpClient: httpClient)
			} else {
				return YandexDiskCloudJsonResource(raw: item, oAuthResource: res, parent: parent, httpClient: httpClient) }
		}
	}
		
	internal static func createRequestForLoadRootResources(oauthResource: OAuthResource, httpUtilities: HttpUtilitiesProtocol = HttpUtilities())
		-> NSMutableURLRequestProtocol? {
			guard let token = oauthResource.tokenId else {
			return nil
		}

		return httpUtilities.createUrlRequest(resourcesApiUrl, parameters: ["path": "/"], headers: ["Authorization": token])
	}
	
	internal static func loadResources(request: NSMutableURLRequestProtocol, oauthResource: OAuthResource,
	                                   httpClient: HttpClientProtocol = HttpClient(), forResource: CloudResource? = nil,
	                                   cacheProvider: CloudResourceCacheProviderType? = nil) -> Observable<[CloudResource]> {
		return Observable.create { observer in
			// check cached data
			if let forResource = forResource, cachedData = cacheProvider?.getCachedChilds(forResource),
				cachedChilds = YandexDiskCloudJsonResource.deserializeResponseData(JSON(data: cachedData), res: oauthResource, parent: forResource,
				httpClient: httpClient) {
				observer.onNext(cachedChilds)
			}
			
			// make request
			let task = httpClient.loadJsonData(request).doOnError { observer.onError($0) }.bindNext { json in
					if let data = YandexDiskCloudJsonResource.deserializeResponseData(json, res: oauthResource, parent: forResource, httpClient: httpClient) {
						observer.onNext(data)
						
					} else {
						observer.onNext([CloudResource]())
					}
					
					observer.onCompleted()
				}
			
			return AnonymousDisposable {
				task.dispose()
			}
		}
	}
	
	public static func loadRootResources(oauthResource: OAuthResource, httpRequest: HttpClientProtocol = HttpClient(),
	                                     cacheProvider: CloudResourceCacheProviderType? = nil) -> Observable<[CloudResource]>? {
			guard let request = createRequestForLoadRootResources(oauthResource) else { return nil }
			
			return loadResources(request, oauthResource: oauthResource, httpClient: httpRequest, forResource: nil, cacheProvider: cacheProvider)
	}
}