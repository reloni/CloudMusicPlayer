//
//  Observable+retryWhenWithDelay.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 09.06.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import RxSwift

extension Observable {
	///Repeats observable if error occurred with specified delay time
	public func retryWithDelay(delayTime: Double, maxAttemptCount: Int, retryReturnObject: Observable.E, errorEvaluator: (ErrorType) -> Bool) -> Observable<Observable.E> {
		var retryCounter = 0
		let serialScheduler = SerialDispatchQueueScheduler(globalConcurrentQueueQOS: DispatchQueueSchedulerQOS.Utility)
		return retryWhen { (error: Observable<ErrorType>) -> Observable<Observable.E> in
			return error.observeOn(serialScheduler).flatMapLatest { returnedError -> Observable<Observable.E> in
				if errorEvaluator(returnedError) && retryCounter < maxAttemptCount {
					retryCounter += 1
					return Observable.just(retryReturnObject).delaySubscription(delayTime, scheduler: ConcurrentDispatchQueueScheduler(globalConcurrentQueueQOS: DispatchQueueSchedulerQOS.Utility))
				}
				return Observable.error(returnedError)
			}
		}
	}
}