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
import RxSwift

public class YandexDiskCloudAudioJsonResource : YandexDiskCloudJsonResource, CloudAudioResource {
//	public var title: String {
//		return "song"
//	}
//	public var artist: String {
//		return "artist!"
//	}
//	public var album: String {
//		return "album"
//	}
//	public var albumYear: uint {
//		return 205
//	}
//	public var trackLength: uint {
//		return 205
//	}
	
	internal var downloadResourceUrl: NSURL? {
		return NSURL(baseUrl: resourcesUrl + "/download", parameters: getRequestParameters())
	}
	
	public var downloadUrl: Observable<String?>? {
		guard let url = downloadResourceUrl, request = httpUtilities.createUrlRequest(url, headers: getRequestHeaders()) else {
			return nil
		}
		
		return Observable.create { [unowned self] observer in
			let task = self.httpRequest.loadJsonData(request).bindNext { result in
				if case .SuccessJson(let json) = result, let href = json["href"].string {
					observer.onNext(href)
				} else {
					observer.onNext(nil)
				}
				observer.onCompleted()
			}
			
			return AnonymousDisposable {
				task.dispose()
			}
		}
	}
	
	public func getDownloadUrl(completion: (String?) -> ()) {
		let request = Alamofire.request(.GET, "https://cloud-api.yandex.net:443/v1/disk/resources/download", parameters: getRequestParameters(),
			encoding: .URL, headers: getRequestHeaders())
		HttpRequestManager.loadDataForCloudResource(request) { json in
			completion(json?["href"].string)
		}
	}
}