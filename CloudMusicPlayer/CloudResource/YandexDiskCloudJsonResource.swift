//
//  YandexDiskCloudResource.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 27.02.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import SwiftyJSON
import Alamofire
import RxSwift

public class YandexDiskCloudJsonResource : CloudJsonResource {
	public static let apiUrl = "https://cloud-api.yandex.net:443/v1/disk"
	public static let resourcesApiUrl = apiUrl + "/resources"
	public private (set) var parent: CloudResource?
	public private (set) var childs: [CloudResource]?
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
	
	init (raw: JSON, oAuthResource: OAuthResource, parent: CloudResource?) {
		self.raw = raw
		self.parent = parent
		self.oAuthResource = oAuthResource
	}
	
	public func getRequestHeaders() -> [String : String]? {
		return ["Authorization": oAuthResource.tokenId ?? ""]
	}
	
	public func getRequestParameters() -> [String : String]? {
		return ["path": path]
	}
	
	public func loadChilds(completion: ([CloudResource]?) -> ()) {
		HttpRequestManager.loadDataForCloudResource(self) { json in
			completion(YandexDiskCloudJsonResource.deserializeResponseData(json, res: self.oAuthResource))
		}
	}
	
	public func loadChilds() -> Observable<CloudRequestResult>? {
		return Observable.create { observer in

			return AnonymousDisposable {
				
			}
		}
	}
	
	public static func deserializeResponseData(json: JSON?, res: OAuthResource) -> [CloudResource]? {
		guard let items = json?["_embedded"]["items"].array else {
			return nil
		}
		
		return items.map { item in
			if item["media_type"].stringValue == "audio" {
				return YandexDiskCloudAudioJsonResource(raw: item, oAuthResource: res, parent: nil)
			} else {
				return YandexDiskCloudJsonResource(raw: item, oAuthResource: res, parent: nil) }
		}
	}
	
	public static func loadRootResources(res: OAuthResource, completion: ([CloudResource]?) -> ()) {
		guard let token = res.tokenId else {
			completion(nil)
			return
		}
		
		HttpRequestManager.loadDataForCloudResource(Alamofire.request(.GET, apiUrl, parameters: ["path": "/"],
			encoding: .URL, headers: ["Authorization": token])) { json in
				completion(YandexDiskCloudJsonResource.deserializeResponseData(json, res: res))
		}
	}
	
	internal static func createRequestForLoadRootResources(oauthResource: OAuthResource, httpUtilities: HttpUtilitiesProtocol = HttpUtilities.instance) -> NSMutableURLRequestProtocol? {
		guard let token = oauthResource.tokenId, request = httpUtilities.createUrlRequest(resourcesApiUrl, parameters: ["path": "/"]) else {
			return nil
		}
		
		request.addValue(token, forHTTPHeaderField: "Authorization")
		return request
	}
	
	public static func loadRootResources(oauthResource: OAuthResource, httpRequest: HttpRequestProtocol = HttpRequest.instance,
		session: NSURLSessionProtocol = NSURLSession.sharedSession(), httpUtilities: HttpUtilitiesProtocol = HttpUtilities.instance) -> Observable<CloudRequestResult>? {
			guard let request = createRequestForLoadRootResources(oauthResource, httpUtilities: httpUtilities) else { return nil }
			
			return Observable.create { observer in
				let task = httpRequest.loadJsonData(request, session: session).bindNext { result in
					if case .SuccessJson(let json) = result {
						observer.onNext(.Success(deserializeResponseData(json, res: oauthResource)))
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
}