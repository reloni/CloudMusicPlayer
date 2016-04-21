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

public protocol CloudResource {
	var oAuthResource: OAuthResource { get }
	var parent: CloudResource? { get }
	var httpClient: HttpClientProtocol { get }
	var uid: String { get }
	var name: String { get }
	var path: String { get }
	var type: String { get }
	var mediaType: String? { get }
	var mimeType: String? { get }
	var rootUrl: String { get }
	var resourcesUrl: String { get }
	func getRequestHeaders() -> [String: String]?
	func getRequestParameters() -> [String: String]?
	func loadChildResources() -> Observable<[CloudResource]>
	func loadChildResources(loadMode: CloudResourceLoadMode) -> Observable<[CloudResource]>
}

public protocol CloudAudioResource : CloudResource {
	var downloadUrl: Observable<String?>? { get }
}

public protocol CloudJsonResource : CloudResource {
	var raw: JSON { get }
}

