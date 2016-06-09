//
//  Observable+retryWhenWithDelayTests.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 09.06.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import XCTest
import RxSwift
import CloudMusicPlayer

enum CustomError : ErrorType {
	case someError
	case someReallyBadError
}

class Observable_retryWhenWithDelayTests: XCTestCase {
	var bag: DisposeBag!
	
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
		bag = DisposeBag()
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
	}
	
	func testNotRetriesIfNoError() {
		var retriesCount = 0
		let observable = Observable<Int>.create { observer in
			retriesCount += 1
			observer.onNext(1)
			observer.onNext(2)
			observer.onNext(3)
			observer.onCompleted()
			return NopDisposable.instance
		}
		
		let expectation = expectationWithDescription("Should complete observable once")
		observable.retryWithDelay(0.1, maxAttemptCount: 5, retryReturnObject: 1) { _ in return true }
			.doOnCompleted { expectation.fulfill() }.subscribe().addDisposableTo(bag)
		
		waitForExpectationsWithTimeout(1, handler: nil)
		XCTAssertEqual(1, retriesCount, "Should invoke observable only once cause there are no errors")
	}
	
	func testRetriesCorrectAmountOfTimes() {
		var retriesCount = 0
		let observable = Observable<Int>.create { observer in
			retriesCount += 1
			observer.onNext(1)
			observer.onNext(2)
			observer.onNext(3)
			observer.onError(CustomError.someError)
			observer.onCompleted()
			return NopDisposable.instance
		}
		
		let expectation = expectationWithDescription("Should complete observable with error")
		observable.retryWithDelay(0.005, maxAttemptCount: 5, retryReturnObject: 1) { _ in return true }
			.doOnError { _ in expectation.fulfill() }.subscribe().addDisposableTo(bag)
		
		waitForExpectationsWithTimeout(1, handler: nil)
		XCTAssertEqual(6, retriesCount, "Check invokes observable correct amount of times (once normal and five retries)")
	}
	
	func testRetriesOnlyOnParticularError() {
		var retriesCount = 0
		let observable = Observable<Int>.create { observer in
			retriesCount += 1
			observer.onNext(1)
			observer.onNext(2)
			observer.onNext(3)
			if retriesCount < 4 {
				observer.onError(CustomError.someReallyBadError)
			} else {
				observer.onError(CustomError.someError)
			}
			observer.onCompleted()
			return NopDisposable.instance
		}
		
		let expectation = expectationWithDescription("Should complete observable with error")
		observable.retryWithDelay(0.005, maxAttemptCount: 5, retryReturnObject: 1) { error in
			if case CustomError.someReallyBadError = error {return true }
			return false
		}.doOnError { _ in expectation.fulfill() }.subscribe().addDisposableTo(bag)
		
		waitForExpectationsWithTimeout(1, handler: nil)
		XCTAssertEqual(4, retriesCount, "Check retries observable only when particular error occurred")
	}
}
