//
//  YandexDiskCloudMediaJsonResource.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 27.02.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import SwiftyJSON
//import Alamofire
import RxSwift

public class YandexDiskCloudAudioJsonResource : YandexDiskCloudJsonResource, CloudAudioResource {
	internal var downloadResourceUrl: NSURL? {
		return NSURL(baseUrl: resourcesUrl + "/download", parameters: getRequestParameters())
	}
	
	public var downloadUrl: Observable<String?>? {
		guard let url = downloadResourceUrl, request = httpClient.httpUtilities.createUrlRequest(url, headers: getRequestHeaders()) else {
			return nil
		}
		
		return Observable.create { [unowned self] observer in
			let task = self.httpClient.loadJsonData(request).bindNext { result in
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
}