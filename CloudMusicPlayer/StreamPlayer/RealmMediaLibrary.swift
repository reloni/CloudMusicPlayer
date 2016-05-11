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
}

public class UnsafeRealmMediaLibrary {
	internal func getRealm() throws -> Realm {
		return try Realm()
	}
	
	internal func createOrUpdateMetadataObject(realm: Realm, uid: String, metadata: MediaItemMetadataType) throws -> RealmMediaItemMetadata {
		if let meta = realm.objects(RealmMediaItemMetadata).filter("resourceUid = %@", uid).first {
			try realm.write {
				meta.album = metadata.album
				meta.artist = metadata.artist
				meta.artwork = metadata.artwork
				meta.internalDuration = RealmOptional<Float>(metadata.duration)
				meta.title = metadata.title
			}
			return meta
		} else {
			let meta = RealmMediaItemMetadata(uid: uid)
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
		try realm.write { realm.objects(RealmMediaItemMetadata).forEach { realm.delete($0) } }
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
	
	public func saveMetadata(resource: StreamResourceIdentifier, metadata: MediaItemMetadataType) throws {
		let realm = try getRealm()
		
		try createOrUpdateMetadataObject(realm, uid: resource.streamResourceUid, metadata: metadata)
	}
	
	public func createPlayList(name: String) throws -> PlayListType? {
		let realm = try getRealm()
		let playList = RealmPlayList(uid: NSUUID().UUIDString, name: name)
		try realm.write { realm.add(playList) }
		return playList.toStruct()
	}
	
	public func clearPlayList(playList: PlayListType) throws {
		let realm = try getRealm()
		
		guard let realmPlayList = realm.objects(RealmPlayList).filter("uid = %@", playList.uid).first else { return }
		try realm.write { realmPlayList.items.removeAll() }
	}
	
	public func deletePlayList(playList: PlayListType) throws {
		let realm = try getRealm()
		
		guard let realmPlayList = realm.objects(RealmPlayList).filter("uid = %@", playList.uid).first else { return }
		try realm.write { realm.delete(realmPlayList) }
	}
	
	public func renamePlayList(playList: PlayListType, newName: String) throws {
		let realm = try getRealm()
		
		guard let realmPlayList = realm.objects(RealmPlayList).filter("uid = %@", playList.uid).first else { return }
		try realm.write { realmPlayList.name = newName }
	}
	
	public func getAllPlayLists() throws -> [PlayListType] {
		let realm = try getRealm()
		return realm.objects(RealmPlayList).map { $0.toStruct() }
	}
	
	public func addItemsToPlayList(playList: PlayListType, items: [MediaItemMetadataType]) throws {
		let realm = try getRealm()
		
		guard let realmPlayList = realm.objects(RealmPlayList).filter("resourceUid = %@", playList.uid).first else { return }
		
		try items.forEach { metadataItem in
			let realmMetadataItem = try createOrUpdateMetadataObject(realm, uid: metadataItem.resourceUid, metadata: metadataItem)
			try realm.write { realmPlayList.items.append(realmMetadataItem) }
		}
	}
	
	public func removeItemFromPlayList(playList: PlayListType, item: MediaItemMetadataType) throws {
		try removeItemsFromPlayList(playList, items: [item])
	}
	
	public func removeItemsFromPlayList(playList: PlayListType, items: [MediaItemMetadataType]) throws {
		let realm = try getRealm()
		
		guard let realmPlayList = realm.objects(RealmPlayList).filter("resourceUid = %@", playList.uid).first else { return }
		
		try realm.write {
			items.forEach { metadataItem in
				if let realmMetadataItemIndex = realmPlayList.items.indexOf("resourceUid = %@", metadataItem.resourceUid) {
					realmPlayList.items.removeAtIndex(realmMetadataItemIndex)
				}
			}
		}
	}
	
	public func isItemContainsInPlayList(playList: PlayListType, item: MediaItemMetadataType) throws -> Bool {
		let realm = try getRealm()
		
		guard let realmPlayList = realm.objects(RealmPlayList).filter("resourceUid = %@", playList.uid).first else { return false }
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
	
	public func saveMetadata(resource: StreamResourceIdentifier, metadata: MediaItemMetadataType) {
		let _ = try? unsafeLibrary.saveMetadata(resource, metadata: metadata)
	}
	
	public func createPlayList(name: String) -> PlayListType? {
		do {
			return try unsafeLibrary.createPlayList(name)
		} catch {
			return nil
		}
	}
	
	public func clearPlayList(playList: PlayListType) {
		let _ = try? unsafeLibrary.clearPlayList(playList)
	}
	
	public func deletePlayList(playList: PlayListType) {
		let _ = try? unsafeLibrary.deletePlayList(playList)
	}
	
	public func renamePlayList(playList: PlayListType, newName: String) {
		let _ = try? unsafeLibrary.renamePlayList(playList, newName: newName)
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
	
	public func removeItemFromPlayList(playList: PlayListType, item: MediaItemMetadataType) {
		removeItemsFromPlayList(playList, items: [item])
	}
	
	public func removeItemsFromPlayList(playList: PlayListType, items: [MediaItemMetadataType]) {
		let _ = try? unsafeLibrary.removeItemsFromPlayList(playList, items: items)
	}
	
	public func isItemContainsInPlayList(playList: PlayListType, item: MediaItemMetadataType) -> Bool {
		return false
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