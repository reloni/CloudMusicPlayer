//
//  MainModel.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 24.05.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import RealmSwift

class MainModel {
	static var sharedInstance: MainModel!
	
	let player: RxPlayer
	
	init(player: RxPlayer) {
		self.player = player
	}
	
	var artists: MediaCollection<ArtistType, RealmArtist>? {
		return (try? player.mediaLibrary.getArtists()) ?? nil
	}
	
	var albums: MediaCollection<AlbumType, RealmAlbum>? {
		return (try? player.mediaLibrary.getAlbums()) ?? nil
	}

	var tracks: MediaCollection<TrackType, RealmTrack>? {
		return (try? player.mediaLibrary.getTracks()) ?? nil
	}
	
	var playLists: MediaCollection<PlayListType, RealmPlayList>? {
		return (try? player.mediaLibrary.getPlayLists()) ?? nil
	}
}