//
//  InternalPlayer.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 29.04.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import RxSwift
import AVFoundation

internal protocol InternalPlayerType {
	func play(playerItem: AVPlayerItemProtocol, asset: AVURLAssetProtocol, observer: AVAssetResourceLoaderEventsObserverProtocol,
	          hostPlayer: RxPlayer)
	func stop()
	func pause()
	func resume()
	var events: Observable<PlayerEvents> { get }
	var currentTime: Observable<(currentTime: CMTime?, duration: CMTime?)?> { get }
	var nativePlayer: AVPlayerProtocol? { get }
}

internal class InternalPlayer {
	var nativePlayer: AVPlayerProtocol?
	var observer: AVAssetResourceLoaderEventsObserverProtocol?
	let subject = PublishSubject<PlayerEvents>()
	
	//let currentTimeSubject = BehaviorSubject<(currentTime: CMTime?, duration: CMTime?)?>(value: nil)
	var currentTimeDisposable: Disposable?
	var bag: DisposeBag?
	var asset: AVURLAssetProtocol?
	var playerItem: AVPlayerItemProtocol?
	var hostPlayer: RxPlayer?
	
	deinit {
		stop()
	}
	
	internal func dispose() {
		stop()
		//subject.onCompleted()
		bag = nil
	}
}

extension InternalPlayer : InternalPlayerType {
	var events: Observable<PlayerEvents> { return subject }
	
	var currentTime: Observable<(currentTime: CMTime?, duration: CMTime?)?> {
		return Observable.create { [weak self] observer in
			guard let object = self else {
				observer.onNext(nil); observer.onCompleted(); return NopDisposable.instance
			}
			
			return Observable<Int>.interval(1, scheduler: SerialDispatchQueueScheduler(globalConcurrentQueueQOS: DispatchQueueSchedulerQOS.Utility))
				.bindNext { _ in
					//print("current time")
					if let playerItem = object.playerItem, asset = object.asset {
						observer.onNext((currentTime: playerItem.currentTime(), duration: asset.duration))
					} else {
						observer.onNext(nil)
					}
			}
		}
	}
	
	func play(playerItem: AVPlayerItemProtocol, asset: AVURLAssetProtocol, observer: AVAssetResourceLoaderEventsObserverProtocol,
	          hostPlayer: RxPlayer) {
		stop()
		bag = DisposeBag()
		
		self.asset = asset
		self.playerItem = playerItem
		self.observer = observer
		self.hostPlayer = hostPlayer
		self.nativePlayer = AVPlayer(playerItem: playerItem as! AVPlayerItem)
		
		nativePlayer?.internalItemStatus.bindNext { [weak self] status in
			print("player status: \(status?.rawValue)")
			if status == AVPlayerItemStatus.ReadyToPlay {
				self?.nativePlayer?.play()
				self?.subject.onNext(.Started)
				
				if let object = self {
					NSNotificationCenter.defaultCenter().addObserver(object, selector:
						#selector(object.finishPlayingItem), name: AVPlayerItemDidPlayToEndTimeNotification, object: object.playerItem as? AVPlayerItem)
				}
			}
			}.addDisposableTo(bag!)
	}
	
	func flush() {
		NSNotificationCenter.defaultCenter().removeObserver(self, name: AVPlayerItemDidPlayToEndTimeNotification, object: playerItem as? AVPlayerItem)
		nativePlayer?.replaceCurrentItemWithPlayerItem(nil)
		nativePlayer = nil
		asset = nil
		playerItem = nil
		bag = nil
		currentTimeDisposable?.dispose()
	}
	
	func stop() {
		flush()
		subject.onNext(.Stopped)
	}
	
	func pause() {
		if let nativePlayer = nativePlayer {
			currentTimeDisposable?.dispose()
			nativePlayer.setPlayerRate(0.0)
			subject.onNext(.Paused)
		}
	}
	
	func resume() {
		if let nativePlayer = nativePlayer {
			nativePlayer.setPlayerRate(1.0)
			subject.onNext(.Resumed)
		}
	}
	
	@objc func finishPlayingItem() {
		flush()
		guard let player = hostPlayer else { return }
		subject.onNext(.FinishPlayingCurrentItem(player))
		print("finish playing item")
	}
}