//
//  RxPlayer.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 08.04.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import AVFoundation
import RxSwift

public protocol PlayerEventType { }

public enum PlayerEvents : PlayerEventType {
	case AddNewItem(RxPlayerQueueItem)
	case AddNewItems([RxPlayerQueueItem])
	case RemoveItem(RxPlayerQueueItem)
	case Shuflle([RxPlayerQueueItem])
	case InitWithNewItems([RxPlayerQueueItem])
	case CurrentItemChanged(RxPlayerQueueItem?)
	case RepeatChanged(Bool)
	case ChangeItemsOrder(RxPlayer)
	case PreparingToPlay(RxPlayerQueueItem)
	case Resuming(RxPlayerQueueItem)
	case Resumed
	case Started
	case Stopping(RxPlayerQueueItem)
	case Stopped
	case Pausing(RxPlayerQueueItem)
	case Paused
	case FinishPlayingCurrentItem(RxPlayer)
	case DispatchQueue(RxPlayer)
}

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
		subject.onCompleted()
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


public class RxPlayer {
	internal let internalPlayer: InternalPlayerType
	internal let downloadManager: DownloadManagerType
	internal let streamPlayerUtilities: StreamPlayerUtilitiesProtocol
	
	internal var itemsSet = NSMutableOrderedSet()
	internal var queueEventsSubject = PublishSubject<PlayerEvents>()
	//internal var currentItemSubject = BehaviorSubject<RxPlayerQueueItem?>(value: nil)
	
	internal let serialScheduler = SerialDispatchQueueScheduler(globalConcurrentQueueQOS: DispatchQueueSchedulerQOS.Utility)
	public internal(set) var playing: Bool = false
	
	public var currentItem: Observable<RxPlayerQueueItem?> {
		return Observable.create { [weak self] observer in
			guard let object = self else { observer.onCompleted(); return NopDisposable.instance }
			
			observer.onNext(object.current)
			
			let disposable = object.playerEvents.filter { e in
				if case PlayerEvents.CurrentItemChanged = e { return true }
				return false
				}.map { e -> RxPlayerQueueItem? in
				if case PlayerEvents.CurrentItemChanged(let item) = e {
					return item
				}
				return nil
				}.subscribe(observer)
		
		
			return AnonymousDisposable {
				disposable.dispose()
			}
		}
	}
	
	public var currentItemTime: Observable<(currentTime: CMTime?, duration: CMTime?)?> {
		return internalPlayer.currentTime.shareReplay(1)
	}
	
	public var playerEvents: Observable<PlayerEvents> {
		return Observable.create { [weak self] observer in
			guard let object = self else { observer.onCompleted(); return NopDisposable.instance }
			
			let first = object.queueEventsSubject.shareReplay(1).observeOn(object.serialScheduler).subscribe(observer)
			let second = object.internalPlayer.events.shareReplay(1).observeOn(object.serialScheduler).subscribe(observer)
			
			return AnonymousDisposable {
				first.dispose()
				second.dispose()
			}
		}
	}
	
	internal lazy var dispatchQueueScheduler: Observable<Void> = {
		return Observable<Void>.create { [weak self] observer in
			guard let object = self else { observer.onCompleted(); return NopDisposable.instance }
			
			let disposable = Observable<Int>.interval(5, scheduler: object.serialScheduler)
				.bindNext { _ in object.queueEventsSubject.onNext(.DispatchQueue(object)) }
			
			return AnonymousDisposable {
				disposable.dispose()
			}
		}
	}()
	
	internal var _current: RxPlayerQueueItem?
	public var current: RxPlayerQueueItem? {
		get {
			return _current
		}
		set {
			if _current == newValue {
				return
			}
			_current = newValue
			
			queueEventsSubject.onNext(.CurrentItemChanged(_current))
			if playing && _current != nil {
				queueEventsSubject.onNext(.PreparingToPlay(_current!))
			} else if _current == nil {
				playing = false
				internalPlayer.stop()
			}
		}
	}
	
	public internal(set) var repeatQueue: Bool {
		didSet {
			queueEventsSubject.onNext(.RepeatChanged(repeatQueue))
		}
	}
	
	internal init(repeatQueue: Bool, internalPlayer: InternalPlayerType, downloadManager: DownloadManagerType,
	              streamPlayerUtilities: StreamPlayerUtilitiesProtocol) {
		self.repeatQueue = repeatQueue
		self.internalPlayer = internalPlayer
		self.downloadManager = downloadManager
		self.streamPlayerUtilities = streamPlayerUtilities
	}
	
	public convenience init(repeatQueue: Bool = false, saveData: Bool = false) {
		self.init(repeatQueue: repeatQueue, internalPlayer: InternalPlayer(),
		          downloadManager: DownloadManager(saveData: saveData, fileStorage: LocalNsUserDefaultsStorage(persistInformationAboutSavedFiles: saveData),
								httpUtilities: HttpUtilities()), streamPlayerUtilities: StreamPlayerUtilities())
	}
	
	internal convenience init(repeatQueue: Bool = false, internalPlayer: InternalPlayerType, downloadManager: DownloadManagerType) {
		self.init(repeatQueue: repeatQueue, internalPlayer: internalPlayer,
		          downloadManager: downloadManager, streamPlayerUtilities: StreamPlayerUtilities())
	}
	
	deinit {
		print("Rx player deinit")
		//queueEventsSubject.onCompleted()
		//currentItemSubject.onCompleted()
	}
}