//
//  CloudResource.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 25.02.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import SwiftyJSON

public protocol CloudResource {
	var oAuthResource: OAuthResource { get }
	var parent: CloudResource? { get }
	var childs: [CloudResource]? { get }
	var name: String { get }
	var path: String { get }
	var baseUrl: String { get }
	func getRequestHeaders() -> [String: String]?
	func getRequestParameters() -> [String: AnyObject]?
	func loadChilds(completion: ([CloudResource]?) -> ())
}

public protocol CloudJsonResource : CloudResource {
	var raw: JSON { get }
}

public class YandexCloudJsonResource : CloudJsonResource {
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
	public var baseUrl: String {
		return "https://cloud-api.yandex.net:443/v1/disk/resources"
	}
	init (raw: JSON, oAuthResource: OAuthResource, parent: CloudResource?) {
		self.raw = raw
		self.parent = parent
		self.oAuthResource = oAuthResource
	}
	public func getRequestHeaders() -> [String : String]? {
		return ["Authentication": oAuthResource.tokenId ?? ""]
	}
	public func getRequestParameters() -> [String : AnyObject]? {
		return ["path": path as AnyObject]
	}
	public func loadChilds(completion: ([CloudResource]?) -> ()) {
		CloudResourceManager.loadDataForCloudResource(self) { json in
			if let json = json?["_embedded"]["items"] {
				var children = [CloudResource]()
				for (_,subJson):(String, JSON) in json {
					children.append(YandexCloudJsonResource(raw: subJson, oAuthResource: self.oAuthResource, parent: self))
				}
				completion(children)
			} else {
				completion(nil)
			}
		}
	}
}