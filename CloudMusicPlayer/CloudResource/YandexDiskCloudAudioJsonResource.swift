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
		return Observable.create { [weak self] observer in
			guard let object = self else { observer.onCompleted(); return NopDisposable.instance }
			/*
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
			*/
			
			let concurrentScheduler = ConcurrentDispatchQueueScheduler(globalConcurrentQueueQOS: DispatchQueueSchedulerQOS.Utility)
			let serialScheduler = SerialDispatchQueueScheduler(globalConcurrentQueueQOS: DispatchQueueSchedulerQOS.Utility)
			var retryCounter = 0
			
			// perform request for downloadurl
			// if Yandex server returned error "tooManyRequests"
			// sleep and try again
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
				} // retries if error occurred
				.retryWhen { (error: Observable<ErrorType>) -> Observable<JSON> in
					return error.observeOn(serialScheduler).flatMapLatest { returnedError -> Observable<JSON> in
						// if server returned error "tooManyRequests", perform retry after delay
						if case YandexDiskError.tooManyRequests = returnedError where retryCounter < 5 {
							retryCounter += 1
							return Observable.just(JSON([])).delaySubscription(1, scheduler: concurrentScheduler)
						}
						return Observable.error(returnedError)
					}
				}.catchError { _ in observer.onCompleted(); return Observable.empty() }
				.bindNext { link in
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