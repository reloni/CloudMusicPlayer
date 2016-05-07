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

public class YandexDiskCloudJsonResource {
	public static func getRootResource(httpClient: HttpClientProtocol = HttpClient(),
	                                   oauth: OAuthResource) -> Observable<CloudResource> {
		return Observable.just(YandexDiskCloudJsonResource(raw: JSON(["name": "disk", "path": "/"]), httpClient: httpClient, oauth: oauth, parent: nil))
	}
	
	public static let apiUrl = "https://cloud-api.yandex.net:443/v1/disk"
	public static let resourcesApiUrl = apiUrl + "/resources"
	public internal (set) var parent: CloudResource?
	public internal (set) var httpClient: HttpClientProtocol
	public let oAuthResource: OAuthResource
	public var raw: JSON
	
	public var rootUrl: String = {
		return YandexDiskCloudJsonResource.apiUrl
	}()
	
	public var resourcesUrl: String = {
		return YandexDiskCloudAudioJsonResource.resourcesApiUrl
	}()
	
	init (raw: JSON, httpClient: HttpClientProtocol, oauth: OAuthResource, parent: CloudResource?) {
		self.raw = raw
		self.parent = parent
		self.oAuthResource = oauth
		self.httpClient = httpClient
	}
	
	internal func createRequest() -> NSMutableURLRequestProtocol? {
		if oAuthResource.tokenId == nil { return nil }
		return httpClient.httpUtilities.createUrlRequest(resourcesUrl, parameters: getRequestParameters(), headers: getRequestHeaders())
	}
}

extension YandexDiskCloudJsonResource : CloudResource {
	public var name: String {
		return raw["name"].stringValue
	}
	
	public var uid: String {
		return raw["path"].stringValue
	}
	
	public var type: CloudResourceType {
		switch (raw["type"].stringValue) {
		case "file": return .File
		case "dir": return .Folder
		default: return .Unknown
		}
	}
	
	public var mimeType: String? {
		return raw["mime_type"].string
	}
	
	public func getRequestHeaders() -> [String : String]? {
		return ["Authorization": oAuthResource.tokenId ?? ""]
	}
	
	public func getRequestParameters() -> [String : String]? {
		return ["path": uid]
	}
	
	public func loadChildResources() -> Observable<JSON> {
		guard let request = createRequest() else {
			return Observable.empty()
		}
		
		return httpClient.loadJsonData(request)
	}
	
	public func loadChildResourcesRecursive() -> Observable<CloudResource> {
		return loadChildResources().flatMapLatest { json in
			return self.deserializeResponse(json)
			}.flatMap { e -> Observable<CloudResource> in
				return [e].toObservable().concat(e.loadChildResourcesRecursive())
		}
	}
	
	public func deserializeResponse(json: JSON) -> Observable<CloudResource> {
		guard let items = json["_embedded"]["items"].array else {
			return Observable.empty()
		}
		
		return items.map { item -> CloudResource in
			if item["media_type"].stringValue == "audio" {
				return YandexDiskCloudAudioJsonResource(raw: item, httpClient: httpClient, oauth: oAuthResource, parent: self)
			} else {
				return YandexDiskCloudJsonResource(raw: item, httpClient: httpClient, oauth: oAuthResource, parent: self) }
			}.toObservable()
	}
}