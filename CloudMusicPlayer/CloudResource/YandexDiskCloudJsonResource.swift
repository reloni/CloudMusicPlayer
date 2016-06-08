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
	                                   oauth: OAuthType) -> CloudResource {
		return YandexDiskCloudJsonResource(raw: JSON(["name": "disk", "path": "/"]), httpClient: httpClient, oauth: oauth)
	}
	
	public static let apiUrl = "https://cloud-api.yandex.net:443/v1/disk"
	public static let resourcesApiUrl = apiUrl + "/resources"
	public static let typeIdentifier = "YandexDiskCloudResource"
	public internal (set) var httpClient: HttpClientProtocol
	public let oAuthResource: OAuthType
	public var raw: JSON
	
	public var rootUrl: String = {
		return YandexDiskCloudJsonResource.apiUrl
	}()
	
	public var resourcesUrl: String = {
		return YandexDiskCloudAudioJsonResource.resourcesApiUrl
	}()
	
	init (raw: JSON, httpClient: HttpClientProtocol, oauth: OAuthType) {
		self.raw = raw
		//self.parent = parent
		self.oAuthResource = oauth
		self.httpClient = httpClient
	}
	
	internal func createRequest() -> NSMutableURLRequestProtocol? {
		if oAuthResource.accessToken == nil { return nil }
		return httpClient.httpUtilities.createUrlRequest(resourcesUrl, parameters: getRequestParameters(), headers: getRequestHeaders())
	}
}

extension YandexDiskCloudJsonResource : CloudResource {
	public var resourceTypeIdentifier: String {
		return YandexDiskCloudJsonResource.typeIdentifier
	}
	
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
		return ["Authorization": oAuthResource.accessToken ?? ""]
	}
	
	public func getRequestParameters() -> [String : String]? {
		return ["path": uid]
	}
	
	public func loadChildResources() -> Observable<Result<JSON>> {
		guard let request = createRequest() else {
			return Observable.empty()
		}

		return httpClient.loadJsonData(request)
	}
		
	public func deserializeResponse(json: JSON) -> [CloudResource] {
		guard let items = json["_embedded"]["items"].array else {
			return [CloudResource]()
		}
		
		return items.map { item -> CloudResource in
			return wrapRawData(item)
		}
	}
	
	public func wrapRawData(json: JSON) -> CloudResource {
		if json["media_type"].stringValue == "audio" {
			return YandexDiskCloudAudioJsonResource(raw: json, httpClient: httpClient, oauth: oAuthResource)
		} else {
			return YandexDiskCloudJsonResource(raw: json, httpClient: httpClient, oauth: oAuthResource)
		}
	}
}