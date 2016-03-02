//
//  DeinitTest.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 02.03.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

public class testClass {
	private static var tasks = [String: testClass]()
	public static func newTask() -> Observable<Int> {
		let task = testClass()
		task.latestReceivedData.bindNext { data in
			if data == 2 {
				tasks.removeValueForKey("a")
			}
		}.addDisposableTo(task.bag)
		testClass.tasks["a"] = task
		return task.latestReceivedData
	}
	public static func push(data: Int) {
		tasks["a"]?.latestReceivedData.onNext(data)
	}
	
	private var bag = DisposeBag()
	private var latestReceivedData = PublishSubject<Int>()
	
	deinit {
		print("deinit")
	}
}