//
//  YandexDiskCloudMediaJsonResource.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 27.02.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import SwiftyJSON
import RxSwift

public class YandexDiskCloudAudioJsonResource : YandexDiskCloudJsonResource, CloudAudioResource {
	internal var downloadResourceUrl: NSURL? {
		return NSURL(baseUrl: resourcesUrl + "/download", parameters: getRequestParameters())
	}
	
	public var downloadUrl: Observable<String> {
		guard let url = downloadResourceUrl else {
			return Observable.empty()
		}
		
		let request = httpClient.httpUtilities.createUrlRequest(url, headers: getRequestHeaders())
		return Observable.create { [unowned self] observer in
			let task = self.httpClient.loadJsonData(request)
				.doOnCompleted { _ in observer.onCompleted() }.bindNext { result in
					if case Result.success(let box) = result {
						if let href = box.value["href"].string {
							observer.onNext(href)
						}
					} else if case Result.error(let error) = result {
						print("yandex file url error: \(error)")
						observer.onCompleted()
					}
			}
			
			return AnonymousDisposable {
				task.dispose()
			}
		}
	}
}