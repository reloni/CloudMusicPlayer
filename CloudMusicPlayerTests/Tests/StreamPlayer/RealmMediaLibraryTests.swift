//
//  RealmMediaLibraryTests.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 11.05.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import XCTest
@testable import CloudMusicPlayer
import RealmSwift

extension RealmMediaItemMetadata {
	public convenience init(uid: String, title: String?, album: String?, artist: String?, artwork: NSData?, duration: Float?) {
		self.init(uid: uid)
		self.title = title
		self.album = album
		self.artist = artist
		self.artwork = artwork
		self.internalDuration.value = duration
	}
}

class RealmMediaLibraryTests: XCTestCase {
	
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
		Realm.Configuration.defaultConfiguration.inMemoryIdentifier = self.name
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
	}
	
	func testAddMetadataItem() {
		let metadata = MediaItemMetadata(resourceUid: "testuid", artist: "Test artist", title: "Test title", album: "test album",
		                                 artwork: "test artwork".dataUsingEncoding(NSUTF8StringEncoding), duration: 1.56)
		let lib = RealmMediaLibrary() as MediaLibraryType
		lib.saveMetadata(metadata)
		
		let realm = try! Realm()
		let realmObject = realm.objects(RealmMediaItemMetadata).first
		
		XCTAssertNotNil(realmObject)
		XCTAssertEqual(realmObject?.resourceUid, metadata.resourceUid)
		XCTAssertEqual(realmObject?.album, metadata.album)
		XCTAssertEqual(realmObject?.artist, metadata.artist)
		XCTAssertEqual(realmObject?.artwork, metadata.artwork)
		XCTAssertEqual(realmObject?.title, metadata.title)
		XCTAssertEqual(realmObject?.duration, metadata.duration)
	}
	
	func testUpdateExistedMetadata() {
		var metadata = MediaItemMetadata(resourceUid: "testuid", artist: "Test artist", title: "Test title", album: "test album",
		                                 artwork: "test artwork".dataUsingEncoding(NSUTF8StringEncoding), duration: 1.56)
		let lib = RealmMediaLibrary() as MediaLibraryType
		lib.saveMetadata(metadata)
	
		metadata.artist = "updated artist"
		metadata.title = "updated title"
		metadata.album = "updated album"
		
		lib.saveMetadata(metadata)
		
		let realm = try! Realm()
		let realmObject = realm.objects(RealmMediaItemMetadata).first
		
		XCTAssertNotNil(realmObject)
		XCTAssertEqual(realmObject?.resourceUid, metadata.resourceUid)
		XCTAssertEqual(realmObject?.album, metadata.album)
		XCTAssertEqual(realmObject?.artist, metadata.artist)
		XCTAssertEqual(realmObject?.artwork, metadata.artwork)
		XCTAssertEqual(realmObject?.title, metadata.title)
		XCTAssertEqual(realmObject?.duration, metadata.duration)
	}
	
	func testReturnMetadata() {
		let metadata = RealmMediaItemMetadata(uid: "testuid")
		metadata.album = "test album"
		metadata.artist = "test artist"
		metadata.title = "test title"
		metadata.artwork = "test artwork".dataUsingEncoding(NSUTF8StringEncoding)
		metadata.internalDuration.value = 1.56
		let realm = try! Realm()
		try! realm.write { realm.add(metadata) }
		
		let lib = RealmMediaLibrary()
		let libMetadata = lib.getMetadata("testuid")
		
		XCTAssertNotNil(libMetadata)
		XCTAssertEqual(libMetadata?.resourceUid, "testuid")
		XCTAssertEqual(libMetadata?.album, "test album")
		XCTAssertEqual(libMetadata?.artist, "test artist")
		XCTAssertEqual(libMetadata?.artwork, "test artwork".dataUsingEncoding(NSUTF8StringEncoding))
		XCTAssertEqual(libMetadata?.title, "test title")
		XCTAssertEqual(libMetadata?.duration, 1.56)
	}
	
	func testReturnNilIfMetadataNotExisted() {
		let metadata = RealmMediaItemMetadata(uid: "testuid")
		metadata.album = "test album"
		metadata.artist = "test artist"
		metadata.title = "test title"
		metadata.artwork = "test artwork".dataUsingEncoding(NSUTF8StringEncoding)
		metadata.internalDuration.value = 1.56
		let realm = try! Realm()
		try! realm.write { realm.add(metadata) }
		
		let lib = RealmMediaLibrary()
		let libMetadata = lib.getMetadata("wronguid")
		
		XCTAssertNil(libMetadata)
	}
	
	func testCreatePlayList() {
		let lib = RealmMediaLibrary()
		let createdPl = lib.createPlayList("super play list")
		
		XCTAssertEqual(createdPl?.name, "super play list")
		XCTAssertEqual(createdPl?.items.count, 0)
		
		let realm = try! Realm()
		let realmPl = realm.objects(RealmPlayList).first
		
		XCTAssertNotNil(realmPl)
		XCTAssertEqual(realmPl?.name, createdPl?.name)
		XCTAssertEqual(realmPl?.uid, createdPl?.uid)
		XCTAssertEqual(realmPl?.items.count, createdPl?.items.count)
	}
	
	func testReturnEmptyPlayListByUid() {
		let pl = RealmPlayList(uid: "testuid", name: "my play list")
		let realm = try! Realm()
		try! realm.write { realm.add(pl) }
		
		let lib = RealmMediaLibrary()
		let libPl = lib.getPlayListByUid("testuid")
		
		XCTAssertEqual(libPl?.name, pl.name)
		XCTAssertEqual(libPl?.items.count, 0)
	}
	
	func testReturnNilIfPlayListNotExistedByUid() {
		let pl = RealmPlayList(uid: "testuid", name: "my play list")
		let realm = try! Realm()
		try! realm.write { realm.add(pl) }
		
		let lib = RealmMediaLibrary()
		let libPl = lib.getPlayListByUid("wrong")
		
		XCTAssertNil(libPl)
	}
	
	func testCreatePlayListAndAddItems() {
		let lib = RealmMediaLibrary()
		guard let createdPl = lib.createPlayList("super play list") else { XCTFail("PlayList creation failed"); return }
	
		lib.addItemsToPlayList(createdPl, items: [
			MediaItemMetadata(resourceUid: "testuid1", artist: "Test artist1", title: "Test title1", album: "test album1",
				artwork: "test artwork1".dataUsingEncoding(NSUTF8StringEncoding), duration: 1.1),
			MediaItemMetadata(resourceUid: "testuid2", artist: "Test artist2", title: "Test title2", album: "test album2",
				artwork: "test artwork2".dataUsingEncoding(NSUTF8StringEncoding), duration: 1.2),
			MediaItemMetadata(resourceUid: "testuid3", artist: "Test artist3", title: "Test title3", album: "test album3",
				artwork: "test artwork3".dataUsingEncoding(NSUTF8StringEncoding), duration: 1.3)
			])
		
		let realm = try! Realm()
		let realmPl = realm.objects(RealmPlayList).first
		
		XCTAssertEqual(realmPl?.items.count, 3)
	}
	
	func testReturnPlayListWithItemsByUid() {
		let pl = RealmPlayList(uid: "testuid", name: "my play list")
		pl.items.append(RealmMediaItemMetadata(uid: "metauid1", title: "meta 1", album: "meta 1", artist: "meta 1", artwork: nil, duration: 0))
		pl.items.append(RealmMediaItemMetadata(uid: "metauid2", title: "meta 2", album: "meta 2", artist: "meta 2", artwork: nil, duration: 0))
		let realm = try! Realm()
		try! realm.write { realm.add(pl) }
		
		let lib = RealmMediaLibrary()
		let libPl = lib.getPlayListByUid("testuid")
		
		XCTAssertEqual(libPl?.items.count, 2)
	}
	
	func testReturnSinglePlayListWithItemsByName() {
		let pl = RealmPlayList(uid: "testuid", name: "my play list")
		pl.items.append(RealmMediaItemMetadata(uid: "metauid1", title: "meta 1", album: "meta 1", artist: "meta 1", artwork: nil, duration: 0))
		pl.items.append(RealmMediaItemMetadata(uid: "metauid2", title: "meta 2", album: "meta 2", artist: "meta 2", artwork: nil, duration: 0))
		let realm = try! Realm()
		try! realm.write {
			realm.add(pl);
			realm.add(RealmPlayList(uid: "testuid2", name: "second pl"));
			realm.add(RealmPlayList(uid: "testuid3", name: "third pl"))
		}
		
		let lib = RealmMediaLibrary()
		let libPlayLists = lib.getPlayListsByName("my play list")
		
		XCTAssertEqual(libPlayLists.count, 1)
		XCTAssertEqual(libPlayLists.first?.items.count, 2)
	}
	
	func testClearMediaLibrary() {
		let pl1 = RealmPlayList(uid: "pluid1", name: "my play list")
		pl1.items.append(RealmMediaItemMetadata(uid: "metauid1", title: "meta 1", album: "meta 1", artist: "meta 1", artwork: nil, duration: 0))
		pl1.items.append(RealmMediaItemMetadata(uid: "metauid2", title: "meta 2", album: "meta 2", artist: "meta 2", artwork: nil, duration: 0))
		
		let pl2 = RealmPlayList(uid: "pluid2", name: "my play list")
		pl2.items.append(RealmMediaItemMetadata(uid: "metauid3", title: "meta 1", album: "meta 1", artist: "meta 1", artwork: nil, duration: 0))
		pl2.items.append(RealmMediaItemMetadata(uid: "metauid4", title: "meta 2", album: "meta 2", artist: "meta 2", artwork: nil, duration: 0))
		
		let realm = try! Realm()
		try! realm.write {
			realm.add(pl1)
			realm.add(pl2)
		}
		
		let lib = RealmMediaLibrary()
		lib.clearLibrary()
		
		XCTAssertEqual(realm.objects(RealmMediaItemMetadata).count, 0)
		XCTAssertEqual(realm.objects(RealmPlayList).count, 0)
	}
	
	func testCorrectCheckExistedMetadata() {
		let metadata = MediaItemMetadata(resourceUid: "testuid", artist: "Test artist", title: "Test title", album: "test album",
		                                 artwork: "test artwork".dataUsingEncoding(NSUTF8StringEncoding), duration: 1.56)
		let lib = RealmMediaLibrary() as MediaLibraryType
		lib.saveMetadata(metadata)
		
		XCTAssertTrue(lib.isMetadataExists(metadata.resourceUid))
	}
	
	func testCorrectCheckNotExistedMetadata() {
		let metadata = MediaItemMetadata(resourceUid: "testuid", artist: "Test artist", title: "Test title", album: "test album",
		                                 artwork: "test artwork".dataUsingEncoding(NSUTF8StringEncoding), duration: 1.56)
		let lib = RealmMediaLibrary() as MediaLibraryType
		lib.saveMetadata(metadata)
		
		XCTAssertFalse(lib.isMetadataExists("notexisted"))
	}
	
	func testClearPlayList() {
		let pl = RealmPlayList(uid: "testuid", name: "my play list")
		pl.items.append(RealmMediaItemMetadata(uid: "metauid1", title: "meta 1", album: "meta 1", artist: "meta 1", artwork: nil, duration: 0))
		pl.items.append(RealmMediaItemMetadata(uid: "metauid2", title: "meta 2", album: "meta 2", artist: "meta 2", artwork: nil, duration: 0))
		let realm = try! Realm()
		try! realm.write { realm.add(pl) }
		
		let lib = RealmMediaLibrary()
		let libPl = lib.getPlayListByUid("testuid")
		
		let clearedPl = lib.clearPlayList(libPl!)
		
		XCTAssertEqual(clearedPl.items.count, 0)
		XCTAssertEqual(realm.objects(RealmPlayList).first?.items.count, 0)
		XCTAssertEqual(realm.objects(RealmMediaItemMetadata).count, 2)
	}
	
	func testNotClearNotExistedPlayList() {
		let pl = RealmPlayList(uid: "testuid", name: "my play list")
		pl.items.append(RealmMediaItemMetadata(uid: "metauid1", title: "meta 1", album: "meta 1", artist: "meta 1", artwork: nil, duration: 0))
		pl.items.append(RealmMediaItemMetadata(uid: "metauid2", title: "meta 2", album: "meta 2", artist: "meta 2", artwork: nil, duration: 0))
		let realm = try! Realm()
		try! realm.write { realm.add(pl) }
		
		let lib = RealmMediaLibrary()
		let notExistedPl = PlayList(uid: "notexisted", name: "test", items: [MediaItemMetadataType]())
		
		let clearedPl = lib.clearPlayList(notExistedPl)
		
		XCTAssertEqual(clearedPl.uid, notExistedPl.uid)
		XCTAssertEqual(realm.objects(RealmPlayList).first?.items.count, 2)
		XCTAssertEqual(realm.objects(RealmMediaItemMetadata).count, 2)
	}
	
	func testDeletePlayList() {
		let pl = RealmPlayList(uid: "testuid", name: "my play list")
		pl.items.append(RealmMediaItemMetadata(uid: "metauid1", title: "meta 1", album: "meta 1", artist: "meta 1", artwork: nil, duration: 0))
		pl.items.append(RealmMediaItemMetadata(uid: "metauid2", title: "meta 2", album: "meta 2", artist: "meta 2", artwork: nil, duration: 0))
		let realm = try! Realm()
		try! realm.write { realm.add(pl) }
		
		let lib = RealmMediaLibrary()
		let libPl = lib.getPlayListByUid("testuid")
		
		lib.deletePlayList(libPl!)
		
		XCTAssertEqual(realm.objects(RealmPlayList).count, 0)
		XCTAssertEqual(realm.objects(RealmMediaItemMetadata).count, 2)
	}
	
	func testRenamePlayList() {
		let pl = RealmPlayList(uid: "testuid", name: "my play list")
		pl.items.append(RealmMediaItemMetadata(uid: "metauid1", title: "meta 1", album: "meta 1", artist: "meta 1", artwork: nil, duration: 0))
		pl.items.append(RealmMediaItemMetadata(uid: "metauid2", title: "meta 2", album: "meta 2", artist: "meta 2", artwork: nil, duration: 0))
		let realm = try! Realm()
		try! realm.write { realm.add(pl) }
		
		let lib = RealmMediaLibrary()
		let libPl = lib.getPlayListByUid("testuid")
		
		let renamedPl = lib.renamePlayList(libPl!, newName: "renamed")
		
		XCTAssertEqual(renamedPl.name, "renamed")
		XCTAssertEqual(renamedPl.uid, "testuid")
		XCTAssertEqual(realm.objects(RealmPlayList).first?.name, renamedPl.name)
	}
	
	func testReturnAllPlayLists() {
		let pl1 = RealmPlayList(uid: "pluid1", name: "my play list")
		pl1.items.append(RealmMediaItemMetadata(uid: "metauid1", title: "meta 1", album: "meta 1", artist: "meta 1", artwork: nil, duration: 0))
		pl1.items.append(RealmMediaItemMetadata(uid: "metauid2", title: "meta 2", album: "meta 2", artist: "meta 2", artwork: nil, duration: 0))
		
		let pl2 = RealmPlayList(uid: "pluid2", name: "my play list")
		pl2.items.append(RealmMediaItemMetadata(uid: "metauid3", title: "meta 1", album: "meta 1", artist: "meta 1", artwork: nil, duration: 0))
		pl2.items.append(RealmMediaItemMetadata(uid: "metauid4", title: "meta 2", album: "meta 2", artist: "meta 2", artwork: nil, duration: 0))
		
		let pl3 = RealmPlayList(uid: "pluid3", name: "my play list")
		
		let realm = try! Realm()
		try! realm.write {
			realm.add(pl1)
			realm.add(pl2)
			realm.add(pl3)
		}
		
		let lib = RealmMediaLibrary()
		let allPls = lib.getAllPlayLists()
		
		XCTAssertEqual(allPls.count, 3)
		XCTAssertEqual(allPls.first?.items.count, 2)
		XCTAssertEqual(allPls.last?.items.count, 0)
	}
	
	func testRemoveItemFromPlayList() {
		let pl1 = RealmPlayList(uid: "pluid1", name: "my play list")
		pl1.items.append(RealmMediaItemMetadata(uid: "metauid1", title: "meta 1", album: "meta 1", artist: "meta 1", artwork: nil, duration: 0))
		pl1.items.append(RealmMediaItemMetadata(uid: "metauid2", title: "meta 2", album: "meta 2", artist: "meta 2", artwork: nil, duration: 0))
	
		let realm = try! Realm()
		try! realm.write { realm.add(pl1) }
		
		let lib = RealmMediaLibrary()
		let libPl = lib.getAllPlayLists().first!
		
		let newPl = lib.removeItemFromPlayList(libPl, item: libPl.items.first!)
		
		XCTAssertEqual(newPl.items.count, 1)
		XCTAssertEqual(newPl.items.first?.resourceUid, "metauid2")
		XCTAssertEqual(realm.objects(RealmMediaItemMetadata).count, 2)
		XCTAssertEqual(realm.objects(RealmPlayList).first?.items.count, 1)
	}
	
	func testNotRemoveNotBelongingItemFromPlayList() {
		let pl1 = RealmPlayList(uid: "pluid1", name: "my play list")
		pl1.items.append(RealmMediaItemMetadata(uid: "metauid1", title: "meta 1", album: "meta 1", artist: "meta 1", artwork: nil, duration: 0))
		pl1.items.append(RealmMediaItemMetadata(uid: "metauid2", title: "meta 2", album: "meta 2", artist: "meta 2", artwork: nil, duration: 0))
		
		let realm = try! Realm()
		try! realm.write {
			realm.add(pl1)
			realm.add(RealmMediaItemMetadata(uid: "metauid3", title: "meta 3", album: "meta 3", artist: "meta 3", artwork: nil, duration: 0))
		}
		
		let lib = RealmMediaLibrary()
		let libPl = lib.getAllPlayLists().first!
		
		let newPl = lib.removeItemFromPlayList(libPl, item: lib.getMetadata("metauid3")!)
		
		XCTAssertEqual(newPl.items.count, 2)
		XCTAssertEqual(realm.objects(RealmMediaItemMetadata).count, 3)
		XCTAssertEqual(realm.objects(RealmPlayList).first?.items.count, 2)
	}
	
	func testRemoveItemsFromPlayList() {
		let pl1 = RealmPlayList(uid: "pluid1", name: "my play list")
		pl1.items.append(RealmMediaItemMetadata(uid: "metauid1", title: "meta 1", album: "meta 1", artist: "meta 1", artwork: nil, duration: 0))
		pl1.items.append(RealmMediaItemMetadata(uid: "metauid2", title: "meta 2", album: "meta 2", artist: "meta 2", artwork: nil, duration: 0))
		
		let realm = try! Realm()
		try! realm.write { realm.add(pl1) }
		
		let lib = RealmMediaLibrary()
		let libPl = lib.getAllPlayLists().first!
		
		let newPl = lib.removeItemsFromPlayList(libPl, items: libPl.items)
		
		XCTAssertEqual(newPl.items.count, 0)
		XCTAssertEqual(realm.objects(RealmMediaItemMetadata).count, 2)
		XCTAssertEqual(realm.objects(RealmPlayList).first?.items.count, 0)
	}
	
	func testCorrectCheckExistedItemInPlayList() {
		let pl1 = RealmPlayList(uid: "pluid1", name: "my play list")
		pl1.items.append(RealmMediaItemMetadata(uid: "metauid1", title: "meta 1", album: "meta 1", artist: "meta 1", artwork: nil, duration: 0))
		pl1.items.append(RealmMediaItemMetadata(uid: "metauid2", title: "meta 2", album: "meta 2", artist: "meta 2", artwork: nil, duration: 0))
		
		let realm = try! Realm()
		try! realm.write { realm.add(pl1) }
		
		let lib = RealmMediaLibrary()
		let libPl = lib.getAllPlayLists().first!
		
		XCTAssertTrue(lib.isItemContainsInPlayList(libPl, item: libPl.items.first!))
	}
	
	func testCorrectCheckItemNotExistedInPlayList() {
		let pl1 = RealmPlayList(uid: "pluid1", name: "my play list")
		pl1.items.append(RealmMediaItemMetadata(uid: "metauid1", title: "meta 1", album: "meta 1", artist: "meta 1", artwork: nil, duration: 0))
		pl1.items.append(RealmMediaItemMetadata(uid: "metauid2", title: "meta 2", album: "meta 2", artist: "meta 2", artwork: nil, duration: 0))
		
		let realm = try! Realm()
		try! realm.write {
			realm.add(pl1)
			realm.add(RealmMediaItemMetadata(uid: "metauid3", title: "meta 3", album: "meta 3", artist: "meta 3", artwork: nil, duration: 0))
		}
		
		let lib = RealmMediaLibrary()
		let libPl = lib.getAllPlayLists().first!
		
		XCTAssertFalse(lib.isItemContainsInPlayList(libPl, item: lib.getMetadata("metauid3")!))
	}
}
