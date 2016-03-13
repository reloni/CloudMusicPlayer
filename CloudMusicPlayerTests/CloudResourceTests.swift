//
//  CloudResourceTests.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 13.03.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import XCTest
import SwiftyJSON
import CloudMusicPlayer

class CloudResourceTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
	
//	func testGetJSONData() {
//		guard let token = OAuthResourceManager.getYandexResource().tokenId else {
//			return
//		}
//		let request = NSMutableURLRequest(URL: NSURL(string: "https://cloud-api.yandex.net:443/v1/disk/resources?path=%2F")!)
//		request.addValue(token, forHTTPHeaderField: "Authorization")
//		
//		let expectation = expectationWithDescription("Should return json data")
//		let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { data, response, error in
//			if let data = data {
//				print(JSON(data: data))
//				expectation.fulfill()
//			}
//		}
//		task.resume()
//		waitForExpectationsWithTimeout(5, handler: nil)
//	}
}
