//
//  CloudResourceManager.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 25.02.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import RxSwift

public class CloudResourceManager {
	private static var _instance: CloudResourceManager?
	private static var token: dispatch_once_t = 0
	public static var instance: CloudResourceManager  {
		dispatch_once(&token) {
			CloudResourceManager._instance = CloudResourceManager()
		}
		return CloudResourceManager._instance!
	}
	
	public static func loadDataForCloudResource(resource: CloudResource, completion: (json: JSON?) -> ()) {
		loadDataForCloudResource(Alamofire.request(.GET, resource.baseUrl, parameters: resource.getRequestParameters(),
			encoding: .URL, headers: resource.getRequestHeaders()), completion: completion)
	}
	
	public static func loadDataForCloudResource(request: Request, completion: (json: JSON?) -> ()) {
		request.responseData { response in
				if let data = response.data {
					completion(json: JSON(data: data))
				} else {
					completion(json: nil)
				}
		}
	}
}

extension CloudResourceManager : CloudResourceManagerProtocol {
	public func loadDataForCloudResource(request: AlamofireRequestProtocol) -> Observable<JSON?> {
		return Observable.create { observer in
			request.getResponseData { response in
				guard let data = response.getData() else {
					observer.onNext(nil)
					observer.onCompleted()
					return
				}
				
				observer.onNext(JSON(data))
				observer.onCompleted()
			}
			
			return AnonymousDisposable { }
		}
	}
	
	public func loadDataForCloudResource(resource: CloudResource) -> Observable<JSON?> {
		return loadDataForCloudResource(Alamofire.request(.GET, resource.baseUrl, parameters: resource.getRequestParameters(),
			encoding: .URL, headers: resource.getRequestHeaders()))
	}
}
