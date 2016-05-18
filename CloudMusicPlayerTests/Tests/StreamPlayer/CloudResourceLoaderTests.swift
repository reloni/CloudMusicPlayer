//
//  CloudResourceLoaderTests.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 12.05.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import XCTest
import CloudMusicPlayer
import RealmSwift

class CloudResourceLoaderTests: XCTestCase {
	
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
		Realm.Configuration.defaultConfiguration.inMemoryIdentifier = self.name
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
	}
	
	func testLoadData() {
		fillRealmCloudResourceCacheProviderWithTestData()
		
		let oauthResource = YandexOAuth()
		let httpClient = HttpClient()
		let yandexRoot = YandexDiskCloudJsonResource.getRootResource(httpClient, oauth: oauthResource)
		let loader = CloudResourceLoader(cacheProvider: RealmCloudResourceCacheProvider(),
		                                 rootCloudResources: [YandexDiskCloudJsonResource.typeIdentifier: yandexRoot])
		
		// test return nil when it's folder
		let musicFolder = loader.loadStreamResourceByUid("disk:/Music")
		XCTAssertNil(musicFolder)
		
		let musicFile = loader.loadStreamResourceByUid("disk:/Music/TestTrack.mp3")
		XCTAssertTrue(musicFile is YandexDiskCloudAudioJsonResource)
		XCTAssertEqual(musicFile?.streamResourceContentType, ContentType.mp3)
	}
}
