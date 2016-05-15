//
//  RealmMediaLibrary.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 30.04.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import Realm
import RealmSwift

public class RealmMediaLibrary {
	public init() { }
	
	internal func getRealm() throws -> Realm {
		return try Realm()
	}
	
//	internal lazy var unknownArtist: RealmArtist = { [unowned self] in
//		guard let artist = try! self.getRealm().objects(RealmArtist).filter("uid = %@", "unknown_artist").first else {
//			return RealmArtist(uid: "unknown_artist", name: "Unknown artist")
//		}
//		return artist
//	}()
//	
//	internal lazy var unknownAlbum: RealmAlbum = { [unowned self] in
//		guard let album = try! self.getRealm().objects(RealmAlbum).filter("uid = %@", "unknown_album").first else {
//			let album = RealmAlbum(uid: "unknown_album", name: "Unknown album")
//			album.artistInternal = self.unknownArtist
//			return album
//		}
//		return album
//	}()
	
	internal func getOrCreateArtist(realm: Realm, name: String) throws -> RealmArtist {
		if let artist = realm.objects(RealmArtist).filter("name = %@", name).first {
			return artist
		} else {
			let artist = RealmArtist(uid: NSUUID().UUIDString, name: name)
			realm.add(artist)
			return artist
		}
	}
	
	internal func getOrCreateAlbum(realm: Realm, name: String, artwork: NSData?, artistName: String, updateIfExisted: Bool) throws -> RealmAlbum {
		if let album = realm.objects(RealmAlbum).filter("name = %@", name).first {
			if updateIfExisted {
				album.artwork = artwork
			}
			return album
		} else {
			let album = RealmAlbum(uid: NSUUID().UUIDString, name: name)
			album.artwork = artwork
			album.artistInternal = try getOrCreateArtist(realm, name: artistName)
			album.artistInternal?.albumsInternal.append(album)
			realm.add(album)
			return album
		}
	}
	
	internal func getOrCreateTrack(realm: Realm, metadata: MediaItemMetadataType, updateIfExisted: Bool) throws -> RealmTrack {		
		if let track = realm.objects(RealmTrack).filter("uid = %@", metadata.resourceUid).first {
			if updateIfExisted {
				if let title = metadata.title { track.title = title }
				if let duration = metadata.duration { track.duration = duration }
				if let albumName = metadata.album { track.albumInternal?.name = albumName }
				if let artistName = metadata.artist { track.albumInternal?.artistInternal?.name = artistName }
			}
			return track
		} else {
			let track = RealmTrack(uid: metadata.resourceUid, title: metadata.title ?? "Unknown title", duration: metadata.duration ?? 0)
			let album = try getOrCreateAlbum(realm, name: metadata.album ?? "Unknown album", artwork: metadata.artwork,
			                                 artistName: metadata.artist ?? "Unknown artist", updateIfExisted: updateIfExisted)

			track.albumInternal = album
			album.tracksInternal.append(track); realm.add(track)
			return track
		}
	}
}

extension RealmMediaLibrary : MediaLibraryType {
	public func getArtists() throws -> MediaCollection<ArtistType, RealmArtist> {
		return try MediaCollection<ArtistType, RealmArtist>(realmCollection: AnyRealmCollection(getRealm().objects(RealmArtist)))
	}
	
	public func getAlbums() throws -> MediaCollection<AlbumType, RealmAlbum> {
		return try MediaCollection<AlbumType, RealmAlbum>(realmCollection: AnyRealmCollection(getRealm().objects(RealmAlbum)))
	}
	
	public func getTracks() throws -> MediaCollection<TrackType, RealmTrack> {
		return try MediaCollection<TrackType, RealmTrack>(realmCollection: AnyRealmCollection(getRealm().objects(RealmTrack)))
	}
	
	public func getPlayLists() throws -> MediaCollection<PlayListType, RealmPlayList> {
		return try MediaCollection<PlayListType, RealmPlayList>(realmCollection: AnyRealmCollection(getRealm().objects(RealmPlayList)))
	}
	
	public func clearLibrary() throws {
		let realm = try getRealm()
		try realm.write {
			realm.delete(realm.objects(RealmTrack))
			realm.delete(realm.objects(RealmAlbum))
			realm.delete(realm.objects(RealmArtist))
			realm.delete(realm.objects(RealmPlayList))
		}
	}
	
	public func isTrackExists(resource: StreamResourceIdentifier) throws -> Bool {
		return try getRealm().objects(RealmTrack).filter("uid = %@", resource.streamResourceUid).count > 0
	}
	
	public func getTrackByUid(resource: StreamResourceIdentifier) throws -> TrackType? {
		return try getRealm().objects(RealmTrack).filter("uid = %@", resource.streamResourceUid).first
	}
	
	public func getMetadataObjectByUid(resource: StreamResourceIdentifier) throws -> MediaItemMetadata? {
		guard let track = try getTrackByUid(resource) else { return nil }
		return MediaItemMetadata(resourceUid: track.uid,
		                         artist: track.artist.name,
		                         title: track.title,
		                         album: track.album.name,
		                         artwork: track.album.artwork,
		                         duration: track.duration)
	}
	
	public func saveMetadata(metadata: MediaItemMetadataType, updateExistedObjects: Bool) throws -> TrackType? {
		let realm = try getRealm()
		realm.beginWrite()
		let track = try getOrCreateTrack(realm, metadata: metadata, updateIfExisted: updateExistedObjects)
		try realm.commitWrite()
		return track
	}
	
	public func saveMetadataSafe(metadata: MediaItemMetadataType, updateExistedObjects: Bool) -> TrackType? {
		do {
			return try saveMetadata(metadata, updateExistedObjects: updateExistedObjects)
		} catch {
			return nil
		}
	}
	
	public func createPlayList(name: String) throws -> PlayListType {
		let realm = try getRealm()
		let playList = RealmPlayList(uid: NSUUID().UUIDString, name: name)
		try realm.write { realm.add(playList) }
		return playList
	}
	
	public func clearPlayList(playList: PlayListType) throws {
		let realm = try getRealm()
		
		guard let realmPlayList = realm.objects(RealmPlayList).filter("uid = %@", playList.uid).first else { return }
		try realm.write { realmPlayList.itemsInternal.removeAll() }
	}
	
	public func deletePlayList(playList: PlayListType) throws {
		let realm = try getRealm()
		
		guard let realmPlayList = realm.objects(RealmPlayList).filter("uid = %@", playList.uid).first else { return }
		try realm.write { realm.delete(realmPlayList) }
	}
	
	public func addTracksToPlayList(playList: PlayListType, tracks: [TrackType]) throws -> PlayListType {
		let realm = try getRealm()
		
		guard let realmPlayList = realm.objects(RealmPlayList).filter("uid = %@", playList.uid).first else { return playList }
		
		try realm.write {
			tracks.forEach { track in
				if let realmTrack = track as? RealmTrack {
					realmPlayList.itemsInternal.append(realmTrack)
				}
			}
			
		}
		return realmPlayList
	}
	
	public func removeTrackFromPlayList(playList: PlayListType, track: TrackType) throws -> PlayListType {
		return try removeTracksFromPlayList(playList, tracks: [track])
	}
	
	public func removeTracksFromPlayList(playList: PlayListType, tracks: [TrackType]) throws -> PlayListType {
		let realm = try getRealm()
		
		guard let realmPlayList = realm.objects(RealmPlayList).filter("uid = %@", playList.uid).first else { return playList }
		
		try realm.write {
			tracks.forEach { track in
				if let realmMetadataItemIndex = realmPlayList.itemsInternal.indexOf("uid = %@", track.uid) {
					realmPlayList.itemsInternal.removeAtIndex(realmMetadataItemIndex)
				}
			}
		}
		
		return realmPlayList
	}
	
	public func isTrackContainsInPlayList(playList: PlayListType, track: TrackType) throws -> Bool {
		guard let realmPlayList = try getRealm().objects(RealmPlayList).filter("uid = %@", playList.uid).first else { return false }
		return realmPlayList.itemsInternal.filter("uid = %@", track.uid).count > 0
	}
	
	public func getPlayListByUid(uid: String) throws -> PlayListType? {
		return try getRealm().objects(RealmPlayList).filter("uid = %@", uid).first
	}
	
	public func getPlayListsByName(name: String) throws -> [PlayListType] {
		return try getRealm().objects(RealmPlayList).filter("name = %@", name).map { $0 }
	}
	
	public func renamePlayList(playList: PlayListType, newName: String) throws {
		guard let realmPl = try getPlayListByUid(playList.uid) else { return }
		try getRealm().write {
			var pl = realmPl
			pl.name = newName
		}
	}
}

public class RealmArtist: Object, ArtistType {
	public internal(set) dynamic var uid: String
	public internal(set) dynamic var name: String
	public let albumsInternal = List<RealmAlbum>()
	
	public var albums: MediaCollection<AlbumType, RealmAlbum> {
		return MediaCollection<AlbumType, RealmAlbum>(realmCollection: AnyRealmCollection(albumsInternal))
	}
	
	required public init(uid: String, name: String) {
		self.uid = uid
		self.name = name
		super.init()
	}
	
	public required init(realm: RLMRealm, schema: RLMObjectSchema) {
		uid = NSUUID().UUIDString
		name = ""
		super.init(realm: realm, schema: schema)
	}
	
	public required init(value: AnyObject, schema: RLMSchema) {
		uid = NSUUID().UUIDString
		name = ""
		super.init(value: value, schema: schema)
	}
	
	public required init() {
		uid = NSUUID().UUIDString
		name = ""
		super.init()
	}
	
	override public static func primaryKey() -> String? {
		return "uid"
	}
}

public class RealmAlbum: Object, AlbumType {
	public internal(set) dynamic var uid: String
	public internal(set) dynamic var name: String
	public internal(set) dynamic var artwork: NSData?
	internal dynamic var artistInternal: RealmArtist?
	internal let tracksInternal = List<RealmTrack>()
	
	public var artist: ArtistType {
		return artistInternal!
	}
	
	public var tracks: MediaCollection<TrackType, RealmTrack> {
		return MediaCollection<TrackType, RealmTrack>(realmCollection: AnyRealmCollection(tracksInternal))
	}
	
	required public init(uid: String, name: String) {
		self.uid = uid
		self.name = name
		//self.artistInternal = artist
		super.init()
	}
	
	public required init(realm: RLMRealm, schema: RLMObjectSchema) {
		uid = NSUUID().UUIDString
		name = ""
		super.init(realm: realm, schema: schema)
	}
	
	public required init(value: AnyObject, schema: RLMSchema) {
		uid = NSUUID().UUIDString
		name = ""
		super.init(value: value, schema: schema)
	}
	
	public required init() {
		uid = NSUUID().UUIDString
		name = ""
		super.init()
	}
	
	override public static func primaryKey() -> String? {
		return "uid"
	}
}

public class RealmTrack: Object, TrackType {
	public internal(set) dynamic var uid: String
	public internal(set) dynamic var title: String
	public internal(set) dynamic var duration: Float
	public internal(set) dynamic var albumInternal: RealmAlbum?

	public var artist: ArtistType {
		return albumInternal!.artist
	}
	
	public var album: AlbumType {
		return albumInternal!
	}
	
	public init(uid: String, title: String, duration: Float) {
		self.uid = uid
		self.title = title
		self.duration = duration
		super.init()
	}
	
	public required init(realm: RLMRealm, schema: RLMObjectSchema) {
		uid = NSUUID().UUIDString
		self.title = ""
		self.duration = 0
		super.init(realm: realm, schema: schema)
	}
	
	public required init(value: AnyObject, schema: RLMSchema) {
		uid = NSUUID().UUIDString
		self.title = ""
		self.duration = 0
		super.init(value: value, schema: schema)
	}
	
	public required init() {
		uid = NSUUID().UUIDString
		self.title = ""
		self.duration = 0
		super.init()
	}
	
	override public static func primaryKey() -> String? {
		return "uid"
	}
}

public class RealmPlayList : Object, PlayListType {
	public internal(set) dynamic var uid: String
	public dynamic var name: String
	internal let itemsInternal = List<RealmTrack>()
	
	public var items: MediaCollection<TrackType, RealmTrack> {
		return MediaCollection<TrackType, RealmTrack>(realmCollection: AnyRealmCollection(itemsInternal))
	}
	
	public init(uid: String, name: String) {
		self.uid = uid
		self.name = name
		super.init()
	}
	
	public required init(realm: RLMRealm, schema: RLMObjectSchema) {
		uid = NSUUID().UUIDString
		name = ""
		super.init(realm: realm, schema: schema)
	}
	
	public required init(value: AnyObject, schema: RLMSchema) {
		uid = NSUUID().UUIDString
		name = ""
		super.init(value: value, schema: schema)
	}
	
	public required init() {
		uid = NSUUID().UUIDString
		name = ""
		super.init()
	}
	
	override public static func primaryKey() -> String? {
		return "uid"
	}
}

public class MediaCollection<ExposedType, InternalType: Object> : SequenceType {
	public typealias Generator = MediaCollectionGenerator<ExposedType, InternalType>
	internal let realmCollection: AnyRealmCollection<InternalType>
	public init(realmCollection: AnyRealmCollection<InternalType>) {
		self.realmCollection = realmCollection
	}
	public var first: ExposedType? { return realmCollection.first as? ExposedType }
	public var last: ExposedType? { return realmCollection.last as? ExposedType }
	public var count: Int { return realmCollection.count }
	public subscript (index: Int) -> ExposedType? {
		return index < 0 || index >= realmCollection.count ? nil : realmCollection[index] as? ExposedType
	}
	
	public func generate() -> MediaCollection.Generator {
		return MediaCollectionGenerator(collection: self)
	}
}

public class MediaCollectionGenerator<T, K: Object> : GeneratorType {
	public typealias Element = T
	internal let collection: MediaCollection<T, K>
	internal var currentIndex = 0
	public init(collection: MediaCollection<T, K>) {
		self.collection = collection
	}
	public func next() -> MediaCollectionGenerator.Element? {
		currentIndex += 1
		if currentIndex > collection.count { return nil }
		return collection[currentIndex - 1]
	}
}