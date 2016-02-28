//
//  CloudResource.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 25.02.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import SwiftyJSON
import Alamofire

public protocol CloudResource {
	var oAuthResource: OAuthResource { get }
	var parent: CloudResource? { get }
	var childs: [CloudResource]? { get }
	var name: String { get }
	var path: String { get }
	var type: String { get }
	var baseUrl: String { get }
	func getRequestHeaders() -> [String: String]?
	func getRequestParameters() -> [String: AnyObject]?
	func loadChilds(completion: ([CloudResource]?) -> ())
}

public protocol CloudJsonResource : CloudResource {
	var raw: JSON { get }
}

public class YandexCloudJsonResource : CloudJsonResource {
	public static let apiUrl = "https://cloud-api.yandex.net:443/v1/disk/resources"
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
	
	public var baseUrl: String {
		return YandexCloudJsonResource.apiUrl
	}
	
	init (raw: JSON, oAuthResource: OAuthResource, parent: CloudResource?) {
		self.raw = raw
		self.parent = parent
		self.oAuthResource = oAuthResource
	}
	
	public func getRequestHeaders() -> [String : String]? {
		return ["Authorization": oAuthResource.tokenId ?? ""]
	}
	
	public func getRequestParameters() -> [String : AnyObject]? {
		return ["path": path as AnyObject]
	}
	
	public func loadChilds(completion: ([CloudResource]?) -> ()) {
		CloudResourceManager.loadDataForCloudResource(self) { json in
			completion(YandexCloudJsonResource.deserializeResponseData(json, res: self.oAuthResource))
		}
	}
	
	public static func deserializeResponseData(json: JSON?, res: OAuthResource) -> [CloudResource]? {
		guard let items = json?["_embedded"]["items"].array else {
			return nil
		}
	
		return items.map { YandexCloudJsonResource(raw: $0, oAuthResource: res, parent: nil) }
	}
	
	public static func loadRootResources(res: OAuthResource, completion: ([CloudResource]?) -> ()) {
		guard let token = res.tokenId else {
			completion(nil)
			return
		}
		
		CloudResourceManager.loadDataForCloudResource(Alamofire.request(.GET, apiUrl, parameters: ["path": "/"],
			encoding: .URL, headers: ["Authorization": token])) { json in
				completion(YandexCloudJsonResource.deserializeResponseData(json, res: res))
		}
	}
}