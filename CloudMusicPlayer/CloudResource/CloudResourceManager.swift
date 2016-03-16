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

//public class HttpRequestManager {
//	public static func loadDataForCloudResource(resource: CloudResource, completion: (json: JSON?) -> ()) {
//		loadDataForCloudResource(Alamofire.request(.GET, resource.resourcesUrl, parameters: resource.getRequestParameters(),
//			encoding: .URL, headers: resource.getRequestHeaders()), completion: completion)
//	}
//	
//	public static func loadDataForCloudResource(request: Request, completion: (json: JSON?) -> ()) {
//		request.responseData { response in
//				if let data = response.data {
//					completion(json: JSON(data: data))
//				} else {
//					completion(json: nil)
//				}
//		}
//	}
//}

