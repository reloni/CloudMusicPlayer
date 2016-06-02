//
//  CloudResource.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 25.02.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import SwiftyJSON
import RxSwift

public enum CloudResourceLoadMode {
	case CacheAndRemote
	case CacheOnly
	case RemoteOnly
}

public enum CloudResourceType {
	case Folder
	case File
	case Unknown
}

public protocol CloudResource {
	var resourceTypeIdentifier: String { get }
	var raw: JSON { get }
	var oAuthResource: OAuthType { get }
	//var parent: CloudResource? { get }
	var uid: String { get }
	var name: String { get }
	var type: CloudResourceType { get }
	var mimeType: String? { get }
	var rootUrl: String { get }
	var resourcesUrl: String { get }
	func getRequestHeaders() -> [String: String]?
	func getRequestParameters() -> [String: String]?
	func loadChildResources() -> Observable<Result<JSON>>
	//func loadChildResourcesRecursive() -> Observable<CloudResource>
	func deserializeResponse(json: JSON) -> [CloudResource]
	func wrapRawData(json: JSON) -> CloudResource
}

public protocol CloudAudioResource : CloudResource {
	var downloadUrl: Observable<String> { get }
}
