//
//  CloudResourceClientYandexTests.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 07.05.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import XCTest
import SwiftyJSON
@testable import CloudMusicPlayer
import RxSwift
import Realm
import RealmSwift

class CloudResourceClientYandexTests: XCTestCase {
	
	var bag: DisposeBag!
	var request: FakeRequest!
	var session: FakeSession!
	var utilities: FakeHttpUtilities!
	var oauthResource: OAuthResourceBase!
	var httpClient: HttpClientProtocol!
	var rootResource: CloudResource!
	
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
		
		Realm.Configuration.defaultConfiguration.inMemoryIdentifier = self.name
		
		bag = DisposeBag()
		request = FakeRequest()
		session = FakeSession(fakeTask: FakeDataTask(completion: nil))
		utilities = FakeHttpUtilities()
		httpClient = HttpClient(urlSession: session, httpUtilities: utilities)
		oauthResource = OAuthResourceBase(id: "fakeOauthResource", authUrl: "https://fakeOauth.com", clientId: "fakeClientId", tokenId: "fakeTokenId")
		rootResource = YandexDiskCloudJsonResource.getRootResource(httpClient, oauth: oauthResource)
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
		bag = nil
		request = nil
		session = nil
		utilities = nil
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

		let client = CloudResourceClient()
		
		//YandexDiskCloudJsonResource.loadRootResources(oauthResource, httpRequest: httpClient)?.bindNext { result in
		client.loadChildResources(rootResource, loadMode: .CacheAndRemote).bindNext { result in
			if result.count == 9 {
				expectation.fulfill()
			}
			}.addDisposableTo(bag)
		
		waitForExpectationsWithTimeout(1, handler: nil)
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
		
		let client = CloudResourceClient()
		//YandexDiskCloudJsonResource.loadRootResources(oauthResource, httpRequest: httpClient)?.doOnError { error in
		client.loadChildResources(rootResource, loadMode: .CacheAndRemote).doOnError { error in
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
		
		let client = CloudResourceClient()
		//let request = YandexDiskCloudJsonResource.loadRootResources(oauthResource, httpRequest: httpClient)?
		let request = client.loadChildResources(rootResource, loadMode: .CacheAndRemote)
			.bindNext { _ in
		}
		request.dispose()
		
		waitForExpectationsWithTimeout(1, handler: nil)
	}
	
	func testLoadChilds() {
		let expectation = expectationWithDescription("Should return childs")
		
		guard let rootItem = JSON.getJsonFromFile("YandexMusicDirItem") else {
			waitForExpectationsWithTimeout(1, handler: nil)
			return
		}
		let item = YandexDiskCloudJsonResource(raw: rootItem, httpClient: httpClient, oauth: oauthResource)
		//let item = YandexDiskCloudJsonResource(raw: rootItem, oAuthResource: oauthResource, parent: nil, httpClient: httpClient)
		
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
		
		let cliet = CloudResourceClient()
		//item.loadChildResources().bindNext { childs in
		cliet.loadChildResources(item, loadMode: .CacheAndRemote).bindNext { childs in
			loadedChilds = childs
			expectation.fulfill()
			}.addDisposableTo(bag)
		
		waitForExpectationsWithTimeout(1, handler: nil)
		
		XCTAssertNotNil(loadedChilds)
		XCTAssertEqual(4, loadedChilds?.count)
		
		let first = loadedChilds?.first
		XCTAssertEqual(first?.name, "David Arkenstone")
		XCTAssertEqual(first?.uid, "disk:/Music/David Arkenstone")
		XCTAssertEqual(first?.type, .Folder)
		XCTAssertTrue(first is YandexDiskCloudJsonResource)
		//XCTAssertEqual(item.uid, first?.parent?.uid)
		
		let audioItem = loadedChilds?.last as? CloudAudioResource
		XCTAssertEqual(audioItem?.name, "TestTrack.mp3")
		XCTAssertEqual(audioItem?.uid, "disk:/Music/TestTrack.mp3")
		XCTAssertEqual(audioItem?.type, .File)
		XCTAssertTrue(audioItem is YandexDiskCloudAudioJsonResource)
		//XCTAssertEqual(item.uid, audioItem?.parent?.uid)
	}
	
	func testReceiveErrorWhileLoadingChilds() {
		let expectation = expectationWithDescription("Should receive error")
		
		guard let rootItem = JSON.getJsonFromFile("YandexMusicDirItem") else {
			XCTFail("Fail to load json from file")
			return
		}
		let item = YandexDiskCloudJsonResource(raw: rootItem, httpClient: httpClient, oauth: oauthResource)
		//let item = YandexDiskCloudJsonResource(raw: rootItem, oAuthResource: oauthResource, parent: nil, httpClient: httpClient)
		
		session.task?.taskProgress.bindNext { progress in
			if case .resume(let tsk) = progress {
				dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
					tsk.completion?(nil, nil, NSError(domain: "TestDomain", code: 1, userInfo: nil))
				}
			}
			}.addDisposableTo(bag)
		
		let client = CloudResourceClient()
		//item.loadChildResources().doOnError { error in
		client.loadChildResources(item, loadMode: .CacheAndRemote).doOnError { error in
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
		let item = YandexDiskCloudAudioJsonResource(raw: audioItem, httpClient: httpClient, oauth: oauthResource)
		//let item = YandexDiskCloudAudioJsonResource(raw: audioItem, oAuthResource: oauthResource, parent: nil, httpClient: httpClient)
		
		session.task?.taskProgress.bindNext { progress in
			if case .resume(let tsk) = progress {
				XCTAssertEqual(item.downloadResourceUrl, tsk.originalRequest?.URL, "Check invoke url")
				dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
					tsk.completion?(sendJson.rawDataSafe(), nil, nil)
				}
			}
			}.addDisposableTo(bag)
		
		item.downloadUrl.bindNext { result in
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
		
		let item = YandexDiskCloudAudioJsonResource(raw: audioItem, httpClient: httpClient, oauth: oauthResource)
		//let item = YandexDiskCloudAudioJsonResource(raw: audioItem, oAuthResource: oauthResource, parent: nil, httpClient: httpClient)
		
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
		
		item.downloadUrl.doOnCompleted { expectation.fulfill() }.bindNext { result in
			XCTFail("Should not return data")
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
		
		let cachedJson = JSON.getJsonFromFile("YandexMusicFolderContents_Cached")
		
		//let fakeUserDefaults = FakeNSUserDefaults(localCache: [CloudResourceNsUserDefaultsCacheProvider.userDefaultsId: [rootItem["path"].stringValue: cachedJson!]])
		//let cacheProvider = CloudResourceNsUserDefaultsCacheProvider(loadData: true, userDefaults: fakeUserDefaults)
		//let yandexRoot = try! YandexDiskCloudJsonResource.getRootResource(httpClient, oauth: oauthResource).toBlocking().first()
		let item = YandexDiskCloudJsonResource(raw: rootItem, httpClient: httpClient, oauth: oauthResource)
		let cacheProvider = RealmCloudResourceCacheProvider()
		cacheProvider.cacheChilds(item, childs: item.deserializeResponse(cachedJson!))
		//let item = YandexDiskCloudJsonResource(raw: rootItem, oAuthResource: oauthResource, parent: nil, httpClient: httpClient, cacheProvider: cacheProvider)
		
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
		
		let client = CloudResourceClient(cacheProvider: cacheProvider)
		//item.loadChildResources().bindNext { childs in
		client.loadChildResources(item, loadMode: .CacheAndRemote).bindNext { childs in
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
			} else { responseCount += 1 }
			}.addDisposableTo(bag)
		
		waitForExpectationsWithTimeout(1, handler: nil)
		
		// check cached items
		XCTAssertNotNil(cachedChilds)
		XCTAssertEqual(2, cachedChilds?.count)
		
		var first = cachedChilds?.first
		XCTAssertEqual(first?.name, "Apocalyptica")
		XCTAssertEqual(first?.uid, "disk:/Music/Apocalyptica")
		XCTAssertEqual(first?.type, .Folder)
		XCTAssertTrue(first is YandexDiskCloudJsonResource)
		//XCTAssertEqual(item.uid, first?.parent?.uid)
		//XCTAssertTrue((first as! YandexDiskCloudJsonResource).cacheProvider as! CloudResourceNsUserDefaultsCacheProvider === cacheProvider)
		
		var audioItem = cachedChilds?.last as? CloudAudioResource
		XCTAssertEqual(audioItem?.name, "CachedTrack.mp3")
		XCTAssertEqual(audioItem?.uid, "disk:/Music/CachedTrack.mp3")
		XCTAssertEqual(audioItem?.type, .File)
		XCTAssertTrue(audioItem is YandexDiskCloudAudioJsonResource)
		//XCTAssertEqual(item.uid, audioItem?.parent?.uid)
		//XCTAssertTrue((audioItem as! YandexDiskCloudJsonResource).cacheProvider as! CloudResourceNsUserDefaultsCacheProvider === cacheProvider)
		
		// check loaded items
		XCTAssertNotNil(loadedChilds)
		XCTAssertEqual(4, loadedChilds?.count)
		
		first = loadedChilds?.first
		XCTAssertEqual(first?.name, "David Arkenstone")
		XCTAssertEqual(first?.uid, "disk:/Music/David Arkenstone")
		XCTAssertEqual(first?.type, .Folder)
		XCTAssertTrue(first is YandexDiskCloudJsonResource)
		//XCTAssertEqual(item.uid, first?.parent?.uid)
		//XCTAssertTrue((first as! YandexDiskCloudJsonResource).cacheProvider as! CloudResourceNsUserDefaultsCacheProvider === cacheProvider)
		
		audioItem = loadedChilds?.last as? CloudAudioResource
		XCTAssertEqual(audioItem?.name, "TestTrack.mp3")
		XCTAssertEqual(audioItem?.uid, "disk:/Music/TestTrack.mp3")
		XCTAssertEqual(audioItem?.type, .File)
		XCTAssertTrue(audioItem is YandexDiskCloudAudioJsonResource)
		//XCTAssertEqual(item.uid, audioItem?.parent?.uid)
		//XCTAssertTrue((audioItem as! YandexDiskCloudJsonResource).cacheProvider as! CloudResourceNsUserDefaultsCacheProvider === cacheProvider)
	}
	
//	func testLoadAndCacheChilds() {
//		let expectation = expectationWithDescription("Should return childs")
//		
//		guard let rootItem = JSON.getJsonFromFile("YandexMusicDirItem") else {
//			XCTFail("Failed to load json data")
//			return
//		}
//		
//		let fakeUserDefaults = FakeNSUserDefaults()
//		let cacheProvider = CloudResourceNsUserDefaultsCacheProvider(loadData: true, userDefaults: fakeUserDefaults)
//		let item = YandexDiskCloudJsonResource(raw: rootItem, httpClient: httpClient, oauth: oauthResource, parent: nil)
//		//let item = YandexDiskCloudJsonResource(raw: rootItem, oAuthResource: oauthResource, parent: nil, httpClient: httpClient, cacheProvider: cacheProvider)
//		
//		session.task?.taskProgress.bindNext { progress in
//			if case .resume(let tsk) = progress {
//				XCTAssertEqual(NSURL(baseUrl: item.resourcesUrl, parameters: item.getRequestParameters())?.absoluteString, tsk.originalRequest?.URL?.absoluteString, "Check invoke url")
//				let json = JSON.getJsonFromFile("YandexMusicFolderContents")
//				dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
//					tsk.completion?(json?.rawDataSafe(), nil, nil)
//				}
//			}
//			}.addDisposableTo(bag)
//		
//		let client = CloudResourceClient(cacheProvider: cacheProvider)
//		//item.loadChildResources().bindNext { _ in
//		client.loadChildResources(item, loadMode: .CacheAndRemote).bindNext { _ in
//			expectation.fulfill()
//			}.addDisposableTo(bag)
//		
//		waitForExpectationsWithTimeout(1, handler: nil)
//		
//		guard let cachedData = (fakeUserDefaults.localCache.first?.1 as? [String: NSData])?.first?.1 else {
//			XCTFail("Data not cached")
//			return
//		}
//		
//		XCTAssertEqual(JSON.getJsonFromFile("YandexMusicFolderContents"), JSON(data: cachedData), "Sended json should be same as cached")
//	}
	
	func testCacheRootResources() {
		let expectation = expectationWithDescription("Should return childs")
		
		//let fakeUserDefaults = FakeNSUserDefaults()
		//let cacheProvider = CloudResourceNsUserDefaultsCacheProvider(loadData: true, userDefaults: fakeUserDefaults)
		let cacheProvider = RealmCloudResourceCacheProvider()
		
		session.task?.taskProgress.bindNext { progress in
			if case .resume(let tsk) = progress {
				let json = JSON.getJsonFromFile("YandexRoot")
				dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
					tsk.completion?(json?.rawDataSafe(), nil, nil)
				}
			}
			}.addDisposableTo(bag)
		
		let client = CloudResourceClient(cacheProvider: cacheProvider)
		//YandexDiskCloudJsonResource.loadRootResources(oauthResource, httpRequest: httpClient, cacheProvider: cacheProvider)?.bindNext { _ in
		client.loadChildResources(rootResource, loadMode: .CacheAndRemote).bindNext { _ in
			expectation.fulfill()
			}.addDisposableTo(bag)
		
		waitForExpectationsWithTimeout(1, handler: nil)
		
		//guard let cachedData = (fakeUserDefaults.localCache.first?.1 as? [String: NSData])?.first?.1 else {
		//	XCTFail("Data not cached")
		//	return
		//}
		
		let realm = try! Realm()
		XCTAssertEqual(10, realm.objects(RealmCloudResource).count)
		//XCTAssertEqual(JSON.getJsonFromFile("YandexRoot"), JSON(data: cachedData), "Sended json should be same as cached")
	}
	
	func testLoadCachedRootData() {
		let actualRootsexpectation = expectationWithDescription("Should return actual root items")
		let cachedRootExpectation = expectationWithDescription("Ahould return cached root items")
		
		let cachedJson = JSON.getJsonFromFile("YandexRoot")!
		let yandexRoot = YandexDiskCloudJsonResource.getRootResource(httpClient, oauth: oauthResource)
		let cacheProvider = RealmCloudResourceCacheProvider()
		cacheProvider.cacheChilds(yandexRoot, childs: yandexRoot.deserializeResponse(cachedJson))
		
		session.task?.taskProgress.bindNext { progress in
			if case .resume(let tsk) = progress {
				let json = JSON.getJsonFromFile("YandexRoot")
				dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
					tsk.completion?(json?.rawDataSafe(), nil, nil)
				}
			}
			}.addDisposableTo(bag)
		
		var responseCount = 0
		
		let client = CloudResourceClient(cacheProvider: cacheProvider)
		//YandexDiskCloudJsonResource.loadRootResources(oauthResource, httpRequest: httpClient, cacheProvider: cacheProvider)?.bindNext { childs in
		client.loadChildResources(rootResource, loadMode: .CacheAndRemote).bindNext { childs in
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
		
		let musicResource = rootResource.wrapRawData(rootItem) as! YandexDiskCloudJsonResource
		let cachedJson = JSON.getJsonFromFile("YandexMusicFolderContents_Cached")!
		let musicChilds = musicResource.deserializeResponse(cachedJson)

		let cacheProvider = RealmCloudResourceCacheProvider()
		cacheProvider.cacheChilds(musicResource, childs: musicChilds)
		//let item = YandexDiskCloudJsonResource(raw: rootItem, httpClient: httpClient, oauth: oauthResource, parent: nil)
		//let item = YandexDiskCloudJsonResource(raw: rootItem, oAuthResource: oauthResource, parent: nil, httpClient: httpClient, cacheProvider: cacheProvider)
		
		session.task?.taskProgress.bindNext { progress in
			if case .resume(let tsk) = progress {
				XCTAssertEqual(NSURL(baseUrl: musicResource.resourcesUrl, parameters: musicResource.getRequestParameters())?.absoluteString, tsk.originalRequest?.URL?.absoluteString,
					"Check invoke url")
				let json = JSON.getJsonFromFile("YandexMusicFolderContents")
				dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
					tsk.completion?(json?.rawDataSafe(), nil, nil)
				}
			}
			}.addDisposableTo(bag)
		
		let client = CloudResourceClient(cacheProvider: cacheProvider)
		//let response = try! item.loadChildResources(.CacheOnly).toBlocking().toArray()
		let response = try! client.loadChildResources(musicResource, loadMode: .CacheOnly).toBlocking().toArray()
		
		// check responded only with cached data
		XCTAssertEqual(1, response.count, "Check responded once")
		
		// check return correct cached data
		let first = response.first?.first
		XCTAssertEqual(first?.name, "Apocalyptica")
		XCTAssertEqual(first?.uid, "disk:/Music/Apocalyptica")
		XCTAssertEqual(first?.type, .Folder)
		XCTAssertTrue(first is YandexDiskCloudJsonResource)
		//XCTAssertEqual(musicResource.uid, first?.parent?.uid)
		//XCTAssertTrue(first?.parent as? YandexDiskCloudJsonResource === musicResource)
		//XCTAssertTrue((first as! YandexDiskCloudJsonResource).cacheProvider as! CloudResourceNsUserDefaultsCacheProvider === cacheProvider)
		
		let audioItem = response.last?.last as? CloudAudioResource
		XCTAssertEqual(audioItem?.name, "CachedTrack.mp3")
		XCTAssertEqual(audioItem?.uid, "disk:/Music/CachedTrack.mp3")
		XCTAssertEqual(audioItem?.type, .File)
		XCTAssertTrue(audioItem is YandexDiskCloudAudioJsonResource)
		//XCTAssertTrue(audioItem?.parent as? YandexDiskCloudJsonResource === musicResource)
		//XCTAssertEqual(musicResource.uid, audioItem?.parent?.uid)
		//XCTAssertTrue((audioItem as! YandexDiskCloudJsonResource).cacheProvider as! CloudResourceNsUserDefaultsCacheProvider === cacheProvider)
	}
	
	func testLoadRemoteOnly() {
		guard let rootItem = JSON.getJsonFromFile("YandexMusicDirItem") else {
			waitForExpectationsWithTimeout(1, handler: nil)
			return
		}
		
		let musicResource = rootResource.wrapRawData(rootItem) as! YandexDiskCloudJsonResource
		let cachedJson = JSON.getJsonFromFile("YandexMusicFolderContents_Cached")!
		let musicChilds = musicResource.deserializeResponse(cachedJson)
		
		let cacheProvider = RealmCloudResourceCacheProvider()
		cacheProvider.cacheChilds(musicResource, childs: musicChilds)
		//let item = YandexDiskCloudJsonResource(raw: rootItem, oAuthResource: oauthResource, parent: nil, httpClient: httpClient, cacheProvider: cacheProvider)
		
		session.task?.taskProgress.bindNext { progress in
			if case .resume(let tsk) = progress {
				XCTAssertEqual(NSURL(baseUrl: musicResource.resourcesUrl, parameters: musicResource.getRequestParameters())?.absoluteString, tsk.originalRequest?.URL?.absoluteString,
					"Check invoke url")
				let json = JSON.getJsonFromFile("YandexMusicFolderContents")
				dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
					tsk.completion?(json?.rawDataSafe(), nil, nil)
				}
			}
			}.addDisposableTo(bag)
		
		let client = CloudResourceClient(cacheProvider: cacheProvider)
		//let response = try! item.loadChildResources(.RemoteOnly).toBlocking().toArray()
		let response = try! client.loadChildResources(musicResource, loadMode: .RemoteOnly).toBlocking().toArray()
		
		// check responded only with cached data
		XCTAssertEqual(1, response.count, "Check responded once")
		
		// check return correct cached data
		let first = response.first?.first
		XCTAssertEqual(first?.name, "David Arkenstone")
		XCTAssertEqual(first?.uid, "disk:/Music/David Arkenstone")
		XCTAssertEqual(first?.type, .Folder)
		XCTAssertTrue(first is YandexDiskCloudJsonResource)
		//XCTAssertEqual(musicResource.uid, first?.parent?.uid)
		//XCTAssertTrue(first?.parent as? YandexDiskCloudJsonResource === musicResource)
		//XCTAssertTrue((first as! YandexDiskCloudJsonResource).cacheProvider as! CloudResourceNsUserDefaultsCacheProvider === cacheProvider)
		
		let audioItem = response.last?.last as? CloudAudioResource
		XCTAssertEqual(audioItem?.name, "TestTrack.mp3")
		XCTAssertEqual(audioItem?.uid, "disk:/Music/TestTrack.mp3")
		XCTAssertEqual(audioItem?.type, .File)
		XCTAssertTrue(audioItem is YandexDiskCloudAudioJsonResource)
		//XCTAssertEqual(musicResource.uid, audioItem?.parent?.uid)
		//XCTAssertTrue(audioItem?.parent as? YandexDiskCloudJsonResource === musicResource)
		//XCTAssertTrue((audioItem as! YandexDiskCloudJsonResource).cacheProvider as! CloudResourceNsUserDefaultsCacheProvider === cacheProvider)
	}
}
