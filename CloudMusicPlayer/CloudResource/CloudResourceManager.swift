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
	
	public static func downloadData(resource: CloudAudioResource, completion: (fileUrl: NSURL?) -> ()) {
		resource.getDownloadUrl { url in
			guard let url = url else {
				completion(fileUrl: nil)
				return
			}
			let request = Alamofire.request(.GET, url, parameters: nil,
				encoding: .URL, headers: resource.getRequestHeaders())
			downloadData(request, completion: completion)
		}
	}
	
	public static func downloadData(request: Request, completion: (fileUrl: NSURL?) -> ()) {
		request.responseData { response in
			if let data = response.data {
				let fileManager = NSFileManager.defaultManager()
				let directoryURL = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
				let pathComponent = NSUUID().UUIDString + ".mp3"
				let url = directoryURL.URLByAppendingPathComponent(pathComponent)
				if data.writeToURL(url, atomically: true) {
					completion(fileUrl: url)
				} else {
					completion(fileUrl: nil)
				}
			} else {
				completion(fileUrl: nil)
			}
		}
	}
}