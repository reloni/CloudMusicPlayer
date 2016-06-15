//
//  PlayListInfoModel.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 21.05.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import RxSwift

class PlayListInfoModel {
	let playList: PlayListType
	let mainModel: MainModel
	
	init(mainModel: MainModel, playList: PlayListType) {
		self.mainModel = mainModel
		self.playList = playList
	}
	
	var playListActive: Bool {
		return mainModel.currentPlayingContainerUid == playList.synchronize().uid
	}
	
	func checkPlayListPlaying() -> Bool {
		return playListActive && mainModel.player.playing
	}
	
	var playing: Observable<Bool> {
		return Observable.create { [weak self] observer in
			guard let object = self else { observer.onCompleted(); return NopDisposable.instance }
			observer.onNext(object.checkPlayListPlaying())
			
			let disposable = object.mainModel.player.playerEvents.bindNext { event in
				switch event {
				case .Paused: fallthrough
				case .Stopped: fallthrough
				case .Resumed: fallthrough
				case .Started: observer.onNext(object.checkPlayListPlaying())
				default: break
				}
			}
			
			return AnonymousDisposable {
				disposable.dispose()
			}
		}
	}
	
	func togglePlayer(play: Bool, track: TrackType? = nil) {
		// if should pause player and track not specified, simply pause and exit
		if !play { mainModel.player.pause(); return }
		
		let player = mainModel.player
		
		// check new track specified
		guard let newTrack = track?.synchronize() else {
			// if should pause, simply do that
			if playListActive {
				// if track not specified and player play current play list, simply resume
				player.resume(true)
			} else {
				// else spart playing current play list
				mainModel.playPlayList(playList)
			}
			return
		}
		
		// if play list not active, simply start playing this play list
		guard playListActive && player.currentItems.count == playList.items.count else {
			mainModel.playPlayList(playList, startWith: newTrack); return
		}
		
		if player.current?.streamIdentifier.streamResourceUid == newTrack.uid {
			// if player current item equals to specified track, resume
			player.resume(true)
		} else {
			// else, set specified track as current and resume
			if let queueItem = player.getQueueItemByUid(newTrack.uid) {
				player.play(queueItem)
			}
		}
	}
}