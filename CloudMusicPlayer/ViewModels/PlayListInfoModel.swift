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
	
	var playing: Observable<Bool> {
		return Observable.create { [weak self] observer in
			guard let object = self else { observer.onCompleted(); return NopDisposable.instance }
			observer.onNext(object.checkPlaying())
			
			let disposable = object.mainModel.player.playerEvents.bindNext { event in
				switch event {
				case .Paused: fallthrough
				case .Stopped: fallthrough
				case .Resumed: fallthrough
				case .Started: observer.onNext(object.checkPlaying())
				default: break
				}
			}
			
			return AnonymousDisposable {
				disposable.dispose()
			}
		}
	}
	
	func checkPlaying() -> Bool {
		return playList.synchronize().uid == mainModel.currentPlayingContainerUid && mainModel.player.playing
	}
	
	func togglePlayerState(startPlayingWith: TrackType? = nil) {
		if checkPlaying() && mainModel.currentPlayingContainerUid == playList.uid {
			mainModel.player.pause()
		} else if mainModel.currentPlayingContainerUid == playList.uid &&
			mainModel.player.currentItems.count == playList.items.count {
			mainModel.player.resume(true)
		} else {
			mainModel.playPlayList(playList, startWith: startPlayingWith)
		}
	}
}