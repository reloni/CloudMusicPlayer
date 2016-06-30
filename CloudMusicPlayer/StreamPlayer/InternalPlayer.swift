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

public protocol InternalPlayerType {
	func play(resource: StreamResourceIdentifier) -> Observable<Result<Void>>
	func stop()
	func pause()
	func resume()
	var currentTime: Observable<(currentTime: CMTime?, duration: CMTime?)?> { get }
	var nativePlayer: AVPlayerProtocol? { get }
	func getCurrentTimeAndDuration() -> (currentTime: CMTime, duration: CMTime)?
}

public class InternalPlayer {
	public var nativePlayer: AVPlayerProtocol?
	var observer: AVAssetResourceLoaderEventsObserverProtocol?
	let eventsCallback: (PlayerEvents) -> ()
	
	var bag: DisposeBag
	var asset: AVURLAssetProtocol?
	var playerItem: AVPlayerItemProtocol?
	var hostPlayer: RxPlayer
	
	deinit {
		stop()
	}
	
	internal init(hostPlayer: RxPlayer, eventsCallback: (PlayerEvents) -> ()) {
		self.hostPlayer = hostPlayer
		self.eventsCallback = eventsCallback
		bag = DisposeBag()
	}
}

extension InternalPlayer : InternalPlayerType {
	public func getCurrentTimeAndDuration() -> (currentTime: CMTime, duration: CMTime)? {
		guard let playerItem = self.playerItem, asset = self.asset else { return nil }
		return (currentTime: playerItem.currentTime(), duration: asset.duration)
	}
	
	public var currentTime: Observable<(currentTime: CMTime?, duration: CMTime?)?> {
		return Observable.create { [weak self] observer in
			guard let object = self else {
				observer.onNext(nil); observer.onCompleted(); return NopDisposable.instance
			}
			
			return Observable<Int>.interval(0.5, scheduler: SerialDispatchQueueScheduler(globalConcurrentQueueQOS: DispatchQueueSchedulerQOS.Utility))
				.bindNext { _ in
					if let playerItem = object.playerItem, asset = object.asset {
						observer.onNext((currentTime: playerItem.currentTime(), duration: asset.duration))
					} else {
						observer.onNext(nil)
					}
			}
		}
	}
	
	public func play(resource: StreamResourceIdentifier) -> Observable<Result<Void>> {
		let asset = hostPlayer.streamPlayerUtilities.createavUrlAsset(NSURL(string: "fake://domain.com")!)
		let observer = AVAssetResourceLoaderEventsObserver()
		asset.getResourceLoader().setDelegate(observer, queue: dispatch_get_global_queue(QOS_CLASS_UTILITY, 0))
		let playerItem = hostPlayer.streamPlayerUtilities.createavPlayerItem(asset)
		
		let downloadTask = hostPlayer.downloadManager.createDownloadObservable(resource, priority: .Normal)
		
		let task = downloadTask.loadWithAsset(
			assetEvents: observer.loaderEvents,
			targetAudioFormat: resource.streamResourceContentType)
		
		DispatchQueue.async(.Utility) { [weak self, playerItem, asset, observer] in
			self?.play(playerItem, asset: asset, observer: observer)
		}
		
		return task
	}
	
	internal func play(playerItem: AVPlayerItemProtocol, asset: AVURLAssetProtocol, observer: AVAssetResourceLoaderEventsObserverProtocol) {
		flush()
		
		// setup audio session
		do {
			try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, withOptions: .DefaultToSpeaker)
			try AVAudioSession.sharedInstance().setMode(AVAudioSessionModeDefault)
			try AVAudioSession.sharedInstance().setActive(true)
		} catch let error as NSError {
			NSLog("Error while set up audio session \(error.localizedDescription)")
		}
		
		self.asset = asset
		self.playerItem = playerItem
		self.observer = observer
		self.nativePlayer = AVPlayer(playerItem: playerItem as! AVPlayerItem)
		
		nativePlayer?.internalItemStatus.bindNext { [weak self] status in
			//print("player status: \(status?.rawValue)")
			if status == AVPlayerItemStatus.ReadyToPlay {
				self?.nativePlayer?.play()
				self?.eventsCallback(.Started)
				
				if let object = self {
					NSNotificationCenter.defaultCenter().addObserver(object, selector:
						#selector(object.finishPlayingItem), name: AVPlayerItemDidPlayToEndTimeNotification, object: object.playerItem as? AVPlayerItem)
					NSNotificationCenter.defaultCenter().addObserver(object, selector:
						#selector(object.playbackStalled), name: AVPlayerItemPlaybackStalledNotification, object: object.playerItem as? AVPlayerItem)
					NSNotificationCenter.defaultCenter().addObserver(object, selector:
						#selector(object.newErrorLogEntry), name: AVPlayerItemNewErrorLogEntryNotification, object: object.playerItem as? AVPlayerItem)
					NSNotificationCenter.defaultCenter().addObserver(object, selector:
						#selector(object.failedToPlayToEnd), name: AVPlayerItemFailedToPlayToEndTimeNotification, object: object.playerItem as? AVPlayerItem)
				}
			} else if status == AVPlayerItemStatus.Failed {
				NSLog("player error: \((self?.nativePlayer as? AVPlayer)?.error?.localizedDescription)")
				self?.flush()
			}
			}.addDisposableTo(bag)
		
		hostPlayer.beginBackgroundTask()
	}
	
	func flush() {
		NSNotificationCenter.defaultCenter().removeObserver(self, name: AVPlayerItemDidPlayToEndTimeNotification, object: playerItem as? AVPlayerItem)
		NSNotificationCenter.defaultCenter().removeObserver(self, name: AVPlayerItemPlaybackStalledNotification, object: playerItem as? AVPlayerItem)
		NSNotificationCenter.defaultCenter().removeObserver(self, name: AVPlayerItemNewErrorLogEntryNotification, object: playerItem as? AVPlayerItem)
		NSNotificationCenter.defaultCenter().removeObserver(self, name: AVPlayerItemFailedToPlayToEndTimeNotification, object: playerItem as? AVPlayerItem)
		nativePlayer?.replaceCurrentItemWithPlayerItem(nil)
		nativePlayer = nil
		asset = nil
		playerItem = nil
		bag = DisposeBag()
		
		do {
			try AVAudioSession.sharedInstance().setActive(false, withOptions: AVAudioSessionSetActiveOptions.NotifyOthersOnDeactivation)
		} catch let error as NSError {
			NSLog("Error while deactivating up audio session \(error.localizedDescription)")
		}
	}
	
	public func stop() {
		flush()
		eventsCallback(.Stopped)
		hostPlayer.endBackgroundTask()
	}
	
	public func pause() {
		if let nativePlayer = nativePlayer {
			nativePlayer.setPlayerRate(0.0)
			eventsCallback(.Paused)
		}
		hostPlayer.endBackgroundTask()
	}
	
	public func resume() {
		if let nativePlayer = nativePlayer {
			nativePlayer.setPlayerRate(1.0)
			eventsCallback(.Resumed)
			hostPlayer.beginBackgroundTask()
		}
	}
	
	func switchToNextItem(force: Bool) {
		if force || !isTimeChanging() {
			flush()
			eventsCallback(.FinishPlayingCurrentItem)
			hostPlayer.toNext(true)
		}
	}
	
	func isTimeChanging() -> Bool {
		guard let curTime = getCurrentTimeAndDuration()?.currentTime else { return false }
		NSThread.sleepForTimeInterval(1)
		guard let newTime = getCurrentTimeAndDuration()?.currentTime else { return false }
		return curTime != newTime
	}
	
	@objc func finishPlayingItem(notification: NSNotification) {
		switchToNextItem(false)
	}
	
	@objc func playbackStalled(notification: NSNotification) {
		dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) { [weak self] in
			self?.switchToNextItem(false)
		}
	}
	
	@objc func newErrorLogEntry(notification: NSNotification) {
		
	}
	
	@objc func failedToPlayToEnd(notification: NSNotification) {
		finishPlayingItem(notification)
	}
}