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

public struct CloudResourceManager {
	public static func loadDataForCloudResource(resource: CloudResource, completion: (json: JSON?) -> ()) {
		Alamofire.request(.GET, resource.baseUrl, parameters: resource.getRequestParameters(), encoding: .URL, headers: resource.getRequestHeaders())
			.responseData { response in
			if let data = response.data {
				completion(json: JSON(data: data))
			} else {
				completion(json: nil)
			}
		}
	}
//		let headers = ["Authorization": token]
//		let parameters: [String: AnyObject] = ["path": parent?["path"].string ?? "/"]
//		Alamofire.request(.GET, url, parameters: parameters, encoding: .URL, headers: headers).responseData { response in
//			//Alamofire.request(.GET, url, headers: headers).responseData { response in
//			guard let data = response.data else {
//				return
//			}
//			self.resourceContent = JSON(data: data)
//			dispatch_async(dispatch_get_main_queue()) {
//				self.tableView.reloadData()
//			}
//		}	}
}