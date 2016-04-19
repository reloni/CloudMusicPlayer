//
//  FakeCloudResource.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 15.03.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import RxSwift
import CloudMusicPlayer

public class FakeCloudResource : CloudResource {
	public var oAuthResource: OAuthResource
	public var parent: CloudResource? = nil
	public var childs: [CloudResource]? = nil
	public var httpClient: HttpClientProtocol
	public var httpUtilities: HttpUtilitiesProtocol
	public var name = ""
	public var path = ""
	public var type = ""
	public var mediaType: String? = nil
	public var mimeType: String? = nil
	public var rootUrl = ""
	public var resourcesUrl = ""
	
	public var requestHeaders: [String: String]? = nil
	public var requestParameters: [String: String]? = nil
	
	public func getRequestHeaders() -> [String: String]? {
		return requestHeaders
	}
	
	public func getRequestParameters() -> [String: String]? {
		return requestParameters
	}
	
	public func loadChilds(completion: ([CloudResource]?) -> ()) {
		
	}
	
	public func loadChilds() -> Observable<CloudRequestResult>? {
		return nil
	}
	
	public init(oaRes: OAuthResource, httpClient: HttpClientProtocol, httpUtilities: HttpUtilitiesProtocol) {
		self.oAuthResource = oaRes
		self.httpClient = httpClient
		self.httpUtilities = httpUtilities
	}
}