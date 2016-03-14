//
//  YandexDiskCloudMediaJsonResource.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 27.02.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import SwiftyJSON
import Alamofire

public class YandexDiskCloudAudioJsonResource : YandexDiskCloudJsonResource, CloudAudioResource {
	public var title: String {
		return "song"
	}
	public var artist: String {
		return "artist!"
	}
	public var album: String {
		return "album"
	}
	public var albumYear: uint {
		return 205
	}
	public var trackLength: uint {
		return 205
	}
	
	public func getDownloadUrl(completion: (String?) -> ()) {
		let request = Alamofire.request(.GET, "https://cloud-api.yandex.net:443/v1/disk/resources/download", parameters: getRequestParameters(),
			encoding: .URL, headers: getRequestHeaders())
		HttpRequestManager.loadDataForCloudResource(request) { json in
			completion(json?["href"].string)
		}
	}
}