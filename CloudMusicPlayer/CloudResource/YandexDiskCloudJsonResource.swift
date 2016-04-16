//
//  YandexDiskCloudResource.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 27.02.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import SwiftyJSON
//import Alamofire
import RxSwift

public class YandexDiskCloudJsonResource : CloudJsonResource {
	public static let apiUrl = "https://cloud-api.yandex.net:443/v1/disk"
	public static let resourcesApiUrl = apiUrl + "/resources"
	public private (set) var parent: CloudResource?
	public private (set) var httpClient: HttpClientProtocol
	public let oAuthResource: OAuthResource
	public var raw: JSON
	
	public var name: String {
		return raw["name"].stringValue
	}
	
	public var path: String {
		return raw["path"].stringValue
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
	
	init (raw: JSON, oAuthResource: OAuthResource, parent: CloudResource?, httpClient: HttpClientProtocol = HttpClient()) {
			self.raw = raw
			self.parent = parent
			self.oAuthResource = oAuthResource
			self.httpClient = httpClient
	}
	
	public func getRequestHeaders() -> [String : String]? {
		return ["Authorization": oAuthResource.tokenId ?? ""]
	}
	
	public func getRequestParameters() -> [String : String]? {
		return ["path": path]
	}
	
	public func loadChilds() -> Observable<CloudRequestResult>? {
		guard let request = httpClient.httpUtilities.createUrlRequest(resourcesUrl, parameters: getRequestParameters(), headers: getRequestHeaders()) else {
			return nil
		}
		
		return YandexDiskCloudJsonResource.loadResources(request, oauthResource: oAuthResource, httpClient: httpClient)
	}
	
	public static func deserializeResponseData(json: JSON?, res: OAuthResource,
		httpClient: HttpClientProtocol = HttpClient()) -> [CloudResource]? {
		guard let items = json?["_embedded"]["items"].array else {
			return nil
		}
		
		return items.map { item in
			if item["media_type"].stringValue == "audio" {
				return YandexDiskCloudAudioJsonResource(raw: item, oAuthResource: res, parent: nil, httpClient: httpClient)
			} else {
				return YandexDiskCloudJsonResource(raw: item, oAuthResource: res, parent: nil, httpClient: httpClient) }
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
		httpClient: HttpClientProtocol = HttpClient()) -> Observable<CloudRequestResult> {
		return Observable.create { observer in
			let task = httpClient.loadJsonData(request).bindNext { result in
				if case .SuccessJson(let json) = result {
					observer.onNext(.Success(deserializeResponseData(json, res: oauthResource, httpClient: httpClient)))
				} else if case .Error(let error) = result {
					observer.onNext(.Error(error))
				}
				
				observer.onCompleted()
			}
			
			return AnonymousDisposable {
				task.dispose()
			}
		}
	}
	
	public static func loadRootResources(oauthResource: OAuthResource, httpRequest: HttpClientProtocol = HttpClient()) -> Observable<CloudRequestResult>? {
			guard let request = createRequestForLoadRootResources(oauthResource) else { return nil }
			
			return loadResources(request, oauthResource: oauthResource, httpClient: httpRequest)
	}
}