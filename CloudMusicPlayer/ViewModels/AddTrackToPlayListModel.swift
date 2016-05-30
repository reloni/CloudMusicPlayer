//
//  AddTrackToPlayListModel.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 30.05.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation

class AddItemsToPlayListModel {
	let tracks: [TrackType]
	let albums: [AlbumType]
	let artists: [ArtistType]
	let mainModel: MainModel
	
	init(mainModel: MainModel, artists: [ArtistType], albums: [AlbumType], tracks: [TrackType]) {
		self.mainModel = mainModel
		self.artists = artists
		self.albums = albums
		self.tracks = tracks
	}
	
	func addItemsToPlayLists(playLists: [PlayListType]) {
		playLists.forEach { pl in
			artists.forEach { mainModel.addArtistToPlayList($0, playList: pl) }
			albums.forEach { mainModel.addAlbumToPlayList($0, playList: pl) }
			mainModel.addTracksToPlayList(tracks, playList: pl)
		}
	}
}