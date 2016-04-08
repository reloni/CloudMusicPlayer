//
//  RxShit.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 08.04.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import XCTest
import RxSwift

class RxShit: XCTestCase {
	
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
	}
	
	func testShitCallback() {
		var someShit: SomeClass? = SomeClass()
		let bag = DisposeBag()
		someShit?.rx_observe2().bindNext { e in
			print(e)
		}.addDisposableTo(bag)
		
		someShit?.test1()
		someShit?.test2()
		someShit = nil
		someShit?.test2()
	}
}

class CallbackTarget<T> {
	typealias Callback = (T) -> ()
	let object: T
	let callback: Callback
	init(target: T, callback: Callback) {
		object = target
		self.callback = callback
	}
}

enum SomeEvents {
	case Event1
	case Event2(String)
}

class SomeClass {
	internal var callback: ((SomeEvents) -> ())?
	
	let subject = PublishSubject<SomeEvents>()
	
	internal func test1() {
		callback?(SomeEvents.Event1)
		subject.onNext(SomeEvents.Event1)
	}
	
	internal func test2() {
		callback?(SomeEvents.Event2("some string"))
		subject.onNext(SomeEvents.Event2("shit"))
	}
	
	deinit {
		print("shit deinit")
	}
	
	func rx_observe2() -> Observable<SomeEvents> {
		return Observable.create { [weak self] observer in
			guard let object = self else { observer.onCompleted(); return NopDisposable.instance }
			
			return object.subject.subscribe(observer)
		}
	}
	
	func rx_observe() -> Observable<SomeEvents> {
		return Observable.create { [weak self] observer in
			guard let object = self else { observer.onCompleted(); return NopDisposable.instance }
			
			object.callback = { e in
				observer.onNext(e)
			}
			
			return NopDisposable.instance
		}
	}
}


