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

extension JSON {
	public static func getJsonFromFile(fileName: String) -> JSON? {
		guard let path = NSBundle(forClass: CloudResourceTests.self).pathForResource(fileName, ofType: "json"),
			dataStr = try? String(contentsOfFile: path), let data = dataStr.dataUsingEncoding(NSUTF8StringEncoding)else { return nil }
		
		return JSON(data: data)
	}
	
	public func rawDataSafe() -> NSData? {
		return try? rawData()
	}
}

class CloudResourceTests: XCTestCase {
	var bag: DisposeBag!
	var request: FakeRequest!
	var session: FakeSession!
	var utilities: FakeHttpUtilities!
	
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
		
		bag = DisposeBag()
		request = FakeRequest()
		session = FakeSession(fakeTask: FakeDataTask(completion: nil))
		utilities = FakeHttpUtilities()
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
		bag = nil
		request = nil
		session = nil
		utilities = nil
	}
	
	func testCreateRequest() {
		let oAuth = OAuthResourceBase(id: "fake", authUrl: "http://test.com", clientId: nil, tokenId: "authToken")
		let req = YandexDiskCloudJsonResource.createRequestForLoadRootResources(oAuth, httpUtilities: utilities) as? FakeRequest
		XCTAssertNotNil(req, "Should create request")
		XCTAssertEqual(NSURL(baseUrl: YandexDiskCloudJsonResource.resourcesApiUrl, parameters: ["path": "/"]), req?.URL, "Should create correct url")
		XCTAssertEqual("authToken", req?.headers["Authorization"], "Should set one header with correct token")
	}
	
	func testLoadRootData() {
		session.task?.taskProgress.bindNext { progress in
			if case .resume(let tsk) = progress {
				let json = JSON.getJsonFromFile("YandexRoot")
				dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
					tsk.completion?(json?.rawDataSafe(), nil, nil)
				}
			}
			}.addDisposableTo(bag)
		
		let expectation = expectationWithDescription("Should return correct json data from YandexRoot file")
		let fakeRes = FakeCloudResource(oaRes: OAuthResourceBase(id: "fake", authUrl: "fake", clientId: nil, tokenId: nil))
		fakeRes.resourcesUrl = "https://test.com"
		
		let oAuth = OAuthResourceBase(id: "fake", authUrl: "http://test.com", clientId: nil, tokenId: "token")
		YandexDiskCloudJsonResource.loadRootResources(oAuth, httpRequest: HttpRequest.instance, session: session, httpUtilities: utilities)?.bindNext { result in
			if case .Success(let json) = result where json?.count == 9 {
				expectation.fulfill()
			}
		}.addDisposableTo(bag)
		
		waitForExpectationsWithTimeout(1, handler: nil)
	}
	
//	func testPaths() {
//		
//		print(NSBundle(forClass: self.dynamicType).pathForResource("test", ofType: "txt"))
//		print(NSBundle(forClass: self.dynamicType).pathForResource("test", ofType: "txt", inDirectory: "/CloudMusicPlayerTests/JsonFiles"))
//		print(NSBundle(forClass: self.dynamicType).pathForResource("test", ofType: "txt", inDirectory: NSBundle(forClass: self.dynamicType).resourcePath! + "/CloudMusicPlayerTests/JsonFiles"))
//		print(NSBundle(forClass: self.dynamicType).resourcePath)
//		print(NSBundle(forClass: self.dynamicType).executablePath)
//	}
	
//	func testGetJSONData() {
//		let bag = DisposeBag()
//		let request = FakeRequest()
//		let expectation = expectationWithDescription("Should return json data")
//		let session = FakeSession()
//		let task = (session.dataTaskWithRequest(request) { data, response, error in
//			if let data = data {
//				print(JSON(data: data))
//				expectation.fulfill()
//			}
//			}) as! FakeDataTask
//		
//		task.taskProgress.bindNext { progress in
//			if case .resume(let task) = progress {
//				let json: JSON =  ["name": "Jack", "age": 25]
//				dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
//					task.completion?(try? json.rawData(), nil, nil)
//				}
//			}
//			}.addDisposableTo(bag)
//		
//		task.resume()
//		
//		waitForExpectationsWithTimeout(2, handler: nil)
//	}
	
//	func test() {
//		guard let url = NSURL(baseUrl: "https://cloud-api.yandex.net:443/v1/disk/resources", parameters: ["path": "disk:/Скриншоты"]) else { return }
//		print(url)
//		let req = NSMutableURLRequest(URL: url)
//		req.addValue(OAuthResourceManager.getYandexResource().tokenId!, forHTTPHeaderField: "Authorization")
//		let task = NSURLSession.sharedSession().dataTaskWithRequest(req) { data, response, error in
//			if let data = data {
//				print(JSON(data: data))
//			}
//		} as NSURLSessionDataTask
//		task.resume()
//		sleep(4)
//	}
}
