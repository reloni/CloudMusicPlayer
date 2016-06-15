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
		let track = try! lib.saveMetadata(metadata, updateExistedObjects: true)
		
		XCTAssertEqual(track?.uid, metadata.resourceUid)
		XCTAssertEqual(track?.album.name, metadata.album)
		XCTAssertEqual(track?.artist.name, metadata.artist)
		XCTAssertEqual(track?.album.artwork, metadata.artwork)
		XCTAssertEqual(track?.title, metadata.title)
		XCTAssertEqual(track?.duration, metadata.duration)
		
		let realm = try! Realm()
		let realmArtist = realm.objects(RealmArtist).first
		XCTAssertEqual(realmArtist?.name, metadata.artist)
		XCTAssertEqual(realmArtist?.albums.first?.name, metadata.album)
		XCTAssertEqual(realmArtist?.albums.first?.tracks.first?.title, metadata.title)
		XCTAssertEqual(realm.objects(RealmTrack).first?.album.name, metadata.album)
		XCTAssertEqual(realm.objects(RealmAlbum).first?.artist.name, metadata.artist)
		XCTAssertEqual(realm.objects(RealmArtist).count, 1)
		XCTAssertEqual(realm.objects(RealmAlbum).count, 1)
		XCTAssertEqual(realm.objects(RealmTrack).count, 1)
		XCTAssertEqual(realm.objects(RealmTrack).first?.album.name, metadata.album)
		XCTAssertEqual(realm.objects(RealmTrack).first?.album.tracks.first?.title, metadata.title)
		XCTAssertEqual(realm.objects(RealmAlbum).first?.artist.name, metadata.artist)
		XCTAssertEqual(realm.objects(RealmAlbum).first?.artist.albums.first?.name, metadata.album)
	}
	
	func testAddMetadataItemWithnknownArtist() {
		let metadata = MediaItemMetadata(resourceUid: "testuid", artist: nil, title: "Test title", album: "test album",
		                                 artwork: "test artwork".dataUsingEncoding(NSUTF8StringEncoding), duration: 1.56)
		let lib = RealmMediaLibrary() as MediaLibraryType
		let track = try! lib.saveMetadata(metadata, updateExistedObjects: true)
		
		XCTAssertEqual(track?.uid, metadata.resourceUid)
		XCTAssertEqual(track?.album.name, metadata.album)
		XCTAssertEqual(track?.artist.name, RealmMediaLibrary.unknownArtist.name)
		XCTAssertEqual(track?.album.artwork, metadata.artwork)
		XCTAssertEqual(track?.title, metadata.title)
		XCTAssertEqual(track?.duration, metadata.duration)
		
		let realm = try! Realm()
		let realmArtist = realm.objects(RealmArtist).first
		XCTAssertEqual(realmArtist?.name, RealmMediaLibrary.unknownArtist.name)
		XCTAssertEqual(realmArtist?.albums.first?.name, metadata.album)
		XCTAssertEqual(realmArtist?.albums.first?.tracks.first?.title, metadata.title)
		XCTAssertEqual(realm.objects(RealmTrack).first?.album.name, metadata.album)
		XCTAssertEqual(realm.objects(RealmAlbum).first?.artist.name, RealmMediaLibrary.unknownArtist.name)
		XCTAssertEqual(realm.objects(RealmArtist).count, 1)
		XCTAssertEqual(realm.objects(RealmAlbum).count, 1)
		XCTAssertEqual(realm.objects(RealmTrack).count, 1)
		XCTAssertEqual(realm.objects(RealmTrack).first?.album.name, metadata.album)
		XCTAssertEqual(realm.objects(RealmTrack).first?.album.tracks.first?.title, metadata.title)
		XCTAssertEqual(realm.objects(RealmAlbum).first?.artist.name, RealmMediaLibrary.unknownArtist.name)
		XCTAssertEqual(realm.objects(RealmAlbum).first?.artist.albums.first?.name, metadata.album)
		XCTAssertEqual(realm.objects(RealmArtist).first?.name, RealmMediaLibrary.unknownArtist.name)
		XCTAssertEqual(realm.objects(RealmArtist).first?.albums.first?.name, metadata.album)
	}
	
	func testAddMetadataItemWithnknownArtistAndAlbum() {
		let metadata = MediaItemMetadata(resourceUid: "testuid", artist: nil, title: "Test title", album: nil,
		                                 artwork: "test artwork".dataUsingEncoding(NSUTF8StringEncoding), duration: 1.56)
		let lib = RealmMediaLibrary() as MediaLibraryType
		let track = try! lib.saveMetadata(metadata, updateExistedObjects: true)
		
		XCTAssertEqual(track?.uid, metadata.resourceUid)
		XCTAssertEqual(track?.album.name, RealmMediaLibrary.unknownAlbum.name)
		XCTAssertEqual(track?.artist.name, RealmMediaLibrary.unknownArtist.name)
		XCTAssertEqual(track?.album.artwork, RealmMediaLibrary.unknownAlbum.artwork)
		XCTAssertEqual(track?.title, metadata.title)
		XCTAssertEqual(track?.duration, metadata.duration)
		
		let realm = try! Realm()
		let realmArtist = realm.objects(RealmArtist).first
		XCTAssertEqual(realmArtist?.name, RealmMediaLibrary.unknownArtist.name)
		XCTAssertEqual(realmArtist?.albums.first?.name, RealmMediaLibrary.unknownAlbum.name)
		XCTAssertEqual(realmArtist?.albums.first?.tracks.first?.title, metadata.title)
		XCTAssertEqual(realm.objects(RealmTrack).first?.album.name, RealmMediaLibrary.unknownAlbum.name)
		XCTAssertEqual(realm.objects(RealmAlbum).first?.artist.name, RealmMediaLibrary.unknownArtist.name)
		XCTAssertEqual(realm.objects(RealmArtist).count, 1)
		XCTAssertEqual(realm.objects(RealmAlbum).count, 1)
		XCTAssertEqual(realm.objects(RealmTrack).count, 1)
		XCTAssertEqual(realm.objects(RealmTrack).first?.album.name, RealmMediaLibrary.unknownAlbum.name)
		XCTAssertEqual(realm.objects(RealmTrack).first?.album.tracks.first?.title, metadata.title)
		XCTAssertEqual(realm.objects(RealmAlbum).first?.artist.name, RealmMediaLibrary.unknownArtist.name)
		XCTAssertEqual(realm.objects(RealmAlbum).first?.artist.albums.first?.name, RealmMediaLibrary.unknownAlbum.name)
	}
	
	func testCreateNewArtistAndAlbumForUpdatedTrack() {
		var metadata = MediaItemMetadata(resourceUid: "testuid", artist: "Test artist", title: "Test title", album: "test album",
		                                 artwork: "test artwork".dataUsingEncoding(NSUTF8StringEncoding), duration: 1.56)
		let lib = RealmMediaLibrary() as MediaLibraryType
		lib.saveMetadataSafe(metadata, updateExistedObjects: true)
	
		metadata.artist = "updated artist"
		metadata.title = "updated title"
		metadata.album = "updated album"
		metadata.artwork = "updated artwork".dataUsingEncoding(NSUTF8StringEncoding)
		metadata.duration = 2.65
		
		let updatedTrack = lib.saveMetadataSafe(metadata, updateExistedObjects: true)
		XCTAssertEqual(updatedTrack?.title, metadata.title)
		XCTAssertEqual(updatedTrack?.album.name, metadata.album)
		XCTAssertEqual(updatedTrack?.artist.name, metadata.artist)
		
		let realm = try! Realm()
		let realmTrack = realm.objects(RealmTrack).first
		XCTAssertEqual(realmTrack?.title, metadata.title)
		XCTAssertEqual(realmTrack?.duration, metadata.duration)
		XCTAssertEqual(realmTrack?.album.name, metadata.album)
		XCTAssertEqual(realmTrack?.album.artist.name, metadata.artist)
		XCTAssertEqual(realmTrack?.album.artwork, metadata.artwork)
		XCTAssertEqual(realm.objects(RealmTrack).first?.album.name, metadata.album)
		XCTAssertEqual(realm.objects(RealmArtist).count, 2)
		XCTAssertEqual(realm.objects(RealmAlbum).count, 2)
		XCTAssertEqual(realm.objects(RealmTrack).count, 1)
		XCTAssertEqual(realm.objects(RealmTrack).first?.album.name, metadata.album)
		XCTAssertEqual(realm.objects(RealmTrack).first?.album.tracks.first?.title, metadata.title)
		XCTAssertEqual(realm.objects(RealmAlbum).filter("name = %@", "test album").first?.tracks.count, 0)
		XCTAssertEqual(realm.objects(RealmAlbum).filter("name = %@", "test album").first?.artist.name, "Test artist")
	}
	
	func testCreateNewArtistAndAlbumForUpdatedTrackIfNowTrackBelongsToUnknownArtistAndAlbum() {
		var metadata = MediaItemMetadata(resourceUid: "testuid", artist: nil, title: "Test title", album: nil,
		                                 artwork: "test artwork".dataUsingEncoding(NSUTF8StringEncoding), duration: 1.56)
		let lib = RealmMediaLibrary() as MediaLibraryType
		lib.saveMetadataSafe(metadata, updateExistedObjects: true)
		
		metadata.artist = "updated artist"
		metadata.title = "updated title"
		metadata.album = "updated album"
		metadata.artwork = "updated artwork".dataUsingEncoding(NSUTF8StringEncoding)
		metadata.duration = 2.65
		
		let updatedTrack = lib.saveMetadataSafe(metadata, updateExistedObjects: true)
		XCTAssertEqual(updatedTrack?.title, metadata.title)
		XCTAssertEqual(updatedTrack?.album.name, metadata.album)
		XCTAssertEqual(updatedTrack?.artist.name, metadata.artist)
		
		let realm = try! Realm()
		let realmTrack = realm.objects(RealmTrack).first
		XCTAssertEqual(realmTrack?.title, metadata.title)
		XCTAssertEqual(realmTrack?.duration, metadata.duration)
		XCTAssertEqual(realmTrack?.album.name, metadata.album)
		XCTAssertEqual(realmTrack?.album.artist.name, metadata.artist)
		XCTAssertEqual(realmTrack?.album.artwork, metadata.artwork)
		XCTAssertEqual(realm.objects(RealmTrack).first?.album.name, metadata.album)
		XCTAssertEqual(realm.objects(RealmArtist).count, 2)
		XCTAssertEqual(realm.objects(RealmAlbum).count, 2)
		XCTAssertEqual(realm.objects(RealmTrack).count, 1)
		XCTAssertEqual(realm.objects(RealmTrack).first?.album.name, metadata.album)
		XCTAssertEqual(realm.objects(RealmTrack).first?.album.tracks.first?.title, metadata.title)
		XCTAssertEqual(realm.objects(RealmArtist).filter("uid = %@", RealmMediaLibrary.unknownArtist.uid).first?.albums.first?.tracks.count, 0)
		XCTAssertEqual(realm.objects(RealmArtist).filter("name = %@", metadata.artist!).first?.albums.first?.tracks.first?.title, metadata.title)
	}
	
	func testCreateNewArtistAndAlbumForUpdatedTrackEvenIfAlbumNameUnchanged() {
		var metadata = MediaItemMetadata(resourceUid: "testuid", artist: "Test artist", title: "Test title", album: "test album",
		                                 artwork: "test artwork".dataUsingEncoding(NSUTF8StringEncoding), duration: 1.56)
		let lib = RealmMediaLibrary() as MediaLibraryType
		lib.saveMetadataSafe(metadata, updateExistedObjects: true)
		
		metadata.artist = "updated artist"
		metadata.title = "updated title"
		metadata.artwork = "updated artwork".dataUsingEncoding(NSUTF8StringEncoding)
		metadata.duration = 2.65
		
		let updatedTrack = lib.saveMetadataSafe(metadata, updateExistedObjects: true)
		XCTAssertEqual(updatedTrack?.title, metadata.title)
		XCTAssertEqual(updatedTrack?.album.name, metadata.album)
		XCTAssertEqual(updatedTrack?.artist.name, metadata.artist)
		
		let realm = try! Realm()
		let realmTrack = realm.objects(RealmTrack).first
		XCTAssertEqual(realmTrack?.title, metadata.title)
		XCTAssertEqual(realmTrack?.duration, metadata.duration)
		XCTAssertEqual(realmTrack?.album.name, metadata.album)
		XCTAssertEqual(realmTrack?.album.artist.name, metadata.artist)
		XCTAssertEqual(realmTrack?.album.artwork, metadata.artwork)
		XCTAssertEqual(realm.objects(RealmTrack).first?.album.name, metadata.album)
		XCTAssertEqual(realm.objects(RealmArtist).count, 2)
		XCTAssertEqual(realm.objects(RealmAlbum).count, 2)
		XCTAssertEqual(realm.objects(RealmTrack).count, 1)
		XCTAssertEqual(realm.objects(RealmTrack).first?.album.name, metadata.album)
		XCTAssertEqual(realm.objects(RealmTrack).first?.album.tracks.first?.title, metadata.title)
		XCTAssertEqual(realm.objects(RealmAlbum).filter("name = %@", "test album").first?.tracks.count, 0)
		XCTAssertEqual(realm.objects(RealmAlbum).filter("name = %@", "test album").first?.artist.name, "Test artist")
		XCTAssertEqual(realm.objects(RealmAlbum).filter("name = %@", "test album").last?.artist.name, metadata.artist)
		XCTAssertEqual(realm.objects(RealmAlbum).filter("name = %@", "test album").count, 2)
	}
	
	func testCreateNewAlbumForUpdatedTrack() {
		var metadata = MediaItemMetadata(resourceUid: "testuid", artist: "Test artist", title: "Test title", album: "test album",
		                                 artwork: "test artwork".dataUsingEncoding(NSUTF8StringEncoding), duration: 1.56)
		let lib = RealmMediaLibrary() as MediaLibraryType
		lib.saveMetadataSafe(metadata, updateExistedObjects: true)
		
		metadata.title = "updated title"
		metadata.album = "updated album"
		metadata.artwork = "updated artwork".dataUsingEncoding(NSUTF8StringEncoding)
		metadata.duration = 2.65
		
		let updatedTrack = lib.saveMetadataSafe(metadata, updateExistedObjects: true)
		XCTAssertEqual(updatedTrack?.title, metadata.title)
		XCTAssertEqual(updatedTrack?.album.name, metadata.album)
		XCTAssertEqual(updatedTrack?.artist.name, metadata.artist)
		
		let realm = try! Realm()
		let realmTrack = realm.objects(RealmTrack).first
		XCTAssertEqual(realmTrack?.title, metadata.title)
		XCTAssertEqual(realmTrack?.duration, metadata.duration)
		XCTAssertEqual(realmTrack?.album.name, metadata.album)
		XCTAssertEqual(realmTrack?.album.artist.name, metadata.artist)
		XCTAssertEqual(realmTrack?.album.artwork, metadata.artwork)
		XCTAssertEqual(realm.objects(RealmTrack).first?.album.name, metadata.album)
		XCTAssertEqual(realm.objects(RealmArtist).count, 1)
		XCTAssertEqual(realm.objects(RealmAlbum).count, 2)
		XCTAssertEqual(realm.objects(RealmTrack).count, 1)
		XCTAssertEqual(realm.objects(RealmTrack).first?.album.name, metadata.album)
		XCTAssertEqual(realm.objects(RealmTrack).first?.album.tracks.first?.title, metadata.title)
		XCTAssertEqual(realm.objects(RealmAlbum).filter("name = %@", "test album").first?.tracks.count, 0)
		XCTAssertEqual(realm.objects(RealmAlbum).filter("name = %@", "test album").first?.artist.name, "Test artist")
	}
	
	func testNotUpdateExistedObjects() {
		var metadata = MediaItemMetadata(resourceUid: "testuid", artist: "Test artist", title: "Test title", album: "test album",
		                                 artwork: "test artwork".dataUsingEncoding(NSUTF8StringEncoding), duration: 1.56)
		let lib = RealmMediaLibrary() as MediaLibraryType
		lib.saveMetadataSafe(metadata, updateExistedObjects: false)
		
		metadata.artist = "updated artist"
		metadata.title = "updated title"
		metadata.album = "updated album"
		
		let updatedTrack = lib.saveMetadataSafe(metadata, updateExistedObjects: false)
		XCTAssertNotEqual(updatedTrack?.title, metadata.title)
		XCTAssertNotEqual(updatedTrack?.album.name, metadata.album)
		XCTAssertNotEqual(updatedTrack?.artist.name, metadata.artist)
		
		let realm = try! Realm()
		let realmArtist = realm.objects(RealmArtist).first
		XCTAssertNotEqual(realmArtist?.name, metadata.artist)
		XCTAssertNotEqual(realmArtist?.albums.first?.name, metadata.album)
		XCTAssertNotEqual(realmArtist?.albums.first?.tracks.first?.title, metadata.title)
		XCTAssertNotEqual(realm.objects(RealmTrack).first?.album.name, metadata.album)
		XCTAssertNotEqual(realm.objects(RealmAlbum).first?.artist.name, metadata.artist)
		XCTAssertEqual(realm.objects(RealmArtist).count, 1)
		XCTAssertEqual(realm.objects(RealmAlbum).count, 1)
		XCTAssertEqual(realm.objects(RealmTrack).count, 1)
		XCTAssertNotEqual(realm.objects(RealmTrack).first?.album.name, metadata.album)
		XCTAssertNotEqual(realm.objects(RealmTrack).first?.album.tracks.first?.title, metadata.title)
		XCTAssertNotEqual(realm.objects(RealmAlbum).first?.artist.name, metadata.artist)
		XCTAssertNotEqual(realm.objects(RealmAlbum).first?.artist.albums.first?.name, metadata.album)
	}
	
	func testReturnMetadata() {
		let metadata = MediaItemMetadata(resourceUid: "testuid", artist: "Test artist", title: "Test title", album: "test album",
		                                 artwork: "test artwork".dataUsingEncoding(NSUTF8StringEncoding), duration: 1.56)
		let lib = RealmMediaLibrary() as MediaLibraryType
		lib.saveMetadataSafe(metadata, updateExistedObjects: false)
		let libMetadata = try! lib.getMetadataObjectByUid(metadata.resourceUid)
		
		XCTAssertNotNil(libMetadata)
		XCTAssertEqual(libMetadata?.resourceUid, metadata.resourceUid)
		XCTAssertEqual(libMetadata?.album, metadata.album)
		XCTAssertEqual(libMetadata?.artist, metadata.artist)
		XCTAssertEqual(libMetadata?.artwork, metadata.artwork)
		XCTAssertEqual(libMetadata?.title, metadata.title)
		XCTAssertEqual(libMetadata?.duration, metadata.duration)
	}

	func testReturnNilIfMetadataNotExisted() {
		let metadata = MediaItemMetadata(resourceUid: "testuid", artist: "Test artist", title: "Test title", album: "test album",
		                                 artwork: "test artwork".dataUsingEncoding(NSUTF8StringEncoding), duration: 1.56)
		let lib = RealmMediaLibrary() as MediaLibraryType
		lib.saveMetadataSafe(metadata, updateExistedObjects: false)
		let libMetadata = try! lib.getMetadataObjectByUid("wronguid")
		
		XCTAssertNil(libMetadata)
	}

	func testCreatePlayList() {
		let lib = RealmMediaLibrary()
		let createdPl = try! lib.createPlayList("super play list")
		
		XCTAssertEqual(createdPl.name, "super play list")
		XCTAssertEqual(createdPl.items.count, 0)
		
		let realm = try! Realm()
		let realmPl = realm.objects(RealmPlayList).first
		
		XCTAssertNotNil(realmPl)
		XCTAssertEqual(realmPl?.name, createdPl.name)
		XCTAssertEqual(realmPl?.uid, createdPl.uid)
		XCTAssertEqual(realmPl?.items.count, createdPl.items.count)
	}

	func testReturnEmptyPlayListByUid() {
		let pl = RealmPlayList(uid: "testuid", name: "my play list")
		let realm = try! Realm()
		try! realm.write { realm.add(pl) }
		
		let lib = RealmMediaLibrary()
		let libPl = try! lib.getPlayListByUid("testuid")
		
		XCTAssertEqual(libPl?.name, pl.name)
		XCTAssertEqual(libPl?.items.count, 0)
	}

	func testReturnNilIfPlayListNotExistedByUid() {
		let pl = RealmPlayList(uid: "testuid", name: "my play list")
		let realm = try! Realm()
		try! realm.write { realm.add(pl) }
		
		let lib = RealmMediaLibrary()
		let libPl = try! lib.getPlayListByUid("wrong")
		
		XCTAssertNil(libPl)
	}

	func testCreatePlayListAndAddItems() {
		let lib = RealmMediaLibrary()
		
		try! lib.saveMetadata(MediaItemMetadata(resourceUid: "testuid1", artist: "Test artist1", title: "Test title1", album: "test album1",
			artwork: "test artwork1".dataUsingEncoding(NSUTF8StringEncoding), duration: 1.1), updateExistedObjects: true)
		try! lib.saveMetadata(MediaItemMetadata(resourceUid: "testuid2", artist: "Test artist2", title: "Test title2", album: "test album2",
			artwork: "test artwork2".dataUsingEncoding(NSUTF8StringEncoding), duration: 1.2), updateExistedObjects: true)
		try! lib.saveMetadata(MediaItemMetadata(resourceUid: "testuid3", artist: "Test artist3", title: "Test title3", album: "test album3",
			artwork: "test artwork3".dataUsingEncoding(NSUTF8StringEncoding), duration: 1.3), updateExistedObjects: true)
		
		let createdPl = try! lib.createPlayList("super play list")
	
		try! lib.addTracksToPlayList(createdPl, tracks: try! lib.getTracks().map { $0 })
		let realm = try! Realm()
		let realmPl = realm.objects(RealmPlayList).first
		
		XCTAssertEqual(realmPl?.items.count, 3)
	}
	
	func testNotAddExistedInPlayListItemsAgain() {
		let lib = RealmMediaLibrary()
		
		try! lib.saveMetadata(MediaItemMetadata(resourceUid: "testuid1", artist: "Test artist1", title: "Test title1", album: "test album1",
			artwork: "test artwork1".dataUsingEncoding(NSUTF8StringEncoding), duration: 1.1), updateExistedObjects: true)
		try! lib.saveMetadata(MediaItemMetadata(resourceUid: "testuid2", artist: "Test artist2", title: "Test title2", album: "test album2",
			artwork: "test artwork2".dataUsingEncoding(NSUTF8StringEncoding), duration: 1.2), updateExistedObjects: true)
		try! lib.saveMetadata(MediaItemMetadata(resourceUid: "testuid3", artist: "Test artist3", title: "Test title3", album: "test album3",
			artwork: "test artwork3".dataUsingEncoding(NSUTF8StringEncoding), duration: 1.3), updateExistedObjects: true)
		
		let createdPl = try! lib.createPlayList("super play list")
		
		try! lib.addTracksToPlayList(createdPl, tracks: try! lib.getTracks().map { $0 })
		try! lib.addTracksToPlayList(createdPl, tracks: try! lib.getTracks().map { $0 })
		
		let realm = try! Realm()
		let realmPl = realm.objects(RealmPlayList).first
		
		XCTAssertEqual(realmPl?.items.count, 3)
	}
	
	func testNotAddTracksToNotExistedPlayList() {
		let lib = RealmMediaLibrary()
		
		try! lib.saveMetadata(MediaItemMetadata(resourceUid: "testuid1", artist: "Test artist1", title: "Test title1", album: "test album1",
			artwork: "test artwork1".dataUsingEncoding(NSUTF8StringEncoding), duration: 1.1), updateExistedObjects: true)
		try! lib.saveMetadata(MediaItemMetadata(resourceUid: "testuid2", artist: "Test artist2", title: "Test title2", album: "test album2",
			artwork: "test artwork2".dataUsingEncoding(NSUTF8StringEncoding), duration: 1.2), updateExistedObjects: true)
		try! lib.saveMetadata(MediaItemMetadata(resourceUid: "testuid3", artist: "Test artist3", title: "Test title3", album: "test album3",
			artwork: "test artwork3".dataUsingEncoding(NSUTF8StringEncoding), duration: 1.3), updateExistedObjects: true)
		
		let createdPl = try! lib.createPlayList("super play list")
		try! lib.deletePlayList(createdPl)
		
		try! lib.addTracksToPlayList(createdPl, tracks: try! lib.getTracks().map { $0 })

		let realm = try! Realm()		
		XCTAssertEqual(realm.objects(RealmPlayList).count, 0)
	}
	
	func testReturnPlayListWithItemsByUid() {
		let lib = RealmMediaLibrary()
		
		try! lib.saveMetadata(MediaItemMetadata(resourceUid: "testuid1", artist: "Test artist1", title: "Test title1", album: "test album1",
			artwork: "test artwork1".dataUsingEncoding(NSUTF8StringEncoding), duration: 1.1), updateExistedObjects: true)
		try! lib.saveMetadata(MediaItemMetadata(resourceUid: "testuid2", artist: "Test artist2", title: "Test title2", album: "test album2",
			artwork: "test artwork2".dataUsingEncoding(NSUTF8StringEncoding), duration: 1.2), updateExistedObjects: true)
		let createdPl = try! lib.createPlayList("super play list")
		try! lib.addTracksToPlayList(createdPl, tracks: try! lib.getTracks().map { $0 })
		
		let libPl = try! lib.getPlayListByUid(createdPl.uid)
		
		XCTAssertEqual(libPl?.items.count, 2)
		XCTAssertEqual(createdPl.items.count, 2)
	}

	func testReturnSinglePlayListWithItemsByName() {
		let lib = RealmMediaLibrary()
		
		try! lib.saveMetadata(MediaItemMetadata(resourceUid: "testuid1", artist: "Test artist1", title: "Test title1", album: "test album1",
			artwork: "test artwork1".dataUsingEncoding(NSUTF8StringEncoding), duration: 1.1), updateExistedObjects: true)
		try! lib.saveMetadata(MediaItemMetadata(resourceUid: "testuid2", artist: "Test artist2", title: "Test title2", album: "test album2",
			artwork: "test artwork2".dataUsingEncoding(NSUTF8StringEncoding), duration: 1.2), updateExistedObjects: true)
		let createdPl = try! lib.createPlayList("super play list")
		try! lib.addTracksToPlayList(createdPl, tracks: try! lib.getTracks().map { $0 })
		try! lib.createPlayList("new pl")
		try! lib.createPlayList("new pl 2")
		let libPlayLists = try! lib.getPlayListsByName("super play list")
		
		XCTAssertEqual(libPlayLists.count, 1)
		XCTAssertEqual(libPlayLists.first?.items.count, 2)
	}

	func testClearMediaLibrary() {
		let lib = RealmMediaLibrary()
		
		try! lib.saveMetadata(MediaItemMetadata(resourceUid: "testuid1", artist: "Test artist1", title: "Test title1", album: "test album1",
			artwork: "test artwork1".dataUsingEncoding(NSUTF8StringEncoding), duration: 1.1), updateExistedObjects: true)
		try! lib.saveMetadata(MediaItemMetadata(resourceUid: "testuid2", artist: "Test artist2", title: "Test title2", album: "test album2",
			artwork: "test artwork2".dataUsingEncoding(NSUTF8StringEncoding), duration: 1.2), updateExistedObjects: true)
		try! lib.saveMetadata(MediaItemMetadata(resourceUid: "testuid3", artist: "Test artist2", title: "Test title3", album: "test album2",
			artwork: "test artwork2".dataUsingEncoding(NSUTF8StringEncoding), duration: 1.2), updateExistedObjects: true)
		let createdPl = try! lib.createPlayList("super play list")
		try! lib.addTracksToPlayList(createdPl, tracks: try! lib.getTracks().map { $0 })
		try! lib.createPlayList("new pl")
		try! lib.createPlayList("new pl 2")
		
		let realm = try! Realm()
		
		XCTAssertEqual(realm.objects(RealmArtist).count, 2)
		XCTAssertEqual(realm.objects(RealmAlbum).count, 2)
		XCTAssertEqual(realm.objects(RealmTrack).count, 3)
		XCTAssertEqual(realm.objects(RealmPlayList).count, 3)
		
		try! lib.clearLibrary()
		
		XCTAssertEqual(realm.objects(RealmArtist).count, 0)
		XCTAssertEqual(realm.objects(RealmAlbum).count, 0)
		XCTAssertEqual(realm.objects(RealmTrack).count, 0)
		XCTAssertEqual(realm.objects(RealmPlayList).count, 0)
	}

	func testCorrectCheckExistedMetadata() {
		let metadata = MediaItemMetadata(resourceUid: "testuid", artist: "Test artist", title: "Test title", album: "test album",
		                                 artwork: "test artwork".dataUsingEncoding(NSUTF8StringEncoding), duration: 1.56)
		let lib = RealmMediaLibrary() as MediaLibraryType
		try! lib.saveMetadata(metadata, updateExistedObjects: false)
		
		XCTAssertTrue(try! lib.isTrackExists(metadata.resourceUid))
	}
	
	func testCorrectCheckNotExistedMetadata() {
		let metadata = MediaItemMetadata(resourceUid: "testuid", artist: "Test artist", title: "Test title", album: "test album",
		                                 artwork: "test artwork".dataUsingEncoding(NSUTF8StringEncoding), duration: 1.56)
		let lib = RealmMediaLibrary() as MediaLibraryType
		try! lib.saveMetadata(metadata, updateExistedObjects: false)
		
		XCTAssertFalse(try! lib.isTrackExists("not existed"))
	}

	func testClearPlayList() {
		let lib = RealmMediaLibrary()
		
		try! lib.saveMetadata(MediaItemMetadata(resourceUid: "testuid1", artist: "Test artist1", title: "Test title1", album: "test album1",
			artwork: "test artwork1".dataUsingEncoding(NSUTF8StringEncoding), duration: 1.1), updateExistedObjects: true)
		try! lib.saveMetadata(MediaItemMetadata(resourceUid: "testuid2", artist: "Test artist2", title: "Test title2", album: "test album2",
			artwork: "test artwork2".dataUsingEncoding(NSUTF8StringEncoding), duration: 1.2), updateExistedObjects: true)
		try! lib.saveMetadata(MediaItemMetadata(resourceUid: "testuid3", artist: "Test artist2", title: "Test title3", album: "test album2",
			artwork: "test artwork2".dataUsingEncoding(NSUTF8StringEncoding), duration: 1.2), updateExistedObjects: true)
		let createdPl = try! lib.createPlayList("super play list")
		try! lib.addTracksToPlayList(createdPl, tracks: try! lib.getTracks().map { $0 })
		
		XCTAssertEqual(createdPl.items.count, 3)
		try! lib.clearPlayList(createdPl)
		XCTAssertEqual(createdPl.items.count, 0)
		
		let realm = try! Realm()
		XCTAssertEqual(realm.objects(RealmPlayList).first?.items.count, 0)
		XCTAssertEqual(realm.objects(RealmTrack).count, 3)
	}

	func testNotClearNotExistedPlayList() {
		let lib = RealmMediaLibrary()
		
		try! lib.saveMetadata(MediaItemMetadata(resourceUid: "testuid1", artist: "Test artist1", title: "Test title1", album: "test album1",
			artwork: "test artwork1".dataUsingEncoding(NSUTF8StringEncoding), duration: 1.1), updateExistedObjects: true)
		try! lib.saveMetadata(MediaItemMetadata(resourceUid: "testuid2", artist: "Test artist2", title: "Test title2", album: "test album2",
			artwork: "test artwork2".dataUsingEncoding(NSUTF8StringEncoding), duration: 1.2), updateExistedObjects: true)
		try! lib.saveMetadata(MediaItemMetadata(resourceUid: "testuid3", artist: "Test artist2", title: "Test title3", album: "test album2",
			artwork: "test artwork2".dataUsingEncoding(NSUTF8StringEncoding), duration: 1.2), updateExistedObjects: true)
		let createdPl = try! lib.createPlayList("super play list")
		try! lib.addTracksToPlayList(createdPl, tracks: try! lib.getTracks().map { $0 })
		
		try! lib.clearPlayList(RealmPlayList(uid: "not existed in db", name: "test"))
		
		let realm = try! Realm()
		XCTAssertEqual(realm.objects(RealmPlayList).count, 1)
		XCTAssertEqual(realm.objects(RealmPlayList).first?.items.count, 3)
		XCTAssertEqual(realm.objects(RealmTrack).count, 3)
	}

	func testDeletePlayList() {
		let lib = RealmMediaLibrary()
		
		try! lib.saveMetadata(MediaItemMetadata(resourceUid: "testuid1", artist: "Test artist1", title: "Test title1", album: "test album1",
			artwork: "test artwork1".dataUsingEncoding(NSUTF8StringEncoding), duration: 1.1), updateExistedObjects: true)
		try! lib.saveMetadata(MediaItemMetadata(resourceUid: "testuid2", artist: "Test artist2", title: "Test title2", album: "test album2",
			artwork: "test artwork2".dataUsingEncoding(NSUTF8StringEncoding), duration: 1.2), updateExistedObjects: true)
		try! lib.saveMetadata(MediaItemMetadata(resourceUid: "testuid3", artist: "Test artist2", title: "Test title3", album: "test album2",
			artwork: "test artwork2".dataUsingEncoding(NSUTF8StringEncoding), duration: 1.2), updateExistedObjects: true)
		let createdPl = try! lib.createPlayList("super play list")
		try! lib.addTracksToPlayList(createdPl, tracks: try! lib.getTracks().map { $0 })
		
		try! lib.deletePlayList(createdPl)
		
		let realm = try! Realm()
		XCTAssertEqual(realm.objects(RealmPlayList).count, 0)
		XCTAssertEqual(realm.objects(RealmTrack).count, 3)
	}

	func testRenamePlayList() {
		let lib = RealmMediaLibrary()
		
		try! lib.saveMetadata(MediaItemMetadata(resourceUid: "testuid1", artist: "Test artist1", title: "Test title1", album: "test album1",
			artwork: "test artwork1".dataUsingEncoding(NSUTF8StringEncoding), duration: 1.1), updateExistedObjects: true)
		try! lib.saveMetadata(MediaItemMetadata(resourceUid: "testuid2", artist: "Test artist2", title: "Test title2", album: "test album2",
			artwork: "test artwork2".dataUsingEncoding(NSUTF8StringEncoding), duration: 1.2), updateExistedObjects: true)
		try! lib.saveMetadata(MediaItemMetadata(resourceUid: "testuid3", artist: "Test artist2", title: "Test title3", album: "test album2",
			artwork: "test artwork2".dataUsingEncoding(NSUTF8StringEncoding), duration: 1.2), updateExistedObjects: true)
		let createdPl = try! lib.createPlayList("super play list")
		try! lib.addTracksToPlayList(createdPl, tracks: try! lib.getTracks().map { $0 })
		
		try! lib.renamePlayList(createdPl, newName: "renamed")
		
		XCTAssertEqual(createdPl.name, "renamed")
		let realm = try! Realm()
		XCTAssertEqual(realm.objects(RealmPlayList).first?.name, createdPl.name)
	}

	func testReturnAllPlayLists() {
		let lib = RealmMediaLibrary()
		
		try! lib.saveMetadata(MediaItemMetadata(resourceUid: "testuid1", artist: "Test artist1", title: "Test title1", album: "test album1",
			artwork: "test artwork1".dataUsingEncoding(NSUTF8StringEncoding), duration: 1.1), updateExistedObjects: true)
		try! lib.saveMetadata(MediaItemMetadata(resourceUid: "testuid2", artist: "Test artist2", title: "Test title2", album: "test album2",
			artwork: "test artwork2".dataUsingEncoding(NSUTF8StringEncoding), duration: 1.2), updateExistedObjects: true)
		try! lib.saveMetadata(MediaItemMetadata(resourceUid: "testuid3", artist: "Test artist2", title: "Test title3", album: "test album2",
			artwork: "test artwork2".dataUsingEncoding(NSUTF8StringEncoding), duration: 1.2), updateExistedObjects: true)
		let createdPl = try! lib.createPlayList("super play list")
		try! lib.addTracksToPlayList(createdPl, tracks: try! lib.getTracks().map { $0 })
		
		try! lib.createPlayList("super play list 2")
		try! lib.createPlayList("super play list 3")
		
		let allPls = try! lib.getPlayLists()
		
		XCTAssertEqual(allPls.count, 3)
		XCTAssertEqual(allPls.first?.items.count, 3)
		XCTAssertEqual(allPls.last?.items.count, 0)
	}

	func testRemoveItemFromPlayList() {
		let lib = RealmMediaLibrary()
		
		try! lib.saveMetadata(MediaItemMetadata(resourceUid: "testuid1", artist: "Test artist1", title: "Test title1", album: "test album1",
			artwork: "test artwork1".dataUsingEncoding(NSUTF8StringEncoding), duration: 1.1), updateExistedObjects: true)
		try! lib.saveMetadata(MediaItemMetadata(resourceUid: "testuid2", artist: "Test artist2", title: "Test title2", album: "test album2",
			artwork: "test artwork2".dataUsingEncoding(NSUTF8StringEncoding), duration: 1.2), updateExistedObjects: true)
		try! lib.saveMetadata(MediaItemMetadata(resourceUid: "testuid3", artist: "Test artist2", title: "Test title3", album: "test album2",
			artwork: "test artwork2".dataUsingEncoding(NSUTF8StringEncoding), duration: 1.2), updateExistedObjects: true)
		let createdPl = try! lib.createPlayList("super play list")
		try! lib.addTracksToPlayList(createdPl, tracks: try! lib.getTracks().map { $0 })
		
		try! lib.removeTrackFromPlayList(createdPl, track: createdPl.items.first!)
		
		XCTAssertEqual(createdPl.items.count, 2)
		XCTAssertEqual(createdPl.items.first?.uid, "testuid2")
		let realm = try! Realm()
		XCTAssertEqual(realm.objects(RealmTrack).count, 3)
		XCTAssertEqual(realm.objects(RealmPlayList).first?.items.count, 2)
	}

	func testNotRemoveNotBelongingItemFromPlayList() {
		let lib = RealmMediaLibrary()
		
		try! lib.saveMetadata(MediaItemMetadata(resourceUid: "testuid1", artist: "Test artist1", title: "Test title1", album: "test album1",
			artwork: "test artwork1".dataUsingEncoding(NSUTF8StringEncoding), duration: 1.1), updateExistedObjects: true)
		try! lib.saveMetadata(MediaItemMetadata(resourceUid: "testuid2", artist: "Test artist2", title: "Test title2", album: "test album2",
			artwork: "test artwork2".dataUsingEncoding(NSUTF8StringEncoding), duration: 1.2), updateExistedObjects: true)
		
		let createdPl = try! lib.createPlayList("super play list")
		try! lib.addTracksToPlayList(createdPl, tracks: try! lib.getTracks().map { $0 })

		try! lib.saveMetadata(MediaItemMetadata(resourceUid: "testuid3", artist: "Test artist2", title: "Test title3", album: "test album2",
			artwork: "test artwork2".dataUsingEncoding(NSUTF8StringEncoding), duration: 1.2), updateExistedObjects: true)
		
		try! lib.removeTrackFromPlayList(createdPl, track: try! lib.getTrackByUid("testuid3")!)
		
		XCTAssertEqual(createdPl.items.count, 2)
		let realm = try! Realm()
		XCTAssertEqual(realm.objects(RealmTrack).count, 3)
		XCTAssertEqual(realm.objects(RealmPlayList).first?.items.count, 2)
	}

	func testRemoveItemsFromPlayList() {
		let lib = RealmMediaLibrary()
		
		try! lib.saveMetadata(MediaItemMetadata(resourceUid: "testuid1", artist: "Test artist1", title: "Test title1", album: "test album1",
			artwork: "test artwork1".dataUsingEncoding(NSUTF8StringEncoding), duration: 1.1), updateExistedObjects: true)
		try! lib.saveMetadata(MediaItemMetadata(resourceUid: "testuid2", artist: "Test artist2", title: "Test title2", album: "test album2",
			artwork: "test artwork2".dataUsingEncoding(NSUTF8StringEncoding), duration: 1.2), updateExistedObjects: true)
		try! lib.saveMetadata(MediaItemMetadata(resourceUid: "testuid3", artist: "Test artist2", title: "Test title3", album: "test album2",
			artwork: "test artwork2".dataUsingEncoding(NSUTF8StringEncoding), duration: 1.2), updateExistedObjects: true)
		let createdPl = try! lib.createPlayList("super play list")
		try! lib.addTracksToPlayList(createdPl, tracks: try! lib.getTracks().map { $0 })
		
		try! lib.removeTracksFromPlayList(createdPl, tracks: createdPl.items.map { $0 })
		
		XCTAssertEqual(createdPl.items.count, 0)
		let realm = try! Realm()
		XCTAssertEqual(realm.objects(RealmTrack).count, 3)
		XCTAssertEqual(realm.objects(RealmPlayList).first?.items.count, 0)
	}

	func testCorrectCheckExistedItemInPlayList() {
		let lib = RealmMediaLibrary()
		
		try! lib.saveMetadata(MediaItemMetadata(resourceUid: "testuid1", artist: "Test artist1", title: "Test title1", album: "test album1",
			artwork: "test artwork1".dataUsingEncoding(NSUTF8StringEncoding), duration: 1.1), updateExistedObjects: true)
		try! lib.saveMetadata(MediaItemMetadata(resourceUid: "testuid2", artist: "Test artist2", title: "Test title2", album: "test album2",
			artwork: "test artwork2".dataUsingEncoding(NSUTF8StringEncoding), duration: 1.2), updateExistedObjects: true)
		try! lib.saveMetadata(MediaItemMetadata(resourceUid: "testuid3", artist: "Test artist2", title: "Test title3", album: "test album2",
			artwork: "test artwork2".dataUsingEncoding(NSUTF8StringEncoding), duration: 1.2), updateExistedObjects: true)
		let createdPl = try! lib.createPlayList("super play list")
		try! lib.addTracksToPlayList(createdPl, tracks: try! lib.getTracks().map { $0 })
		
		XCTAssertTrue(try! lib.isTrackContainsInPlayList(createdPl, track: createdPl.items.first!))
	}
	
	func testCorrectCheckItemNotExistedInPlayList() {
		let lib = RealmMediaLibrary()
		
		try! lib.saveMetadata(MediaItemMetadata(resourceUid: "testuid1", artist: "Test artist1", title: "Test title1", album: "test album1",
			artwork: "test artwork1".dataUsingEncoding(NSUTF8StringEncoding), duration: 1.1), updateExistedObjects: true)
		try! lib.saveMetadata(MediaItemMetadata(resourceUid: "testuid2", artist: "Test artist2", title: "Test title2", album: "test album2",
			artwork: "test artwork2".dataUsingEncoding(NSUTF8StringEncoding), duration: 1.2), updateExistedObjects: true)
		let createdPl = try! lib.createPlayList("super play list")
		try! lib.addTracksToPlayList(createdPl, tracks: try! lib.getTracks().map { $0 })
		try! lib.saveMetadata(MediaItemMetadata(resourceUid: "testuid3", artist: "Test artist2", title: "Test title3", album: "test album2",
			artwork: "test artwork2".dataUsingEncoding(NSUTF8StringEncoding), duration: 1.2), updateExistedObjects: true)
		
		XCTAssertFalse(try! lib.isTrackContainsInPlayList(createdPl, track: try! lib.getTrackByUid("testuid3")!))
	}
	
	func testReturnAllArtists() {
		let lib = RealmMediaLibrary()
		
		try! lib.saveMetadata(MediaItemMetadata(resourceUid: "testuid1", artist: "Test artist1", title: "Test title1", album: "test album1",
			artwork: "test artwork1".dataUsingEncoding(NSUTF8StringEncoding), duration: 1.1), updateExistedObjects: true)
		try! lib.saveMetadata(MediaItemMetadata(resourceUid: "testuid2", artist: "Test artist2", title: "Test title2", album: "test album2",
			artwork: "test artwork2".dataUsingEncoding(NSUTF8StringEncoding), duration: 1.2), updateExistedObjects: true)
		let createdPl = try! lib.createPlayList("super play list")
		try! lib.addTracksToPlayList(createdPl, tracks: try! lib.getTracks().map { $0 })
		try! lib.saveMetadata(MediaItemMetadata(resourceUid: "testuid3", artist: "Test artist2", title: "Test title3", album: "test album2",
			artwork: "test artwork2".dataUsingEncoding(NSUTF8StringEncoding), duration: 1.2), updateExistedObjects: true)
		try! lib.saveMetadata(MediaItemMetadata(resourceUid: "testuid4", artist: nil, title: "Test title3", album: "test album2",
			artwork: "test artwork2".dataUsingEncoding(NSUTF8StringEncoding), duration: 1.2), updateExistedObjects: true)
		
		XCTAssertEqual(try! lib.getArtists().count, 3)
	}
	
	func testReturnAllAlbums() {
		let lib = RealmMediaLibrary()
		
		try! lib.saveMetadata(MediaItemMetadata(resourceUid: "testuid1", artist: "Test artist1", title: "Test title1", album: "test album1",
			artwork: "test artwork1".dataUsingEncoding(NSUTF8StringEncoding), duration: 1.1), updateExistedObjects: true)
		try! lib.saveMetadata(MediaItemMetadata(resourceUid: "testuid2", artist: "Test artist2", title: "Test title2", album: "test album2",
			artwork: "test artwork2".dataUsingEncoding(NSUTF8StringEncoding), duration: 1.2), updateExistedObjects: true)
		let createdPl = try! lib.createPlayList("super play list")
		try! lib.addTracksToPlayList(createdPl, tracks: try! lib.getTracks().map { $0 })
		try! lib.saveMetadata(MediaItemMetadata(resourceUid: "testuid3", artist: "Test artist2", title: "Test title3", album: "test album2",
			artwork: "test artwork2".dataUsingEncoding(NSUTF8StringEncoding), duration: 1.2), updateExistedObjects: true)
		try! lib.saveMetadata(MediaItemMetadata(resourceUid: "testuid4", artist: nil, title: "Test title3", album: "test album2",
			artwork: "test artwork2".dataUsingEncoding(NSUTF8StringEncoding), duration: 1.2), updateExistedObjects: true)
		
		XCTAssertEqual(try! lib.getAlbums().count, 3)
	}
	
	func testNotCreatePlayListWithEmptyName() {
		let lib = RealmMediaLibrary()
		do {
			try lib.createPlayList("")
		}
		catch {
			guard let error = error as? CustomErrorType else {
				XCTFail("Should throw correct exception")
				return
			}
			XCTAssertEqual(error.errorCode(), MediaLibraryErroros.emptyPlayListName.errorCode())
		}
		let realm = try! Realm()
		XCTAssertEqual(0, realm.objects(RealmPlayList).count)
	}
	
	func testAccessFromAnotherThread() {
		let lib = RealmMediaLibrary()
		
		try! lib.saveMetadata(MediaItemMetadata(resourceUid: "testuid1", artist: "Test artist1", title: "Test title1", album: "test album1",
			artwork: "test artwork1".dataUsingEncoding(NSUTF8StringEncoding), duration: 1.1), updateExistedObjects: true)

		let track = try! lib.getTracks().first!
		let album = try! lib.getAlbums().first!
		let artist = try! lib.getArtists().first!
		
		let pl = try! lib.createPlayList("test pl")

		try! lib.addTracksToPlayList(pl, tracks: [track])
		
		let expectation = expectationWithDescription("Access from another thread")

		DispatchQueue.async(.Utility) {
			// trying to access properties
			// if synchronization don't work exception will be thrown
			
			let _ = track.synchronize().album.artist.name
			let _ = track.synchronize().artist.name
			let _ = track.synchronize().artist.albums.count
			let _ = album.synchronize().artist.name
			let _ = album.synchronize().tracks.count
			let _ = artist.synchronize().albums.count
			let _ = artist.synchronize().name
			let _ = pl.synchronize().items.count
			let _ = pl.synchronize().name
			
			expectation.fulfill()
		}
		
		waitForExpectationsWithTimeout(1, handler: nil)
	}
	
	func testSequence() {
		let lib = RealmMediaLibrary()
		
		try! lib.saveMetadata(MediaItemMetadata(resourceUid: "testuid1", artist: "Test artist1", title: "Test title1", album: "test album1",
			artwork: "test artwork1".dataUsingEncoding(NSUTF8StringEncoding), duration: 1.1), updateExistedObjects: true)
		
		let album = try! lib.getAlbums().first!
		let artist = try! lib.getArtists().first!
		
		XCTAssertEqual("Test title1", album.tracks.map { $0.title }.first)
		XCTAssertEqual("test album1", artist.albums.map { $0.name }.first)
	}
}
