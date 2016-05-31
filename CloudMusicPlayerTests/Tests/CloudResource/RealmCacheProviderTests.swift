//
//  UserDefaultsCacheProviderTests.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 20.04.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import XCTest
@testable import CloudMusicPlayer
import RealmSwift
import Realm
import SwiftyJSON
import RxSwift

func fillRealmCloudResourceCacheProviderWithTestData() {
	let oauthResource = YandexOAuth()//OAuthResourceBase(id: "", authUrl: "", clientId: nil, tokenId: nil)
	let httpClient = HttpClient()
	let rootCloudResource = YandexDiskCloudJsonResource(raw: JSON(["path": "disk:/Music", "type": "dir", "name": "Music",
		"modified": "2016-02-27T12:54:42+00:00", "created": "2016-02-27T12:54:42+00:00"]), httpClient: httpClient, oauth: oauthResource)
	
	let childResource1 = YandexDiskCloudJsonResource(raw: JSON(["path": "disk:/Music/dir1", "type": "dir", "name": "dir1",
		"modified": "2016-02-28T12:54:42+00:00", "created": "2016-02-28T12:54:42+00:00"]), httpClient: httpClient, oauth: oauthResource)
	
	let childResource2 = YandexDiskCloudJsonResource(raw: JSON(["name": "TestTrack.mp3",
		"created": "2016-03-05T11:49:31+00:00",
		"modified": "2016-03-05T11:49:31+00:00",
		"media_type": "audio",
		"path": "disk:/Music/TestTrack.mp3",
		"md5": "33e68f0c72fd6e403c4c73e103e7e3ab",
		"type": "file",
		"mime_type": "audio/mpeg",
		"size": 8293071]), httpClient: httpClient, oauth: oauthResource)
	
	let cacheProvider = RealmCloudResourceCacheProvider()
	let realm = try! Realm()
	realm.beginWrite()
	
	//YandexDiskCloudJsonResource..getRootResource(httpClient, oauth: oauthResource)
	let realmRoot = cacheProvider.createResource(realm, resource: YandexDiskCloudJsonResource.getRootResource(httpClient, oauth: oauthResource), parentObjectUid: nil)
	realmRoot.childs.append(cacheProvider.createResource(realm, resource: rootCloudResource, parentObjectUid: realmRoot.uid))
	realmRoot.childs.first!.childs.append(cacheProvider.createResource(realm, resource: childResource1, parentObjectUid: rootCloudResource.uid))
	realmRoot.childs.first!.childs.append(cacheProvider.createResource(realm, resource: childResource2, parentObjectUid: rootCloudResource.uid))
	realm.add(realmRoot)
	let _ = try! realm.commitWrite()
}

class RealmCacheProviderTests: XCTestCase {
	var bag: DisposeBag!
	var request: FakeRequest!
	var session: FakeSession!
	var utilities: FakeHttpUtilities!
	var oauthResource: OAuthType!
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
		httpClient = HttpClient(httpUtilities: utilities)
		//oauthResource = OAuthResourceBase(id: "fakeOauthResource", authUrl: "https://fakeOauth.com", clientId: "fakeClientId", tokenId: "fakeTokenId")
		oauthResource = YandexOAuth(clientId: "fakeClientId", urlScheme: "fakeOauthResource", keychain: FakeKeychain(), authenticator: OAuthAuthenticator())
		(oauthResource as! YandexOAuth).keychain.setString("", forAccount: (oauthResource as! YandexOAuth).tokenKeychainId, synchronizable: false, background: false)
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
	
	func testLoadData() {
		fillRealmCloudResourceCacheProviderWithTestData()
		
		let cacheProvider = RealmCloudResourceCacheProvider()
		let resourcesFromCache = cacheProvider.getCachedChilds(cacheProvider.getCachedChilds(rootResource).first!)
		
		XCTAssertEqual(resourcesFromCache.count, 2)
		
		XCTAssertEqual(resourcesFromCache[0].name, "dir1")
		XCTAssertEqual(resourcesFromCache[0].type, CloudResourceType.Folder)
		
		XCTAssertEqual(resourcesFromCache[1].name, "TestTrack.mp3")
		XCTAssertEqual(resourcesFromCache[1].type, CloudResourceType.File)
	}
	
	func testLoadRawData() {
		fillRealmCloudResourceCacheProviderWithTestData()
		
		let cacheProvider = RealmCloudResourceCacheProvider()
		let raw = cacheProvider.getRawCachedResource("disk:/Music")
		
		let resource = rootResource.wrapRawData(JSON(data: raw!.rawData))
		XCTAssertEqual(resource.uid, "disk:/Music")
		XCTAssertEqual(resource.name, "Music")
		XCTAssertEqual(raw?.resourceTypeIdentifier, YandexDiskCloudJsonResource.typeIdentifier)
	}
	
	func testClearCachedData() {
		fillRealmCloudResourceCacheProviderWithTestData()
		let realm = try! Realm()
		XCTAssertEqual(4, realm.objects(RealmCloudResource).count)
		let cacheProvider = RealmCloudResourceCacheProvider()
		cacheProvider.clearCache()
		XCTAssertEqual(0, realm.objects(RealmCloudResource).count)
	}
	
	func testSaveData() {
		let rootCloudResource = YandexDiskCloudJsonResource(raw: JSON(["path": "disk:/Music", "type": "dir", "name": "Music",
			"modified": "2016-02-27T12:54:42+00:00", "created": "2016-02-27T12:54:42+00:00"]), httpClient: httpClient, oauth: oauthResource)
		
		let childResource1 = YandexDiskCloudJsonResource(raw: JSON(["path": "disk:/Music/dir1", "type": "dir", "name": "dir1",
			"modified": "2016-02-28T12:54:42+00:00", "created": "2016-02-28T12:54:42+00:00"]), httpClient: httpClient, oauth: oauthResource)
		
		let childResource2 = YandexDiskCloudJsonResource(raw: JSON(["name": "TestTrack.mp3",
			"created": "2016-03-05T11:49:31+00:00",
			"modified": "2016-03-05T11:49:31+00:00",
			"media_type": "audio",
			"path": "disk:/Music/TestTrack.mp3",
			"md5": "33e68f0c72fd6e403c4c73e103e7e3ab",
			"type": "file",
			"mime_type": "audio/mpeg",
			"size": 8293071]), httpClient: httpClient, oauth: oauthResource)
		
		let cacheProvider = RealmCloudResourceCacheProvider()
		cacheProvider.cacheChilds(rootCloudResource, childs: [childResource1, childResource2])
		
		let resourcesFromCache = cacheProvider.getCachedChilds(rootCloudResource)
		
		XCTAssertEqual(resourcesFromCache.count, 2)
		
		XCTAssertEqual(resourcesFromCache.first?.name, "dir1")
		XCTAssertEqual(resourcesFromCache.first?.type, CloudResourceType.Folder)
		
		XCTAssertEqual(resourcesFromCache.last?.name, "TestTrack.mp3")
		XCTAssertEqual(resourcesFromCache.last?.type, CloudResourceType.File)
	}
	
	func testOwerwriteData() {
		fillRealmCloudResourceCacheProviderWithTestData()
		
		let rootCloudResource = YandexDiskCloudJsonResource(raw: JSON(["path": "disk:/Music", "type": "dir", "name": "Music",
			"modified": "2016-02-27T12:54:42+00:00", "created": "2016-02-27T12:54:42+00:00"]), httpClient: httpClient, oauth: oauthResource)
		let childResource = YandexDiskCloudJsonResource(raw: JSON(["name": "TestTrack.mp3",
			"created": "2016-03-05T11:49:31+00:00",
			"modified": "2016-03-05T11:49:31+00:00",
			"media_type": "audio",
			"path": "disk:/Music/TestTrack.mp3",
			"md5": "33e68f0c72fd6e403c4c73e103e7e3ab",
			"type": "file",
			"mime_type": "audio/mpeg",
			"size": 8293071]), httpClient: httpClient, oauth: oauthResource)
		
		let cacheProvider = RealmCloudResourceCacheProvider()
		cacheProvider.cacheChilds(rootCloudResource, childs: [childResource])
		
		let realm = try! Realm()
		XCTAssertEqual(3, realm.objects(RealmCloudResource).count)
		print(realm.objects(RealmCloudResource).map { $0.uid })
		
		let resourcesFromCache = cacheProvider.getCachedChilds(rootCloudResource)
		
		XCTAssertEqual(resourcesFromCache.count, 1)
		
		XCTAssertEqual(resourcesFromCache[0].name, "TestTrack.mp3")
		XCTAssertEqual(resourcesFromCache[0].type, CloudResourceType.File)
	}
}
