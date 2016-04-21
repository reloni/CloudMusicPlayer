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
		XCTAssertNil(first?.parent)
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
			if result.count == 9 {
				expectation.fulfill()
			}
		}.addDisposableTo(bag)
		
		waitForExpectationsWithTimeout(1, handler: nil)
	}
	
	func testNotCreateRequestForLoadRootDataForOauthResourceWithoutTokenId() {
		let oauthResWithoutTokenId = OAuthResourceBase(id: "fake", authUrl: "https://fake.com", clientId: nil, tokenId: nil)
		let loadRequest = YandexDiskCloudJsonResource.loadRootResources(oauthResWithoutTokenId, httpRequest: HttpClient())
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
		
		YandexDiskCloudJsonResource.loadRootResources(oauthResource, httpRequest: httpClient)?.doOnError { error in
			if (error as NSError).code == 1 {
				expectation.fulfill()
			}
		}.subscribe().addDisposableTo(bag)
		
		waitForExpectationsWithTimeout(1, handler: nil)
	}
	
	func testTerminateWhileLoadRootData() {
		let expectation = expectationWithDescription("Should cancel task")
		
		session.task?.taskProgress.bindNext { progress in
			if case .resume(_) = progress {
				dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
					for _ in 0...10 {
						sleep(1)
					}
				}
			} else if case .cancel(_) = progress {
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
		
		item.loadChildResources().bindNext { childs in
			loadedChilds = childs
			expectation.fulfill()
			}.addDisposableTo(bag)
		
		waitForExpectationsWithTimeout(1, handler: nil)
		
		XCTAssertNotNil(loadedChilds)
		XCTAssertEqual(4, loadedChilds?.count)
		
		let first = loadedChilds?.first
		XCTAssertEqual(first?.name, "David Arkenstone")
		XCTAssertEqual(first?.path, "disk:/Music/David Arkenstone")
		XCTAssertEqual(first?.type, "dir")
		XCTAssertTrue(first is YandexDiskCloudJsonResource)
		XCTAssertEqual(item.uid, first?.parent?.uid)
		
		let audioItem = loadedChilds?.last as? CloudAudioResource
		XCTAssertEqual(audioItem?.name, "TestTrack.mp3")
		XCTAssertEqual(audioItem?.path, "disk:/Music/TestTrack.mp3")
		XCTAssertEqual(audioItem?.type, "file")
		XCTAssertTrue(audioItem is YandexDiskCloudAudioJsonResource)
		XCTAssertEqual(item.uid, audioItem?.parent?.uid)
	}
	
	func testReceiveErrorWhileLoadingChilds() {
		let expectation = expectationWithDescription("Should receive error")
		
		guard let rootItem = JSON.getJsonFromFile("YandexMusicDirItem") else {
			XCTFail("Fail to load json from file")
			return
		}
		let item = YandexDiskCloudJsonResource(raw: rootItem, oAuthResource: oauthResource, parent: nil, httpClient: httpClient)
		
		session.task?.taskProgress.bindNext { progress in
			if case .resume(let tsk) = progress {
				dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
					tsk.completion?(nil, nil, NSError(domain: "TestDomain", code: 1, userInfo: nil))
				}
			}
			}.addDisposableTo(bag)
		
		item.loadChildResources().doOnError { error in
			XCTAssertEqual((error as NSError).code, 1)
			expectation.fulfill()
		}.subscribe().addDisposableTo(bag)
		
		waitForExpectationsWithTimeout(1, handler: nil)
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
	
	func testLoadCachedChilds() {
		let actualChildsexpectation = expectationWithDescription("Should return actual childs")
		let cachedChildsExpectation = expectationWithDescription("Should return cached childs")
		
		guard let rootItem = JSON.getJsonFromFile("YandexMusicDirItem") else {
			waitForExpectationsWithTimeout(1, handler: nil)
			return
		}
		
		let cachedJson = try! JSON.getJsonFromFile("YandexMusicFolderContents_Cached")?.rawData()
		let fakeUserDefaults = FakeNSUserDefaults(localCache: [CloudResourceNsUserDefaultsCacheProvider.userDefaultsId: [rootItem["path"].stringValue: cachedJson!]])
		let cacheProvider = CloudResourceNsUserDefaultsCacheProvider(loadData: true, userDefaults: fakeUserDefaults)
		let item = YandexDiskCloudJsonResource(raw: rootItem, oAuthResource: oauthResource, parent: nil, httpClient: httpClient, cacheProvider: cacheProvider)
		
		session.task?.taskProgress.bindNext { progress in
			if case .resume(let tsk) = progress {
				XCTAssertEqual(NSURL(baseUrl: item.resourcesUrl, parameters: item.getRequestParameters())?.absoluteString, tsk.originalRequest?.URL?.absoluteString,
					"Check invoke url")
				let json = JSON.getJsonFromFile("YandexMusicFolderContents")
				dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
					tsk.completion?(json?.rawDataSafe(), nil, nil)
				}
			}
			}.addDisposableTo(bag)
		
		var loadedChilds: [CloudResource]?
		var cachedChilds: [CloudResource]?
		
		var responseCount = 0
		
		item.loadChildResources().bindNext { childs in
			if responseCount == 0 {
				// first responce should be with locally cached data
				cachedChilds = childs
				responseCount += 1
				cachedChildsExpectation.fulfill()
			} else if responseCount == 1 {
				// second responce should be with actual data
				loadedChilds = childs
				responseCount += 1
				actualChildsexpectation.fulfill()
			}
			}.addDisposableTo(bag)
		
		waitForExpectationsWithTimeout(1, handler: nil)
		
		// check cached items
		XCTAssertNotNil(cachedChilds)
		XCTAssertEqual(2, cachedChilds?.count)
		
		var first = cachedChilds?.first
		XCTAssertEqual(first?.name, "Apocalyptica")
		XCTAssertEqual(first?.path, "disk:/Music/Apocalyptica")
		XCTAssertEqual(first?.type, "dir")
		XCTAssertTrue(first is YandexDiskCloudJsonResource)
		XCTAssertEqual(item.uid, first?.parent?.uid)
		XCTAssertTrue((first as! YandexDiskCloudJsonResource).cacheProvider as! CloudResourceNsUserDefaultsCacheProvider === cacheProvider)
		
		var audioItem = cachedChilds?.last as? CloudAudioResource
		XCTAssertEqual(audioItem?.name, "CachedTrack.mp3")
		XCTAssertEqual(audioItem?.path, "disk:/Music/CachedTrack.mp3")
		XCTAssertEqual(audioItem?.type, "file")
		XCTAssertTrue(audioItem is YandexDiskCloudAudioJsonResource)
		XCTAssertEqual(item.uid, audioItem?.parent?.uid)
		XCTAssertTrue((audioItem as! YandexDiskCloudJsonResource).cacheProvider as! CloudResourceNsUserDefaultsCacheProvider === cacheProvider)
		
		// check loaded items
		XCTAssertNotNil(loadedChilds)
		XCTAssertEqual(4, loadedChilds?.count)
		
		first = loadedChilds?.first
		XCTAssertEqual(first?.name, "David Arkenstone")
		XCTAssertEqual(first?.path, "disk:/Music/David Arkenstone")
		XCTAssertEqual(first?.type, "dir")
		XCTAssertTrue(first is YandexDiskCloudJsonResource)
		XCTAssertEqual(item.uid, first?.parent?.uid)
		XCTAssertTrue((first as! YandexDiskCloudJsonResource).cacheProvider as! CloudResourceNsUserDefaultsCacheProvider === cacheProvider)
		
		audioItem = loadedChilds?.last as? CloudAudioResource
		XCTAssertEqual(audioItem?.name, "TestTrack.mp3")
		XCTAssertEqual(audioItem?.path, "disk:/Music/TestTrack.mp3")
		XCTAssertEqual(audioItem?.type, "file")
		XCTAssertTrue(audioItem is YandexDiskCloudAudioJsonResource)
		XCTAssertEqual(item.uid, audioItem?.parent?.uid)
		XCTAssertTrue((audioItem as! YandexDiskCloudJsonResource).cacheProvider as! CloudResourceNsUserDefaultsCacheProvider === cacheProvider)		
	}
	
	func testLoadAndCacheChilds() {
		let expectation = expectationWithDescription("Should return childs")
		
		guard let rootItem = JSON.getJsonFromFile("YandexMusicDirItem") else {
			XCTFail("Failed to load json data")
			return
		}
		
		let fakeUserDefaults = FakeNSUserDefaults()
		let cacheProvider = CloudResourceNsUserDefaultsCacheProvider(loadData: true, userDefaults: fakeUserDefaults)
		let item = YandexDiskCloudJsonResource(raw: rootItem, oAuthResource: oauthResource, parent: nil, httpClient: httpClient, cacheProvider: cacheProvider)
		
		session.task?.taskProgress.bindNext { progress in
			if case .resume(let tsk) = progress {
				XCTAssertEqual(NSURL(baseUrl: item.resourcesUrl, parameters: item.getRequestParameters())?.absoluteString, tsk.originalRequest?.URL?.absoluteString, "Check invoke url")
				let json = JSON.getJsonFromFile("YandexMusicFolderContents")
				dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
					tsk.completion?(json?.rawDataSafe(), nil, nil)
				}
			}
			}.addDisposableTo(bag)
		
		item.loadChildResources().bindNext { _ in
			expectation.fulfill()
			}.addDisposableTo(bag)
		
		waitForExpectationsWithTimeout(1, handler: nil)
		
		guard let cachedData = (fakeUserDefaults.localCache.first?.1 as? [String: NSData])?.first?.1 else {
			XCTFail("Data not cached")
			return
		}
		
		XCTAssertEqual(JSON.getJsonFromFile("YandexMusicFolderContents"), JSON(data: cachedData), "Sended json should be same as cached")
	}
	
	func testCacheRootResources() {
		let expectation = expectationWithDescription("Should return childs")
		
		let fakeUserDefaults = FakeNSUserDefaults()
		let cacheProvider = CloudResourceNsUserDefaultsCacheProvider(loadData: true, userDefaults: fakeUserDefaults)
		
		session.task?.taskProgress.bindNext { progress in
			if case .resume(let tsk) = progress {
				let json = JSON.getJsonFromFile("YandexRoot")
				dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
					tsk.completion?(json?.rawDataSafe(), nil, nil)
				}
			}
			}.addDisposableTo(bag)
		
		YandexDiskCloudJsonResource.loadRootResources(oauthResource, httpRequest: httpClient, cacheProvider: cacheProvider)?.bindNext { _ in
			expectation.fulfill()
		}.addDisposableTo(bag)
		
		waitForExpectationsWithTimeout(1, handler: nil)
		
		guard let cachedData = (fakeUserDefaults.localCache.first?.1 as? [String: NSData])?.first?.1 else {
			XCTFail("Data not cached")
			return
		}
		
		XCTAssertEqual(JSON.getJsonFromFile("YandexRoot"), JSON(data: cachedData), "Sended json should be same as cached")
	}
	
	func testLoadCachedRootData() {
		let actualRootsexpectation = expectationWithDescription("Should return actual root items")
		let cachedRootExpectation = expectationWithDescription("Ahould return cached root items")
		
		let cachedJson = try! JSON.getJsonFromFile("YandexRoot")?.rawData()
		let fakeUserDefaults = FakeNSUserDefaults(localCache: [CloudResourceNsUserDefaultsCacheProvider.userDefaultsId: ["/": cachedJson!]])
		let cacheProvider = CloudResourceNsUserDefaultsCacheProvider(loadData: true, userDefaults: fakeUserDefaults)
		
		session.task?.taskProgress.bindNext { progress in
			if case .resume(let tsk) = progress {
				let json = JSON.getJsonFromFile("YandexRoot")
				dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
					tsk.completion?(json?.rawDataSafe(), nil, nil)
				}
			}
			}.addDisposableTo(bag)
		
		var responseCount = 0
		
		YandexDiskCloudJsonResource.loadRootResources(oauthResource, httpRequest: httpClient, cacheProvider: cacheProvider)?.bindNext { childs in
			if responseCount == 0 {
				// first responce should be with locally cached data
				responseCount += 1
				cachedRootExpectation.fulfill()
			} else if responseCount == 1 {
				// second responce should be with actual data
				responseCount += 1
				actualRootsexpectation.fulfill()
			}
			}.addDisposableTo(bag)
		
		waitForExpectationsWithTimeout(1, handler: nil)
		
		XCTAssertEqual(2, responseCount, "Check receive two responses")
	}
	
	func testLoadCacheOnly() {
		guard let rootItem = JSON.getJsonFromFile("YandexMusicDirItem") else {
			waitForExpectationsWithTimeout(1, handler: nil)
			return
		}
		
		let cachedJson = try! JSON.getJsonFromFile("YandexMusicFolderContents_Cached")?.rawData()
		let fakeUserDefaults = FakeNSUserDefaults(localCache: [CloudResourceNsUserDefaultsCacheProvider.userDefaultsId: [rootItem["path"].stringValue: cachedJson!]])
		let cacheProvider = CloudResourceNsUserDefaultsCacheProvider(loadData: true, userDefaults: fakeUserDefaults)
		let item = YandexDiskCloudJsonResource(raw: rootItem, oAuthResource: oauthResource, parent: nil, httpClient: httpClient, cacheProvider: cacheProvider)
		
		session.task?.taskProgress.bindNext { progress in
			if case .resume(let tsk) = progress {
				XCTAssertEqual(NSURL(baseUrl: item.resourcesUrl, parameters: item.getRequestParameters())?.absoluteString, tsk.originalRequest?.URL?.absoluteString,
					"Check invoke url")
				let json = JSON.getJsonFromFile("YandexMusicFolderContents")
				dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
					tsk.completion?(json?.rawDataSafe(), nil, nil)
				}
			}
			}.addDisposableTo(bag)
		
		let response = try! item.loadChildResources(.CacheOnly).toBlocking().toArray()
		
		// check responded only with cached data
		XCTAssertEqual(1, response.count, "Check responded once")
		
		// check return correct cached data
		let first = response.first?.first
		XCTAssertEqual(first?.name, "Apocalyptica")
		XCTAssertEqual(first?.path, "disk:/Music/Apocalyptica")
		XCTAssertEqual(first?.type, "dir")
		XCTAssertTrue(first is YandexDiskCloudJsonResource)
		XCTAssertEqual(item.uid, first?.parent?.uid)
		XCTAssertTrue((first as! YandexDiskCloudJsonResource).cacheProvider as! CloudResourceNsUserDefaultsCacheProvider === cacheProvider)
		
		let audioItem = response.last?.last as? CloudAudioResource
		XCTAssertEqual(audioItem?.name, "CachedTrack.mp3")
		XCTAssertEqual(audioItem?.path, "disk:/Music/CachedTrack.mp3")
		XCTAssertEqual(audioItem?.type, "file")
		XCTAssertTrue(audioItem is YandexDiskCloudAudioJsonResource)
		XCTAssertEqual(item.uid, audioItem?.parent?.uid)
		XCTAssertTrue((audioItem as! YandexDiskCloudJsonResource).cacheProvider as! CloudResourceNsUserDefaultsCacheProvider === cacheProvider)
	}
	
	func testLoadRemoteOnly() {
		guard let rootItem = JSON.getJsonFromFile("YandexMusicDirItem") else {
			waitForExpectationsWithTimeout(1, handler: nil)
			return
		}
		
		let cachedJson = try! JSON.getJsonFromFile("YandexMusicFolderContents_Cached")?.rawData()
		let fakeUserDefaults = FakeNSUserDefaults(localCache: [CloudResourceNsUserDefaultsCacheProvider.userDefaultsId: [rootItem["path"].stringValue: cachedJson!]])
		let cacheProvider = CloudResourceNsUserDefaultsCacheProvider(loadData: true, userDefaults: fakeUserDefaults)
		let item = YandexDiskCloudJsonResource(raw: rootItem, oAuthResource: oauthResource, parent: nil, httpClient: httpClient, cacheProvider: cacheProvider)
		
		session.task?.taskProgress.bindNext { progress in
			if case .resume(let tsk) = progress {
				XCTAssertEqual(NSURL(baseUrl: item.resourcesUrl, parameters: item.getRequestParameters())?.absoluteString, tsk.originalRequest?.URL?.absoluteString,
					"Check invoke url")
				let json = JSON.getJsonFromFile("YandexMusicFolderContents")
				dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
					tsk.completion?(json?.rawDataSafe(), nil, nil)
				}
			}
			}.addDisposableTo(bag)
		
		let response = try! item.loadChildResources(.RemoteOnly).toBlocking().toArray()
		
		// check responded only with cached data
		XCTAssertEqual(1, response.count, "Check responded once")
		
		// check return correct cached data
		let first = response.first?.first
		XCTAssertEqual(first?.name, "David Arkenstone")
		XCTAssertEqual(first?.path, "disk:/Music/David Arkenstone")
		XCTAssertEqual(first?.type, "dir")
		XCTAssertTrue(first is YandexDiskCloudJsonResource)
		XCTAssertEqual(item.uid, first?.parent?.uid)
		XCTAssertTrue((first as! YandexDiskCloudJsonResource).cacheProvider as! CloudResourceNsUserDefaultsCacheProvider === cacheProvider)
		
		let audioItem = response.last?.last as? CloudAudioResource
		XCTAssertEqual(audioItem?.name, "TestTrack.mp3")
		XCTAssertEqual(audioItem?.path, "disk:/Music/TestTrack.mp3")
		XCTAssertEqual(audioItem?.type, "file")
		XCTAssertTrue(audioItem is YandexDiskCloudAudioJsonResource)
		XCTAssertEqual(item.uid, audioItem?.parent?.uid)
		XCTAssertTrue((audioItem as! YandexDiskCloudJsonResource).cacheProvider as! CloudResourceNsUserDefaultsCacheProvider === cacheProvider)
	}
}
