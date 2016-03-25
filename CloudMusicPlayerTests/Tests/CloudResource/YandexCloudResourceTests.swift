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
		guard let path = NSBundle(forClass: YandexCloudResourceTests.self).pathForResource(fileName, ofType: "json"),
			dataStr = try? String(contentsOfFile: path), let data = dataStr.dataUsingEncoding(NSUTF8StringEncoding)else { return nil }
		
		return JSON(data: data)
	}
	
	public func rawDataSafe() -> NSData? {
		return try? rawData()
	}
}

class YandexCloudResourceTests: XCTestCase {
	var bag: DisposeBag!
	var request: FakeRequest!
	var session: FakeSession!
	var utilities: FakeHttpUtilities!
	var oauthResource: OAuthResourceBase!
	var httpClient: HttpClientProtocol!
	
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
		
		bag = DisposeBag()
		request = FakeRequest()
		session = FakeSession(fakeTask: FakeDataTask(completion: nil))
		utilities = FakeHttpUtilities()
		httpClient = HttpClient(urlSession: session, httpUtilities: utilities)
		oauthResource = OAuthResourceBase(id: "fakeOauthResource", authUrl: "https://fakeOauth.com", clientId: "fakeClientId", tokenId: "fakeTokenId")
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
		let req = YandexDiskCloudJsonResource.createRequestForLoadRootResources(oauthResource, httpUtilities: utilities) as? FakeRequest
		XCTAssertNotNil(req, "Should create request")
		XCTAssertEqual(NSURL(baseUrl: YandexDiskCloudJsonResource.resourcesApiUrl, parameters: ["path": "/"]), req?.URL, "Should create correct url")
		XCTAssertEqual(oauthResource.tokenId, req?.headers["Authorization"], "Should set one header with correct token")
	}
	
	func testNotCreateRequest() {
		let oauthResWithoutTokenId = OAuthResourceBase(id: "fake", authUrl: "https://fake.com", clientId: nil, tokenId: nil)
		let req = YandexDiskCloudJsonResource.createRequestForLoadRootResources(oauthResWithoutTokenId, httpUtilities: utilities) as? FakeRequest
		XCTAssertNil(req, "Should not create request")
	}
	
	func testDeserializeJsonResponseFolder() {
		let first = YandexDiskCloudJsonResource.deserializeResponseData(JSON.getJsonFromFile("YandexRoot"), res: oauthResource)?.first
		XCTAssertNotNil(first)
		XCTAssertEqual(first?.name, "Documents")
		XCTAssertEqual(first?.path, "disk:/Documents")
		XCTAssertEqual(first?.type, "dir")
		XCTAssertTrue(first is YandexDiskCloudJsonResource)
		XCTAssertNil(first?.parent)
		XCTAssertNil(first?.mediaType)
		XCTAssertNil(first?.mimeType)
		XCTAssertEqual(oauthResource.id, first?.oAuthResource.id)
		XCTAssertEqual((first?.getRequestHeaders())!, ["Authorization": oauthResource.tokenId!])
		XCTAssertEqual((first?.getRequestParameters())!, ["path": first!.path])
	}
	
	func testNotDeserializeIncorrectJson() {
		let json: JSON =  ["Test": "Value"]
		let response = YandexDiskCloudJsonResource.deserializeResponseData(json, res: oauthResource)
		XCTAssertNil(response)
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

		YandexDiskCloudJsonResource.loadRootResources(oauthResource, httpRequest: httpClient)?.bindNext { result in
			if case .Success(let json) = result where json?.count == 9 {
				expectation.fulfill()
			}
		}.addDisposableTo(bag)
		
		waitForExpectationsWithTimeout(1, handler: nil)
	}
	
	func testNotCreateRequestForLoadRootDataForOauthResourceWithoutTokenId() {
		let oauthResWithoutTokenId = OAuthResourceBase(id: "fake", authUrl: "https://fake.com", clientId: nil, tokenId: nil)
		let loadRequest = YandexDiskCloudJsonResource.loadRootResources(oauthResWithoutTokenId, httpRequest: HttpClient.instance)
		XCTAssertNil(loadRequest)
	}
	
	func testErrorWhileLoadRootData() {
		session.task?.taskProgress.bindNext { progress in
			if case .resume(let tsk) = progress {
				dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
					tsk.completion?(nil, nil, NSError(domain: "TestDomain", code: 1, userInfo: nil))
				}
			}
			}.addDisposableTo(bag)
		
		let expectation = expectationWithDescription("Should return error")
		
		YandexDiskCloudJsonResource.loadRootResources(oauthResource, httpRequest: httpClient)?.bindNext { result in
			if case .Error(let error) = result where error?.code == 1 {
				expectation.fulfill()
			}
			}.addDisposableTo(bag)
		
		waitForExpectationsWithTimeout(1, handler: nil)
	}
	
	func testTerminateWhileLoadRootData() {
		let expectation = expectationWithDescription("Should suspend task")
		
		session.task?.taskProgress.bindNext { progress in
			if case .resume(_) = progress {
				dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
					for _ in 0...10 {
						sleep(1)
					}
				}
			} else if case .suspend(_) = progress {
				expectation.fulfill()
			}
		}.addDisposableTo(bag)
		
		let request = YandexDiskCloudJsonResource.loadRootResources(oauthResource, httpRequest: httpClient)?
			.bindNext { _ in
		}
		request?.dispose()
		
		waitForExpectationsWithTimeout(1, handler: nil)
	}
	
	func testLoadChilds() {
		let expectation = expectationWithDescription("Should return childs")
		
		guard let rootItem = JSON.getJsonFromFile("YandexMusicDirItem") else {
			waitForExpectationsWithTimeout(1, handler: nil)
			return
		}
		let item = YandexDiskCloudJsonResource(raw: rootItem, oAuthResource: oauthResource, parent: nil, httpClient: httpClient)
		
		session.task?.taskProgress.bindNext { progress in
			if case .resume(let tsk) = progress {
				XCTAssertEqual(NSURL(baseUrl: item.resourcesUrl, parameters: item.getRequestParameters())?.absoluteString, tsk.originalRequest?.URL?.absoluteString, "Check invoke url")
				let json = JSON.getJsonFromFile("YandexMusicFolderContents")
				dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
					tsk.completion?(json?.rawDataSafe(), nil, nil)
				}
			}
		}.addDisposableTo(bag)
		
		var loadedChilds: [CloudResource]?
		
		item.loadChilds()?.bindNext { result in
			if case .Success(let childs) = result {
				loadedChilds = childs
				expectation.fulfill()
			}
		}.addDisposableTo(bag)
		
		waitForExpectationsWithTimeout(1) { result in
			if result != nil { return }
			
			XCTAssertNotNil(loadedChilds)
			XCTAssertEqual(4, loadedChilds?.count)
			
			let first = loadedChilds?.first
			XCTAssertEqual(first?.name, "David Arkenstone")
			XCTAssertEqual(first?.path, "disk:/Music/David Arkenstone")
			XCTAssertEqual(first?.type, "dir")
			XCTAssertTrue(first is YandexDiskCloudJsonResource)
			
			let audioItem = loadedChilds?.last as? CloudAudioResource
			XCTAssertEqual(audioItem?.name, "TestTrack.mp3")
			XCTAssertEqual(audioItem?.path, "disk:/Music/TestTrack.mp3")
			XCTAssertEqual(audioItem?.type, "file")
			XCTAssertTrue(audioItem is YandexDiskCloudAudioJsonResource)
		}
	}
	
	func testGetDownloadUrl() {
		let expectation = expectationWithDescription("Should return download url")
		
		guard let audioItem = JSON.getJsonFromFile("YandexAudioItem"),
			sendJson = JSON.getJsonFromFile("YandexAudioDownloadResponse"), href = sendJson["href"].string else {
				waitForExpectationsWithTimeout(1, handler: nil)
				return
		}
		let item = YandexDiskCloudAudioJsonResource(raw: audioItem, oAuthResource: oauthResource, parent: nil, httpClient: httpClient)
		
		session.task?.taskProgress.bindNext { progress in
			if case .resume(let tsk) = progress {
				XCTAssertEqual(item.downloadResourceUrl, tsk.originalRequest?.URL, "Check invoke url")
				dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
					tsk.completion?(sendJson.rawDataSafe(), nil, nil)
				}
			}
			}.addDisposableTo(bag)
		
		item.downloadUrl?.bindNext { result in
			if result == href {
				expectation.fulfill()
			}
		}.addDisposableTo(bag)
		
		waitForExpectationsWithTimeout(1, handler: nil)
	}
	
	func testNotReturnDownloadUrl() {
		let expectation = expectationWithDescription("Should not return download url")
		
		guard let audioItem = JSON.getJsonFromFile("YandexAudioItem"),
			sendJson = JSON.getJsonFromFile("YandexAudioDownloadResponse") else {
				waitForExpectationsWithTimeout(1, handler: nil)
				return
		}
		
		let item = YandexDiskCloudAudioJsonResource(raw: audioItem, oAuthResource: oauthResource, parent: nil, httpClient: httpClient)
		
		session.task?.taskProgress.bindNext { progress in
			if case .resume(let tsk) = progress {
				XCTAssertEqual(item.downloadResourceUrl, tsk.originalRequest?.URL, "Check invoke url")
				dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
					var sendingJson = sendJson
					// modify href, so it will not return
					sendingJson["href"] = nil
					tsk.completion?(sendingJson.rawDataSafe(), nil, nil)
				}
			}
			}.addDisposableTo(bag)
		
		item.downloadUrl?.bindNext { result in
			if result == nil {
				expectation.fulfill()
			}
		}.addDisposableTo(bag)
		
		waitForExpectationsWithTimeout(1, handler: nil)
	}
}
