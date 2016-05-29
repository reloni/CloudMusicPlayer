//
//  MediaLibrary.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 22.04.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import MediaPlayer

public enum MediaLibraryErroros : CustomErrorType {
	case emptyPlayListName
	
	public func errorDomain() -> String {
		return "MediaLibraryDomain"
	}
	
	public func errorCode() -> Int {
		switch self {
		case .emptyPlayListName: return 1
		}
	}
	
	public func errorDescription() -> String {
		return "Play list name cannot be empty"
	}
}

public protocol MediaLibraryType {
	// metadata
	func getArtists() throws -> MediaCollection<ArtistType, RealmArtist>
	func getAlbums() throws -> MediaCollection<AlbumType, RealmAlbum>
	func getTracks() throws -> MediaCollection<TrackType, RealmTrack>
	func getPlayLists() throws -> MediaCollection<PlayListType, RealmPlayList>
	func getTrackByUid(resource: StreamResourceIdentifier) throws -> TrackType?
	func getMetadataObjectByUid(resource: StreamResourceIdentifier) throws -> MediaItemMetadata?
	func saveMetadata(metadata: MediaItemMetadataType, updateExistedObjects: Bool) throws -> TrackType?
	func saveMetadataSafe(metadata: MediaItemMetadataType, updateExistedObjects: Bool) -> TrackType?
	func isTrackExists(resource: StreamResourceIdentifier) throws -> Bool
	
	// play lists
	func addTracksToPlayList(playList: PlayListType, tracks: [TrackType]) throws -> PlayListType
	func removeTrackFromPlayList(playList: PlayListType, track: TrackType) throws -> PlayListType
	func removeTracksFromPlayList(playList: PlayListType, tracks: [TrackType]) throws -> PlayListType
	func isTrackContainsInPlayList(playList: PlayListType, track: TrackType) throws -> Bool
	func clearPlayList(playList: PlayListType) throws
	func deletePlayList(playList: PlayListType) throws
	func createPlayList(name: String) throws -> PlayListType
	func renamePlayList(playList: PlayListType, newName: String) throws
	//func getAllPlayLists() -> [PlayListType]
	func getPlayListByUid(uid: String) throws -> PlayListType?
	func getPlayListsByName(name: String) throws -> [PlayListType]
	
	func clearLibrary() throws
}

public protocol ArtistType {
	var name: String { get }
	var albums: MediaCollection<AlbumType, RealmAlbum> { get }
}

public protocol AlbumType {
	var artist: ArtistType { get }
	var tracks: MediaCollection<TrackType, RealmTrack> { get }
	var name: String { get }
	var artwork: NSData? { get }
}

public protocol TrackType {
	var uid: String { get }
	var title: String { get }
	var duration: Float { get }
	var album: AlbumType { get }
	var artist: ArtistType { get }
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
	var items: MediaCollection<TrackType, RealmTrack> { get }
}

public protocol AlbumCollectionType {
	var count: Int { get }
	var first: AlbumType? { get }
	var last: AlbumType? { get }
	subscript(index: Int) -> AlbumType { get }
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

extension MediaItemMetadataType {
	public func getMetadataForNowPlayingInfoCenter() -> [String: AnyObject]? {
		var data = [String: AnyObject]()
		data[MPMediaItemPropertyTitle] = title!
		data[MPMediaItemPropertyAlbumTitle] = album!
		data[MPMediaItemPropertyArtist] = artist!
		data[MPMediaItemPropertyPlaybackDuration] = duration!
		data[MPNowPlayingInfoPropertyPlaybackRate] = 1
		if let artwork = artwork, image = UIImage(data: artwork) {
			data[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(image: image)
		}
		return data
	}
}