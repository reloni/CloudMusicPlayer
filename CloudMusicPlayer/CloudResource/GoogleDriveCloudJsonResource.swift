//
//  GoogleDriveCloudJsonResource.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 01.05.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import SwiftyJSON
import RxSwift

public class GoogleDriveCloudJsonResource : CloudResource {
	public static let apiUrl = "https://www.googleapis.com/drive/v3"
	public static let resourcesApiUrl = apiUrl + "/files"
	public private (set) var parent: CloudResource?
	public private (set) var httpClient: HttpClientProtocol
	public let oAuthResource: OAuthResource
	public var raw: JSON
	internal let cacheProvider: CloudResourceCacheProviderType?
	
	public var name: String {
		return raw["name"].stringValue
	}
	
	public var uid: String {
		return raw["id"].stringValue
	}
	
	public var type: CloudResourceType {
		guard let mimeType = mimeType else { return .Unknown }
		switch (mimeType) {
		case "application/vnd.google-apps.folder": return .Folder
		default: return .File
		}
	}
	
	public var mimeType: String? {
		return raw["mimeType"].string
	}
	
	public var rootUrl: String = {
		return GoogleDriveCloudJsonResource.apiUrl
	}()
	
	public var resourcesUrl: String = {
		return GoogleDriveCloudJsonResource.resourcesApiUrl
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
		if let token = oAuthResource.tokenId {
			return ["Authorization": "Bearer \(token)"]
		}
		return nil
	}
	
	public func getRequestParameters() -> [String : String]? {
		return ["q": "\'\(uid)\' in parents"]
	}
	
	public func loadChildResources(loadMode: CloudResourceLoadMode) -> Observable<[CloudResource]> {
		guard let request = httpClient.httpUtilities.createUrlRequest(resourcesUrl, parameters: getRequestParameters(), headers: getRequestHeaders()) else {
			return Observable.just([CloudResource]())
		}
		
		return GoogleDriveCloudJsonResource.loadResources(request, oauthResource: oAuthResource, httpClient: httpClient, forResource: self,
		                                                 cacheProvider: cacheProvider, loadMode: loadMode)
	}
	
	public func loadChildResources() -> Observable<[CloudResource]> {
		return loadChildResources(.CacheAndRemote)
	}
	
	internal static func recursiveLoadChildsRemote(resource: CloudResource) -> Observable<CloudResource> {
		return resource.loadChildResources(.RemoteOnly).flatMapLatest { e -> Observable<CloudResource> in
			return e.toObservable()
			}.flatMap { e -> Observable<CloudResource> in
				return [e].toObservable().concat(GoogleDriveCloudJsonResource.recursiveLoadChildsRemote(e))
		}
	}
	
	public func loadChildResourcesRecursive() -> Observable<[CloudResource]> {
		return GoogleDriveCloudJsonResource.recursiveLoadChildsRemote(self).toArray()
	}
	
	public static func deserializeResponseData(json: JSON?, res: OAuthResource, parent: CloudResource? = nil,
	                                           httpClient: HttpClientProtocol = HttpClient(), cacheProvider: CloudResourceCacheProviderType? = nil) -> [CloudResource]? {
		guard let items = json?["files"].array else {
			return nil
		}
		
		return items.map { item in
			if item["mimeType"].stringValue == "audio/mpeg" {
				return GoogleDriveCloudAudioJsonResource(raw: item, oAuthResource: res, parent: parent, httpClient: httpClient, cacheProvider: cacheProvider)
			} else {
				return GoogleDriveCloudJsonResource(raw: item, oAuthResource: res, parent: parent, httpClient: httpClient, cacheProvider: cacheProvider) }
		}
	}
	
	internal static func createRequestForLoadRootResources(oauthResource: OAuthResource, httpUtilities: HttpUtilitiesProtocol = HttpUtilities())
		-> NSMutableURLRequestProtocol? {
			guard let token = oauthResource.tokenId else {
				return nil
			}

			return httpUtilities.createUrlRequest(resourcesApiUrl, parameters: ["q": "\'0AChKrpwk2445Uk9PVA\' in parents"],
			                                      headers: ["Authorization": "Bearer \(token)"])
	}
	
	internal static func loadResources(request: NSMutableURLRequestProtocol, oauthResource: OAuthResource,
	                                   httpClient: HttpClientProtocol = HttpClient(), forResource: CloudResource? = nil,
	                                   cacheProvider: CloudResourceCacheProviderType? = nil,
	                                   loadMode: CloudResourceLoadMode = .CacheAndRemote) -> Observable<[CloudResource]> {
		return Observable.create { observer in
			
			// check cached data
			if loadMode == .CacheAndRemote || loadMode == .CacheOnly {
				if let cachedData = cacheProvider?.getCachedChilds(forResource?.uid ?? "0AChKrpwk2445Uk9PVA"),
					cachedChilds = GoogleDriveCloudJsonResource.deserializeResponseData(JSON(data: cachedData), res: oauthResource, parent: forResource,
						httpClient: httpClient, cacheProvider: cacheProvider) {
					observer.onNext(cachedChilds)
				}
			}
			
			// make request
			guard loadMode == .CacheAndRemote || loadMode == .RemoteOnly else {
				observer.onCompleted()
				return NopDisposable.instance
			}
			
			let task = httpClient.loadJsonData(request).doOnError { observer.onError($0) }.bindNext { json in
				if let data = GoogleDriveCloudJsonResource.deserializeResponseData(json, res: oauthResource, parent: forResource,
					httpClient: httpClient, cacheProvider: cacheProvider) {
					if let cacheProvider = cacheProvider, rawData = try? json?.rawData() {
						if let rawData = rawData { cacheProvider.cacheChilds(forResource?.uid ?? "/", childsData: rawData) }
					}
					
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
	                                     cacheProvider: CloudResourceCacheProviderType? = nil,
	                                     loadMode: CloudResourceLoadMode = .CacheAndRemote) -> Observable<[CloudResource]>? {
		guard let request = createRequestForLoadRootResources(oauthResource) else { return nil }
		
		return loadResources(request, oauthResource: oauthResource, httpClient: httpRequest, forResource: nil, cacheProvider: cacheProvider, loadMode: loadMode)
	}
}
