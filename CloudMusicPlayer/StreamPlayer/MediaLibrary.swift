//
//  MediaLibrary.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 22.04.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation

public protocol MediaLibraryType {
	// metadata
	func getMetadata(resource: StreamResourceIdentifier) -> MediaItemMetadataType?
	func saveMetadata(metadata: MediaItemMetadataType)
	func isMetadataExists(resource: StreamResourceIdentifier) -> Bool
	
	// play lists
	func addItemsToPlayList(playList: PlayListType, items: [MediaItemMetadataType]) -> PlayListType
	func removeItemFromPlayList(playList: PlayListType, item: MediaItemMetadataType) -> PlayListType
	func removeItemsFromPlayList(playList: PlayListType, items: [MediaItemMetadataType]) -> PlayListType
	func isItemContainsInPlayList(playList: PlayListType, item: MediaItemMetadataType) -> Bool
	func clearPlayList(playList: PlayListType) -> PlayListType
	func deletePlayList(playList: PlayListType)
	func createPlayList(name: String) -> PlayListType?
	func renamePlayList(playList: PlayListType, newName: String) -> PlayListType
	func getAllPlayLists() -> [PlayListType]
	func getPlayListByUid(uid: String) -> PlayListType?
	func getPlayListsByName(name: String) -> [PlayListType]
	
	func clearLibrary()
	
	func getUnsafeObject() -> UnsafeMediaLibraryType
}

public protocol UnsafeMediaLibraryType {
	// metadata
	func getMetadata(resource: StreamResourceIdentifier) throws -> MediaItemMetadataType?
	func saveMetadata(metadata: MediaItemMetadataType) throws
	func isMetadataExists(resource: StreamResourceIdentifier) throws -> Bool
	
	// play lists
	func addItemsToPlayList(playList: PlayListType, items: [MediaItemMetadataType]) throws -> PlayListType
	func removeItemFromPlayList(playList: PlayListType, item: MediaItemMetadataType) throws -> PlayListType
	func removeItemsFromPlayList(playList: PlayListType, items: [MediaItemMetadataType]) throws -> PlayListType
	func isItemContainsInPlayList(playList: PlayListType, item: MediaItemMetadataType) throws -> Bool
	func clearPlayList(playList: PlayListType) throws -> PlayListType
	func deletePlayList(playList: PlayListType) throws
	func createPlayList(name: String) throws -> PlayListType?
	func renamePlayList(playList: PlayListType, newName: String) throws -> PlayListType
	func getAllPlayLists() throws -> [PlayListType]
	func getPlayListByUid(uid: String) throws -> PlayListType?
	func getPlayListsByName(name: String) throws -> [PlayListType]
	
	func clearLibrary() throws
}
public protocol MediaItemMetadataType {
	var resourceUid: String { get }
	var artist: String? { get }
	var title: String? { get }
	var album: String? { get }
	var artwork: NSData? { get }
	var duration: Float? { get }
}

public protocol PlayListType {
	var uid: String { get }
	var name: String { get set }
	var items: [MediaItemMetadataType] { get }
}

public struct MediaItemMetadata : MediaItemMetadataType {
	public internal(set) var resourceUid: String
	public internal(set) var artist: String?
	public internal(set) var title: String?
	public internal(set) var album: String?
	public internal(set) var artwork: NSData?
	public internal(set) var duration: Float?
	public init(resourceUid: String, artist: String?, title: String?, album: String?, artwork: NSData?, duration: Float?) {
		self.resourceUid = resourceUid
		self.artist = artist
		self.title = title
		self.album = album
		self.artwork = artwork
		self.duration = duration
	}
}

public struct PlayList : PlayListType {
	public var uid: String
	public var name: String
	public var items: [MediaItemMetadataType]
	public init(uid: String, name: String, items: [MediaItemMetadataType]) {
		self.uid = uid
		self.name = name
		self.items = items
	}
}