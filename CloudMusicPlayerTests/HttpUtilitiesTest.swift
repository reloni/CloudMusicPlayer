//
//  HttpUtilitiesTest.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 15.03.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import XCTest
import CloudMusicPlayer

class HttpUtilitiesTest: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testCreateNSMutableURLRequest() {
			let req = HttpUtilities.instance.createUrlRequest("https://test.com", parameters: ["param1": "value1"]) as? NSMutableURLRequest
			XCTAssertNotNil(req, "Should return instance of NSMutableURLRequest")
			XCTAssertEqual("https://test.com?param1=value1", req?.URL?.URLString, "Should create request with correct url")
    }
}
