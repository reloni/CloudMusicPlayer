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
	var raw: JSON { get }
	var oAuthResource: OAuthResource { get }
	var parent: CloudResource? { get }
	var httpClient: HttpClientProtocol { get }
	var uid: String { get }
	var name: String { get }
	var type: CloudResourceType { get }
	var mimeType: String? { get }
	var rootUrl: String { get }
	var resourcesUrl: String { get }
	func getRequestHeaders() -> [String: String]?
	func getRequestParameters() -> [String: String]?
	func loadChildResources() -> Observable<[CloudResource]>
	func loadChildResources(loadMode: CloudResourceLoadMode) -> Observable<[CloudResource]>
	func loadChildResourcesRecursive() -> Observable<[CloudResource]>
}

public protocol CloudAudioResource : CloudResource {
	var downloadUrl: Observable<String> { get }
}
