//
//  MediaLibrary.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 22.04.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation

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

public protocol PlaylistType {
	var uid: String { get }
	var items: [MediaItemMetadataType] { get }
	func addItems(items: [MediaItemMetadataType])
	func removeItem(item: MediaItemMetadataType)
	func containsInPlaylist(item: MediaItemMetadataType) -> Bool
	func clear()
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