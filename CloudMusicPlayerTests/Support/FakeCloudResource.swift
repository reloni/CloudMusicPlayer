//
//  FakeCloudResource.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 15.03.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import RxSwift
@testable import CloudMusicPlayer

public class FakeCloudResource : CloudResource {
	public var oAuthResource: OAuthResource
	public var parent: CloudResource? = nil
	public var childs: [CloudResource]? = nil
	public var httpClient: HttpClientProtocol
	public var httpUtilities: HttpUtilitiesProtocol
	public var name = ""
	public var path = ""
	public var uid: String {
		return path
	}
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
	
	public func loadChildResources() -> Observable<[CloudResource]> {
		return Observable.just([CloudResource]())
	}
	
	public init(oaRes: OAuthResource = OAuthResourceBase(id: "", authUrl: "", clientId: nil, tokenId: nil),
	            httpClient: HttpClientProtocol = HttpClient(), httpUtilities: HttpUtilitiesProtocol = HttpUtilities()) {
		self.oAuthResource = oaRes
		self.httpClient = httpClient
		self.httpUtilities = httpUtilities
	}
}