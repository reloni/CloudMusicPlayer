//
//  RxTests.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 28.04.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import XCTest
import RxSwift
import RxBlocking

class RxTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
	
	let subject = PublishSubject<Int>()
	let subject2 = PublishSubject<Int>()
	lazy var events: Observable<Int> = { [unowned self] in
		return Observable.create { observer in
			let disposable = self.subject.subscribe(observer)
			let disposable2 = self.subject2.subscribe(observer)
			return AnonymousDisposable {
				disposable.dispose()
				disposable2.dispose()
			}
		}.shareReplay(0)
	}()
	
	func testShit() {
		//let subject = PublishSubject<Int>()

		let bag = DisposeBag()
		let last = 1000
		var sended = 0
		
		let scheduler = SerialDispatchQueueScheduler(globalConcurrentQueueQOS: DispatchQueueSchedulerQOS.Utility)
		var firstCounter = 0
		subject.observeOn(scheduler).bindNext { i in
			firstCounter += i
			}.addDisposableTo(bag)
		
		var secondCounter = 0
		subject.observeOn(scheduler).bindNext { i in
			secondCounter += i
			}.addDisposableTo(bag)
		
		for _ in 0...last {
			dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
				sended += 1
				self.subject.onNext(1)
			}
			dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
				sended += 1
				self.subject2.onNext(1)
			}
		}
		
		NSThread.sleepForTimeInterval(5)
		
		XCTAssertEqual(sended, firstCounter * 2)
		XCTAssertEqual(sended, secondCounter * 2)
	}

}
