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
import RxSwift

public enum CloudRequestResult {
	case Success([CloudResource]?)
	case Error(NSError?)
}

public protocol CloudResource {
	var oAuthResource: OAuthResource { get }
	var parent: CloudResource? { get }
	var httpUtilities: HttpUtilitiesProtocol { get }
	var httpRequest: HttpRequestProtocol { get }
	var name: String { get }
	var path: String { get }
	var type: String { get }
	var mediaType: String? { get }
	var mimeType: String? { get }
	var rootUrl: String { get }
	var resourcesUrl: String { get }
	func getRequestHeaders() -> [String: String]?
	func getRequestParameters() -> [String: String]?
	func loadChilds() -> Observable<CloudRequestResult>?
}

public protocol CloudAudioResource : CloudResource {
	var downloadUrl: Observable<String?>? { get }
}

public protocol CloudJsonResource : CloudResource {
	var raw: JSON { get }
}

