//
//  MediaLibrary.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 22.04.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import Realm
import RealmSwift

public protocol MediaLibraryType {
	func getMetadata(resource: StreamResourceIdentifier) -> MediaItemMetadataType?
	func saveMetadata(resource: StreamResourceIdentifier, metadata: MediaItemMetadataType)
	func metadataExists(resource: StreamResourceIdentifier) -> Bool
	func clearLibrary()
}

public protocol MediaItemMetadataType {
	var resourceUid: String { get }
	var artist: String? { get }
	var title: String? { get }
	var album: String? { get }
	var artwork: NSData? { get }
	var duration: Float? { get }
}

public struct MediaItemMetadata : MediaItemMetadataType {
	public internal(set) var resourceUid: String
	public internal(set) var artist: String?
	public internal(set) var title: String?
	public internal(set) var album: String?
	public internal(set) var artwork: NSData?
	public internal(set) var duration: Float?
}

public class NonRetentiveMediaLibrary {
	internal var library = [String: MediaItemMetadataType]()
}

extension NonRetentiveMediaLibrary : MediaLibraryType {
	public func getMetadata(resource: StreamResourceIdentifier) -> MediaItemMetadataType? {
		return library[resource.streamResourceUid]
	}
	
	public func saveMetadata(resource: StreamResourceIdentifier, metadata: MediaItemMetadataType) {
		library[resource.streamResourceUid] = metadata
	}
	
	public func metadataExists(resource: StreamResourceIdentifier) -> Bool {
		return library[resource.streamResourceUid] != nil
	}
	
	public func clearLibrary() {
		library.removeAll()
	}
}

public class RealmMediaLibrary {
	//internal let queue = dispatch_queue_create("com.cloudmusicplayer.realmmedialibrary.serialqueue", DISPATCH_QUEUE_SERIAL)
}

public class RealmMediaItemMetadata : Object, MediaItemMetadataType {
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

extension RealmMediaLibrary : MediaLibraryType {
	public func clearLibrary() {
		//dispatch_sync(queue) {
			let realm = try? Realm()
			if let realm = realm {
				let _ = try? realm.write { realm.deleteAll() }
			}
		//}
	}
	
	public func getMetadata(resource: StreamResourceIdentifier) -> MediaItemMetadataType? {
		var result: MediaItemMetadataType?
		//dispatch_sync(queue) {
			let realm = try? Realm()
			if let realm = realm {
				if let meta = realm.objects(RealmMediaItemMetadata).filter("resourceUid = %@", resource.streamResourceUid).first {
					result = MediaItemMetadata(resourceUid: meta.resourceUid, artist: meta.artist, title: meta.title,
					                           album: meta.album, artwork: meta.artwork, duration: meta.duration)
				}
				
			}
		//}
		return result
	}
	
	public func metadataExists(resource: StreamResourceIdentifier) -> Bool {
		var result: Bool = false
		//dispatch_sync(queue) {
			let realm = try? Realm()
			if let realm = realm {
				result = realm.objects(RealmMediaItemMetadata).filter("resourceUid = %@", resource.streamResourceUid).first != nil
			}
		//}
		return result
	}
	
	public func saveMetadata(resource: StreamResourceIdentifier, metadata: MediaItemMetadataType) {
		//dispatch_sync(queue) {
			let realm = try? Realm()
			if let realm = realm {
				if let meta = realm.objects(RealmMediaItemMetadata).filter("resourceUid = %@", resource.streamResourceUid).first {
					let _ = try? realm.write {
						meta.album = metadata.album
						meta.artist = metadata.artist
						meta.artwork = metadata.artwork
						meta.internalDuration = RealmOptional<Float>(metadata.duration)
						meta.title = metadata.title
					}
				} else {
					let meta = RealmMediaItemMetadata(uid: resource.streamResourceUid)
					meta.album = metadata.album
					meta.artist = metadata.artist
					meta.artwork = metadata.artwork
					meta.internalDuration = RealmOptional<Float>(metadata.duration)
					meta.title = metadata.title
					let _ = try? realm.write {
						realm.add(meta)
					}
				}
			}
		//}
	}
}
