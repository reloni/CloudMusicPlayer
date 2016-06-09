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
	internal var downloadUrlErrorRetryDelayTime: Double = 1
	internal var downloadUrlRetryMaxAttemptCount = 5
	
	internal var downloadResourceUrl: NSURL? {
		return NSURL(baseUrl: resourcesUrl + "/download", parameters: getRequestParameters())
	}
	
	public var downloadUrl: Observable<String> {
		guard let url = downloadResourceUrl else {
			return Observable.empty()
		}
		
		let request = httpClient.httpUtilities.createUrlRequest(url, headers: getRequestHeaders())
		return Observable.create { [weak self] observer in
			guard let object = self else { observer.onCompleted(); return NopDisposable.instance }
			
			let task = object.httpClient.loadJsonData(request).flatMapLatest { result -> Observable<String?> in
				if case Result.success(let box) = result {
					// check server side error
					if let error = object.checkError(box.value) { return Observable.error(error) }
					
					if let href = box.value["href"].string {
						return Observable.just(href)
					}
				} else if case Result.error(let error) = result {
					return Observable.error(error)
				}
				// if no error returned and no href key in JSON, return nil
				return Observable.just(nil)
				}.retryWithDelay(object.downloadUrlErrorRetryDelayTime, maxAttemptCount: object.downloadUrlRetryMaxAttemptCount, retryReturnObject: "") { error in
				if case YandexDiskError.tooManyRequests = error {
					return true
				}
				return false
				}.doOnError { _ in observer.onCompleted() }.bindNext { link in
					guard let link = link else { observer.onCompleted(); return }
					observer.onNext(link)
					observer.onCompleted()
			}
			
			return AnonymousDisposable {
				task.dispose()
			}
		}
	}
}