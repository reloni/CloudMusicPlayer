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

//public class RealmMediaLibrary {
//	internal let unsafeLibrary = try! UnsafeRealmMediaLibrary()
//	public init() { }
//}

public class RealmMediaLibrary {
	internal let realm: Realm
	
	public init(realm: Realm) {
		self.realm = realm
	}
	
	public convenience init() throws {
		try self.init(realm: Realm())
	}
	
	internal func getRealm() -> Realm {
		return realm
	}
	
	internal lazy var unknownArtist: RealmArtist = { [unowned self] in
		guard let artist = self.getRealm().objects(RealmArtist).filter("uid = %@", "unknown_artist").first else {
			return RealmArtist(uid: "unknown_artist", name: "Unknown artist")
		}
		return artist
	}()
	
	internal lazy var unknownAlbum: RealmAlbum = { [unowned self] in
		guard let album = self.getRealm().objects(RealmAlbum).filter("uid = %@", "unknown_album").first else {
			return RealmAlbum(uid: "unknown_album", name: "Unknown album", artist: self.unknownArtist)
		}
		return album
	}()
	
	internal func getOrCreateArtist(name: String) throws -> RealmArtist {
		let realm = getRealm()
		if let artist = realm.objects(RealmArtist).filter("name = %@", name).first {
			return artist
		} else {
			let artist = RealmArtist(uid: NSUUID().UUIDString, name: name)
			try realm.write { realm.add(artist) }
			return artist
		}
	}
	
	internal func getOrCreateAlbum(name: String, artwork: NSData?, artistName: String, updateIfExisted: Bool) throws -> RealmAlbum {
		let realm = getRealm()
		if let album = realm.objects(RealmAlbum).filter("name = %@", name).first {
			if updateIfExisted {
				try realm.write { album.artwork = artwork }
			}
			return album
		} else {
			let album = try RealmAlbum(uid: NSUUID().UUIDString, name: name, artist: getOrCreateArtist(artistName))
			try realm.write { realm.add(album) }
			return album
		}
	}
	
	internal func getOrCreateTrack(metadata: MediaItemMetadataType, updateIfExisted: Bool) throws -> RealmTrack {
		let album = try getOrCreateAlbum(metadata.album ?? "Unknown album",
		                                 artwork: metadata.artwork,
		                                 artistName: metadata.artist ?? "Unknown artist",
		                                 updateIfExisted: updateIfExisted)
		let realm = getRealm()
		if let track = realm.objects(RealmTrack).filter("uid = %@", metadata.resourceUid).first {
			if updateIfExisted {
				try realm.write {
					if let title = metadata.title { track.title = title }
					if let duration = metadata.duration { track.duration = duration }
					track.albumInternal = album
				}
			}
			return track
		} else {
			let track = RealmTrack(uid: metadata.resourceUid, title: metadata.title ?? "Unknown track", duration: metadata.duration ?? 0, album: album)
			try realm.write { realm.add(track) }
			return track
		}
	}
	
//	internal func createOrUpdateMetadataObject(realm: Realm, metadata: MediaItemMetadataType) throws -> RealmMediaItemMetadata {
//		if let meta = realm.objects(RealmMediaItemMetadata).filter("resourceUid = %@", metadata.resourceUid).first {
//			try realm.write {
//				meta.album = metadata.album
//				meta.artist = metadata.artist
//				meta.artwork = metadata.artwork
//				meta.internalDuration = RealmOptional<Float>(metadata.duration)
//				meta.title = metadata.title
//			}
//			return meta
//		} else {
//			let meta = RealmMediaItemMetadata(uid: metadata.resourceUid)
//			meta.album = metadata.album
//			meta.artist = metadata.artist
//			meta.artwork = metadata.artwork
//			meta.internalDuration = RealmOptional<Float>(metadata.duration)
//			meta.title = metadata.title
//			try realm.write {
//				realm.add(meta)
//			}
//			return meta
//		}
//	}
}

extension RealmMediaLibrary : MediaLibraryType {
	public var artists: MediaResults<ArtistType, RealmArtist> {
		return MediaResults(realmResults: getRealm().objects(RealmArtist))
	}
	
	public var albums: MediaResults<AlbumType, RealmAlbum> {
		return MediaResults(realmResults: getRealm().objects(RealmAlbum))
	}
	
	public var tracks: MediaResults<TrackType, RealmTrack> {
		return MediaResults(realmResults: getRealm().objects(RealmTrack))
	}
	
	public var playLists: MediaResults<PlayListType, RealmPlayList> {
		return MediaResults(realmResults: getRealm().objects(RealmPlayList))
	}
	
	public func clearLibrary() throws {
		let realm = getRealm()
		try realm.write {
			//realm.delete(realm.objects(RealmMediaItemMetadata))
			realm.delete(realm.objects(RealmTrack))
			realm.delete(realm.objects(RealmAlbum))
			realm.delete(realm.objects(RealmArtist))
			realm.delete(realm.objects(RealmPlayList))
		}
	}
	
	public func isTrackExists(resource: StreamResourceIdentifier) -> Bool {
		return getRealm().objects(RealmTrack).filter("uid = %@", resource.streamResourceUid).count > 0
	}
	
	public func getTrackByUid(resource: StreamResourceIdentifier) -> TrackType? {
		return getRealm().objects(RealmTrack).filter("uid = %@", resource.streamResourceUid).first
	}
	
	public func getMetadataObjectByUid(resource: StreamResourceIdentifier) -> MediaItemMetadata? {
		guard let track = getTrackByUid(resource) else { return nil }
		return MediaItemMetadata(resourceUid: track.uid,
		                         artist: track.artist.name,
		                         title: track.title,
		                         album: track.album.name,
		                         artwork: track.album.artwork,
		                         duration: track.duration)
	}
	
	public func saveMetadata(metadata: MediaItemMetadataType, updateRelatedObjects: Bool) throws {
		try getOrCreateTrack(metadata, updateIfExisted: updateRelatedObjects)
	}
	
	public func saveMetadataSafe(metadata: MediaItemMetadataType, updateRelatedObjects: Bool) {
		let _ = try? saveMetadata(metadata, updateRelatedObjects: updateRelatedObjects)
	}
	
	public func createPlayList(name: String) throws -> PlayListType? {
		let realm = getRealm()
		let playList = RealmPlayList(uid: NSUUID().UUIDString, name: name)
		try realm.write { realm.add(playList) }
		return playList
	}
	
	public func clearPlayList(playList: PlayListType) throws -> PlayListType {
		let realm = getRealm()
		
		guard let realmPlayList = realm.objects(RealmPlayList).filter("uid = %@", playList.uid).first else { return playList }
		try realm.write { realmPlayList.itemsInternal.removeAll() }
		//return PlayList(uid: playList.uid, name: playList.name, items: [MediaItemMetadataType]())
		return realmPlayList
	}
	
	public func deletePlayList(playList: PlayListType) throws {
		let realm = getRealm()
		
		guard let realmPlayList = realm.objects(RealmPlayList).filter("uid = %@", playList.uid).first else { return }
		try realm.write { realm.delete(realmPlayList) }
	}
	
	public func addTracksToPlayList(playList: PlayListType, tracks: [TrackType]) throws -> PlayListType {
		let realm = getRealm()
		
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
		let realm = getRealm()
		
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
	
	public func isTrackContainsInPlayList(playList: PlayListType, track: TrackType) -> Bool {
		guard let realmPlayList = getRealm().objects(RealmPlayList).filter("uid = %@", playList.uid).first else { return false }
		return realmPlayList.itemsInternal.filter("uid = %@", track.uid).count > 0
	}
	
	public func getPlayListByUid(uid: String) -> PlayListType? {
		return getRealm().objects(RealmPlayList).filter("uid = %@", uid).first
	}
	
	public func getPlayListsByName(name: String) -> [PlayListType] {
		return getRealm().objects(RealmPlayList).filter("name = %@", name).map { $0 }
	}
}

public class RealmArtist: Object, ArtistType {
	public internal(set) dynamic var uid: String
	public internal(set) dynamic var name: String
	internal let albumsInternal = List<RealmAlbum>()
	
	public var albums: MediaList<AlbumType, RealmAlbum> {
		return MediaList(realmList: albumsInternal)
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
	internal dynamic var artistInternal: RealmArtist
	internal let tracksInternal = List<RealmTrack>()
	
	public var artist: ArtistType {
		return artistInternal
	}
	
	public var tracks: MediaList<TrackType, RealmTrack> {
		return MediaList(realmList: tracksInternal)
	}
	
	required public init(uid: String, name: String, artist: RealmArtist) {
		self.uid = uid
		self.name = name
		self.artistInternal = artist
		super.init()
	}
	
	public required init(realm: RLMRealm, schema: RLMObjectSchema) {
		uid = NSUUID().UUIDString
		name = ""
		artistInternal = RealmArtist(uid: "unknown_artist", name: "Unknown artist")
		super.init(realm: realm, schema: schema)
	}
	
	public required init(value: AnyObject, schema: RLMSchema) {
		uid = NSUUID().UUIDString
		name = ""
		artistInternal = RealmArtist(uid: "unknown_artist", name: "Unknown artist")
		super.init(value: value, schema: schema)
	}
	
	public required init() {
		uid = NSUUID().UUIDString
		name = ""
		artistInternal = RealmArtist(uid: "unknown_artist", name: "Unknown artist")
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
	public internal(set) dynamic var albumInternal: RealmAlbum

	public var artist: ArtistType {
		return albumInternal.artist
	}
	
	public var album: AlbumType {
		return albumInternal
	}
	
	public init(uid: String, title: String, duration: Float, album: RealmAlbum) {
		self.uid = uid
		self.title = title
		self.duration = duration
		self.albumInternal = album
		super.init()
	}
	
	public required init(realm: RLMRealm, schema: RLMObjectSchema) {
		uid = NSUUID().UUIDString
		self.title = ""
		self.duration = 0
		albumInternal = RealmAlbum(uid: "unknown_album", name: "Unknown album", artist: RealmArtist(uid: "unknown_artist", name: "Unknown artist"))
		super.init(realm: realm, schema: schema)
	}
	
	public required init(value: AnyObject, schema: RLMSchema) {
		uid = NSUUID().UUIDString
		self.title = ""
		self.duration = 0
		albumInternal = RealmAlbum(uid: "unknown_album", name: "Unknown album", artist: RealmArtist(uid: "unknown_artist", name: "Unknown artist"))
		super.init(value: value, schema: schema)
	}
	
	public required init() {
		uid = NSUUID().UUIDString
		self.title = ""
		self.duration = 0
		albumInternal = RealmAlbum(uid: "unknown_album", name: "Unknown album", artist: RealmArtist(uid: "unknown_artist", name: "Unknown artist"))
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
	
	public var items: MediaList<TrackType, RealmTrack> {
		return MediaList(realmList: itemsInternal)
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

public class MediaList<ExposedType, InternalType: Object> : SequenceType {
	public typealias Generator = MediaListGenerator<ExposedType, InternalType>
	internal let realmList: List<InternalType>
	public init(realmList: List<InternalType>) {
		self.realmList = realmList
	}
	public var first: ExposedType? { return realmList.first as? ExposedType }
	public var last: ExposedType? { return realmList.last as? ExposedType }
	public var count: Int { return realmList.count }
	public subscript (index: Int) -> ExposedType? { return realmList[index] as? ExposedType }
	
	public func generate() -> MediaList.Generator {
		return MediaListGenerator(list: self)
	}
}

public class MediaResults<ExposedType, InternalType: Object> : SequenceType {
	public typealias Generator = MediaResultsGenerator<ExposedType, InternalType>
	internal let realmResults: Results<InternalType>
	public init(realmResults: Results<InternalType>) {
		self.realmResults = realmResults
	}
	public var first: ExposedType? { return realmResults.first as? ExposedType }
	public var last: ExposedType? { return realmResults.last as? ExposedType }
	public var count: Int { return realmResults.count }
	public subscript (index: Int) -> ExposedType? { return realmResults[index] as? ExposedType }
	
	public func generate() -> MediaResults.Generator {
		return MediaResultsGenerator(results: self)
	}
}

public class MediaListGenerator<T, K: Object> : GeneratorType {
	public typealias Element = T
	internal let list: MediaList<T, K>
	internal var currentIndex = 0
	public init(list: MediaList<T, K>) {
		self.list = list
	}
	public func next() -> MediaListGenerator.Element? {
		currentIndex += 1
		return list[currentIndex - 1]
	}
}

public class MediaResultsGenerator<T, K: Object> : GeneratorType {
	public typealias Element = T
	internal let results: MediaResults<T, K>
	internal var currentIndex = 0
	public init(results: MediaResults<T, K>) {
		self.results = results
	}
	public func next() -> MediaResultsGenerator.Element? {
		currentIndex += 1
		return results[currentIndex - 1]
	}
}