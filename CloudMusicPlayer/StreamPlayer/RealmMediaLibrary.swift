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

public class RealmMediaItemMetadata : Object {
	public internal(set) dynamic var resourceUid: String
	public internal(set) dynamic var artist: String?
	public internal(set) dynamic var title: String?
	public internal(set) dynamic var album: String?
	public internal(set) dynamic var artwork: NSData?
	public var duration: Float? {
		return internalDuration.value
	}
	public internal(set) var internalDuration = RealmOptional<Float>()
	
	required public init(uid: String) {
		self.resourceUid = uid
		super.init()
	}
	
	public required init(realm: RLMRealm, schema: RLMObjectSchema) {
		resourceUid = NSUUID().UUIDString
		super.init(realm: realm, schema: schema)
	}
	
	public required init(value: AnyObject, schema: RLMSchema) {
		resourceUid = NSUUID().UUIDString
		super.init(value: value, schema: schema)
	}
	
	public required init() {
		resourceUid = NSUUID().UUIDString
		super.init()
	}
	
	override public static func primaryKey() -> String? {
		return "resourceUid"
	}
}

public class RealmMediaLibrary {
	internal let unsafeLibrary = UnsafeRealmMediaLibrary()
	public init() { }
}

public class UnsafeRealmMediaLibrary {
	internal func getRealm() throws -> Realm {
		return try Realm()
	}
	
	internal func createOrUpdateMetadataObject(realm: Realm, metadata: MediaItemMetadataType) throws -> RealmMediaItemMetadata {
		if let meta = realm.objects(RealmMediaItemMetadata).filter("resourceUid = %@", metadata.resourceUid).first {
			try realm.write {
				meta.album = metadata.album
				meta.artist = metadata.artist
				meta.artwork = metadata.artwork
				meta.internalDuration = RealmOptional<Float>(metadata.duration)
				meta.title = metadata.title
			}
			return meta
		} else {
			let meta = RealmMediaItemMetadata(uid: metadata.resourceUid)
			meta.album = metadata.album
			meta.artist = metadata.artist
			meta.artwork = metadata.artwork
			meta.internalDuration = RealmOptional<Float>(metadata.duration)
			meta.title = metadata.title
			try realm.write {
				realm.add(meta)
			}
			return meta
		}
	}
}

extension UnsafeRealmMediaLibrary : UnsafeMediaLibraryType {
	public func clearLibrary() throws {
		let realm = try getRealm()
		try realm.write {
			realm.delete(realm.objects(RealmMediaItemMetadata))
			realm.delete(realm.objects(RealmPlayList))
		}
	}
	
	public func getMetadata(resource: StreamResourceIdentifier) throws -> MediaItemMetadataType? {
		let realm = try getRealm()
		guard let meta = realm.objects(RealmMediaItemMetadata).filter("resourceUid = %@", resource.streamResourceUid).first else { return nil }
		
		return meta.toStruct()
	}
	
	public func isMetadataExists(resource: StreamResourceIdentifier) throws -> Bool {
		let realm = try getRealm()
		
		return realm.objects(RealmMediaItemMetadata).filter("resourceUid = %@", resource.streamResourceUid).first != nil
	}
	
	public func saveMetadata(metadata: MediaItemMetadataType) throws {
		let realm = try getRealm()
		
		try createOrUpdateMetadataObject(realm, metadata: metadata)
	}
	
	public func createPlayList(name: String) throws -> PlayListType? {
		let realm = try getRealm()
		let playList = RealmPlayList(uid: NSUUID().UUIDString, name: name)
		try realm.write { realm.add(playList) }
		return playList.toStruct()
	}
	
	public func clearPlayList(playList: PlayListType) throws -> PlayListType {
		let realm = try getRealm()
		
		guard let realmPlayList = realm.objects(RealmPlayList).filter("uid = %@", playList.uid).first else { return playList }
		try realm.write { realmPlayList.items.removeAll() }
		return PlayList(uid: playList.uid, name: playList.name, items: [MediaItemMetadataType]())
	}
	
	public func deletePlayList(playList: PlayListType) throws {
		let realm = try getRealm()
		
		guard let realmPlayList = realm.objects(RealmPlayList).filter("uid = %@", playList.uid).first else { return }
		try realm.write { realm.delete(realmPlayList) }
	}
	
	public func renamePlayList(playList: PlayListType, newName: String) throws -> PlayListType {
		let realm = try getRealm()
		
		guard let realmPlayList = realm.objects(RealmPlayList).filter("uid = %@", playList.uid).first else { return playList }
		try realm.write { realmPlayList.name = newName }
		return PlayList(uid: playList.uid, name: newName, items: playList.items)
	}
	
	public func getAllPlayLists() throws -> [PlayListType] {
		let realm = try getRealm()
		return realm.objects(RealmPlayList).map { $0.toStruct() }
	}
	
	public func addItemsToPlayList(playList: PlayListType, items: [MediaItemMetadataType]) throws {
		let realm = try getRealm()
		
		guard let realmPlayList = realm.objects(RealmPlayList).filter("uid = %@", playList.uid).first else { return }
		
		try items.forEach { metadataItem in
			let realmMetadataItem = try createOrUpdateMetadataObject(realm, metadata: metadataItem)
			try realm.write { realmPlayList.items.append(realmMetadataItem) }
		}
	}
	
	public func removeItemFromPlayList(playList: PlayListType, item: MediaItemMetadataType) throws -> PlayListType {
		return try removeItemsFromPlayList(playList, items: [item])
	}
	
	public func removeItemsFromPlayList(playList: PlayListType, items: [MediaItemMetadataType]) throws -> PlayListType {
		let realm = try getRealm()
		
		guard let realmPlayList = realm.objects(RealmPlayList).filter("uid = %@", playList.uid).first else { return playList }
		
		try realm.write {
			items.forEach { metadataItem in
				if let realmMetadataItemIndex = realmPlayList.items.indexOf("resourceUid = %@", metadataItem.resourceUid) {
					realmPlayList.items.removeAtIndex(realmMetadataItemIndex)
				}
			}
		}
		
		return realmPlayList.toStruct()
	}
	
	public func isItemContainsInPlayList(playList: PlayListType, item: MediaItemMetadataType) throws -> Bool {
		let realm = try getRealm()
		
		guard let realmPlayList = realm.objects(RealmPlayList).filter("uid = %@", playList.uid).first else { return false }
		return realmPlayList.items.filter("resourceUid = %@", item.resourceUid).count > 0
	}
	
	public func getPlayListByUid(uid: String) throws -> PlayListType? {
		let realm = try getRealm()
		return realm.objects(RealmPlayList).filter("uid = %@", uid).first?.toStruct()
	}
	
	public func getPlayListsByName(name: String) throws -> [PlayListType] {
		let realm = try getRealm()
		return realm.objects(RealmPlayList).filter("name = %@", name).map { $0.toStruct() }
	}
}

extension RealmMediaLibrary : MediaLibraryType {
	public func getUnsafeObject() -> UnsafeMediaLibraryType {
		return unsafeLibrary
	}
	
	public func clearLibrary() {
		let _ = try? unsafeLibrary.clearLibrary()
	}
	
	public func getMetadata(resource: StreamResourceIdentifier) -> MediaItemMetadataType? {
		do {
			return try unsafeLibrary.getMetadata(resource)
		} catch {
			return nil
		}
	}
	
	public func isMetadataExists(resource: StreamResourceIdentifier) -> Bool {
		do {
			return try unsafeLibrary.isMetadataExists(resource)
		} catch {
			return false
		}
	}
	
	public func saveMetadata(metadata: MediaItemMetadataType) {
		let _ = try? unsafeLibrary.saveMetadata(metadata)
	}
	
	public func createPlayList(name: String) -> PlayListType? {
		do {
			return try unsafeLibrary.createPlayList(name)
		} catch {
			return nil
		}
	}
	
	public func clearPlayList(playList: PlayListType) -> PlayListType {
		do {
			return try unsafeLibrary.clearPlayList(playList)
		} catch {
			return playList
		}
	}
	
	public func deletePlayList(playList: PlayListType) {
		let _ = try? unsafeLibrary.deletePlayList(playList)
	}
	
	public func renamePlayList(playList: PlayListType, newName: String) -> PlayListType {
		do {
			return try unsafeLibrary.renamePlayList(playList, newName: newName)
		} catch {
			return playList
		}
	}
	
	public func getAllPlayLists() -> [PlayListType] {
		do {
			return try unsafeLibrary.getAllPlayLists()
		} catch {
			return [PlayListType]()
		}
	}
	
	public func addItemsToPlayList(playList: PlayListType, items: [MediaItemMetadataType]) {
		let _ = try? unsafeLibrary.addItemsToPlayList(playList, items: items)
	}
	
	public func removeItemFromPlayList(playList: PlayListType, item: MediaItemMetadataType) -> PlayListType {
		return removeItemsFromPlayList(playList, items: [item])
	}
	
	public func removeItemsFromPlayList(playList: PlayListType, items: [MediaItemMetadataType]) -> PlayListType {
		do {
			return try unsafeLibrary.removeItemsFromPlayList(playList, items: items)
		} catch {
			return playList
		}
	}
	
	public func isItemContainsInPlayList(playList: PlayListType, item: MediaItemMetadataType) -> Bool {
		do {
			return try unsafeLibrary.isItemContainsInPlayList(playList, item: item)
		} catch {
			return false
		}
	}
	
	public func getPlayListByUid(uid: String) -> PlayListType? {
		do {
			return try unsafeLibrary.getPlayListByUid(uid)
		} catch {
			return nil
		}
	}
	
	public func getPlayListsByName(name: String) -> [PlayListType] {
		do {
			return try unsafeLibrary.getPlayListsByName(name)
		} catch {
			return [PlayListType]()
		}
	}
}

public class RealmPlayList : Object {
	public internal(set) dynamic var uid: String
	public internal(set) dynamic var name: String
	public let items = List<RealmMediaItemMetadata>()
	
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

extension RealmPlayList {
	public func toStruct() -> PlayList {
		return PlayList(uid: uid, name: name, items: items.map { $0.toStruct() })
	}
}

extension RealmMediaItemMetadata {
	public func toStruct() -> MediaItemMetadata {
		return MediaItemMetadata(resourceUid: resourceUid, artist: artist, title: title, album: album, artwork: artwork, duration: duration)
	}
}