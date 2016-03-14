//
//  CloudResourceTests.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 13.03.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import XCTest
import SwiftyJSON
@testable import CloudMusicPlayer
import RxSwift



class CloudResourceTests: XCTestCase {
	
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
	}
	
	func testGetJSONData() {
		let bag = DisposeBag()
		let request = FakeRequest()
		let expectation = expectationWithDescription("Should return json data")
		let session = FakeSession()
		let task = (session.dataTaskWithRequest(request) { data, response, error in
			if let data = data {
				print(JSON(data: data))
				expectation.fulfill()
			}
			}) as! FakeDataTask
		
		task.taskProgress.bindNext { progress in
			if case .resume(let task) = progress {
				let json: JSON =  ["name": "Jack", "age": 25]
				dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
					task.completion?(try? json.rawData(), nil, nil)
				}
			}
			}.addDisposableTo(bag)
		
		task.resume()
		
		waitForExpectationsWithTimeout(2, handler: nil)
	}
}
