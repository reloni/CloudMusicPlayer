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
}

public protocol MediaItemMetadataType {
	var artist: String? { get }
	var title: String? { get }
	var album: String? { get }
	var artwork: NSData? { get }
	var duration: Float64? { get }
}

public struct MediaItemMetadata : MediaItemMetadataType {
	public internal(set) var artist: String?
	public internal(set) var title: String?
	public internal(set) var album: String?
	public internal(set) var artwork: NSData?
	public internal(set) var duration: Float64?
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
}