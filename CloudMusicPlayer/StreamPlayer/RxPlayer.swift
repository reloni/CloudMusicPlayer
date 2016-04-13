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
	case DispatchQueue(RxPlayer)
}

internal protocol InternalPlayerType {
	func play(playerItem: AVPlayerItemProtocol, asset: AVURLAssetProtocol, observer: AVAssetResourceLoaderEventsObserverProtocol,
	          loadMetadata: Bool)
	func stop()
	func pause()
	func resume()
	var events: Observable<PlayerEvents> { get }
	var metadata: Observable<AudioItemMetadata?> { get }
	var duration: Observable<CMTime?> { get }
	//var currentTime: Observable<CMTime?> { get }
	var nativePlayer: AVPlayerProtocol? { get }
}

internal class InternalPlayer {
	var nativePlayer: AVPlayerProtocol?
	var observer: AVAssetResourceLoaderEventsObserverProtocol?
	let subject = PublishSubject<PlayerEvents>()
	let metadataSubject = BehaviorSubject<AudioItemMetadata?>(value: nil)
	let durationSubject = BehaviorSubject<CMTime?>(value: nil)
	//let currentTimeSubject = BehaviorSubject<CMTime?>(value: nil)
	var bag: DisposeBag!
	var asset: AVURLAssetProtocol!
	var playerItem: AVPlayerItemProtocol!
	
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
	var metadata: Observable<AudioItemMetadata?> { return metadataSubject }
	var duration: Observable<CMTime?> { return durationSubject }
	//var currentTime: Observable<CMTime?> { return currentTimeSubject }
	
	func play(playerItem: AVPlayerItemProtocol, asset: AVURLAssetProtocol, observer: AVAssetResourceLoaderEventsObserverProtocol,
	          loadMetadata: Bool = true) {
		stop()
		bag = DisposeBag()
		
		self.asset = asset
		self.playerItem = playerItem
		self.observer = observer
		self.nativePlayer = AVPlayer(playerItem: playerItem as! AVPlayerItem)
		
		nativePlayer?.internalItemStatus.bindNext { [weak self] status in
			print("player status: \(status?.rawValue)")
			if status == AVPlayerItemStatus.ReadyToPlay {
				self?.nativePlayer?.play()
				self?.subject.onNext(.Started)
			}
		}.addDisposableTo(bag)
		
		if loadMetadata {
			self.asset.loadMetadata().bindNext { [weak self] meta in
				self?.metadataSubject.onNext(meta)
			}.addDisposableTo(bag)
		}
		
		self.asset.loadDuration().bindNext { [weak self] duration in
			self?.durationSubject.onNext(duration)
		}.addDisposableTo(bag)
	}
	
	func stop() {
		nativePlayer?.replaceCurrentItemWithPlayerItem(nil)
		nativePlayer = nil
		asset = nil
		playerItem = nil
		subject.onNext(.Stopped)
	}
	
	func pause() {
		if let nativePlayer = nativePlayer {
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
}


public class RxPlayer {
	internal let internalPlayer: InternalPlayerType
	
	internal var itemsSet = NSMutableOrderedSet()
	internal var queueEventsSubject = PublishSubject<PlayerEvents>()
	internal var currentItemMetadataSubject = BehaviorSubject<AudioItemMetadata?>(value: nil)
	
	internal let serialScheduler = SerialDispatchQueueScheduler(globalConcurrentQueueQOS: DispatchQueueSchedulerQOS.Utility)
	public internal(set) var playing: Bool = false
	
	public lazy var playerEvents: Observable<PlayerEvents> = {
		return Observable.create { [weak self] observer in
			guard let object = self else { observer.onCompleted(); return NopDisposable.instance }
			
			
			let first = object.queueEventsSubject.shareReplay(1).observeOn(object.serialScheduler).subscribe(observer)
			let second = object.internalPlayer.events.shareReplay(1).observeOn(object.serialScheduler).subscribe(observer)
			
			return AnonymousDisposable {
				first.dispose()
				second.dispose()
			}
		}
	}()
	
	public var currentItemMetadata: Observable<AudioItemMetadata?>  {
		return internalPlayer.metadata.shareReplay(1)
	}
	
	public var currentItemDuration: Observable<CMTime?> {
		return internalPlayer.duration.shareReplay(1)
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
	
	public internal(set) var current: RxPlayerQueueItem? {
		didSet {
			queueEventsSubject.onNext(.CurrentItemChanged(current))
			if playing && current != nil {
				queueEventsSubject.onNext(.PreparingToPlay(current!))
			} else if current == nil {
				playing = false
			}
		}
	}
	
	public internal(set) var repeatQueue: Bool {
		didSet {
			queueEventsSubject.onNext(.RepeatChanged(repeatQueue))
		}
	}
	
	internal init(repeatQueue: Bool, internalPlayer: InternalPlayerType) {
		self.repeatQueue = repeatQueue
		self.internalPlayer = internalPlayer
	}
	
	public convenience init(repeatQueue: Bool = false) {
		self.init(repeatQueue: repeatQueue, internalPlayer: InternalPlayer())
	}
	
	deinit {
		print("Rx player deinit")
		queueEventsSubject.onCompleted()
	}
}