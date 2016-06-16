//
//  MainModel+Playback.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 16.06.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation

extension MainModel {
	func togglePlayer() {
		if player.playing {
			player.pause()
		} else {
			player.resume()
		}
	}
	
	/// Toggle player state with specified track
	/// If current track in player equals to specified track, toggles player (play or pause track)
	/// If current track in palyer not equal to specified track, tries to found that track in queue and if success starts play this track
	func toggleTrack(track: TrackType) {
		if player.current?.streamIdentifier.streamResourceUid == track.uid {
			togglePlayer()
		} else if let queueItem = player.getQueueItemByUid(track.uid) {
			player.play(queueItem)
		} else {
			// if didn't found starting track, forse resume
			player.resume(true)
		}
	}
	
	func togglePlayer(container: TrackContainerType, track: TrackType? = nil) {
		guard player.count > 0 else {	play(container, track: track); return }
		
		if let track = track where container.uid == currentPlayingContainerUid {
			// if track specified and playing current container
			toggleTrack(track)
		} else if container.uid == currentPlayingContainerUid {
			// if playing current container and track not specified
			togglePlayer()
		} else {
			// if should play new container
			play(container, track: track)
		}
	}
	
	func play(container: TrackContainerType, track: TrackType? = nil) {
		currentPlayingContainerUid = container.uid
		
		switch container {
		case let pl as PlayListType: play(pl, track: track)
		default: break
		}
	}
	
	func play(playList: PlayListType, track: TrackType? = nil) {
		player.play(playList, startWithTrack: track)
	}
}