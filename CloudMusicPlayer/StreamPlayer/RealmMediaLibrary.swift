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
		autoreleasepool {
			let realm = try? Realm()
			if let realm = realm {
				let _ = try? realm.write { realm.deleteAll() }
			}
		}
	}
	
	public func getMetadata(resource: StreamResourceIdentifier) -> MediaItemMetadataType? {
		var result: MediaItemMetadataType?
		autoreleasepool {
			let realm = try? Realm()
			if let realm = realm {
				if let meta = realm.objects(RealmMediaItemMetadata).filter("resourceUid = %@", resource.streamResourceUid).first {
					result = MediaItemMetadata(resourceUid: meta.resourceUid, artist: meta.artist, title: meta.title,
						album: meta.album, artwork: meta.artwork, duration: meta.duration)
				}
				
			}
		}
		return result
	}
	
	public func metadataExists(resource: StreamResourceIdentifier) -> Bool {
		var result: Bool = false
		autoreleasepool {
			let realm = try? Realm()
			if let realm = realm {
				result = realm.objects(RealmMediaItemMetadata).filter("resourceUid = %@", resource.streamResourceUid).first != nil
			}
		}
		return result
	}
	
	public func saveMetadata(resource: StreamResourceIdentifier, metadata: MediaItemMetadataType) {
		autoreleasepool {
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
		}
	}
}