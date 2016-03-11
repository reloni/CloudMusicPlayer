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
	var mediaType: String? { get }
	var mimeType: String? { get }
	var baseUrl: String { get }
	func getRequestHeaders() -> [String: String]?
	func getRequestParameters() -> [String: AnyObject]?
	func loadChilds(completion: ([CloudResource]?) -> ())
}

public protocol CloudAudioResource : CloudResource {
	var title: String { get }
	var artist: String { get }
	var album: String { get }
	var albumYear: uint { get }
	var trackLength: uint { get }
	func getDownloadUrl(completion: (String?) -> ())
	func getFile(completion: (NSURL?) -> ())
}

public protocol CloudJsonResource : CloudResource {
	var raw: JSON { get }
}

