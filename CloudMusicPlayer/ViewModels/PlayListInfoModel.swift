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
}