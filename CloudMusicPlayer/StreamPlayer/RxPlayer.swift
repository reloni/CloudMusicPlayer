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
	case PreparingToPlay(RxPlayerQueueItem, ContentType?)
	case Started
	case Stopping(RxPlayerQueueItem)
	case Stopped
	case Pausing(RxPlayerQueueItem)
	case Paused
	case DispatchQueue(RxPlayer)
}

internal class GlobalPlayerHolder {
	static let instance = GlobalPlayerHolder()

	var player: AVPlayerProtocol?
	var observer: AVAssetResourceLoaderEventsObserver!
	let subject = PublishSubject<PlayerEvents>()
	var bag: DisposeBag!
	var asset: AVURLAssetProtocol!
	var playerItem: AVPlayerItemProtocol!
	
	func initialize(playerItem: AVPlayerItemProtocol, asset: AVURLAssetProtocol, observer: AVAssetResourceLoaderEventsObserver) -> Observable<AssetLoadingEvents> {
		stop()
		bag = DisposeBag()
		
		self.asset = asset
		self.playerItem = playerItem
		self.observer = observer
		self.player = AVPlayer(playerItem: playerItem as! AVPlayerItem)

		player?.internalItemStatus.bindNext { [weak self] status in
			print("player status: \(status?.rawValue)")
			if status == AVPlayerItemStatus.ReadyToPlay {
				self?.player?.play()
				self?.subject.onNext(.Started)
			}
		}.addDisposableTo(bag)
		
		return observer.loaderEvents
	}
	
	func stop() {
		player?.replaceCurrentItemWithPlayerItem(nil)
		player = nil
		bag = nil
	}
	
	deinit {
		stop()
	}
}


public class RxPlayer {
	internal var itemsSet = NSMutableOrderedSet()
	internal var queueEventsSubject = PublishSubject<PlayerEvents>()
	internal let serialScheduler = SerialDispatchQueueScheduler(globalConcurrentQueueQOS: DispatchQueueSchedulerQOS.Utility)

	public lazy var playerEvents: Observable<PlayerEvents> = {
		return Observable.create { [weak self] observer in
			guard let object = self else { observer.onCompleted(); return NopDisposable.instance }
			
			
			let first = object.queueEventsSubject.shareReplay(1).observeOn(object.serialScheduler).subscribe(observer)
			let second = GlobalPlayerHolder.instance.subject.shareReplay(1).observeOn(object.serialScheduler).subscribe(observer)
			
			return AnonymousDisposable {
				first.dispose()
				second.dispose()
			}
		}
	}()
	
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
		}
	}
	
	public internal(set) var repeatQueue: Bool {
		didSet {
			queueEventsSubject.onNext(.RepeatChanged(repeatQueue))
		}
	}
	
	public init(repeatQueue: Bool = false) {
		self.repeatQueue = repeatQueue
	}
	
	deinit {
		print("Rx player deinit")
		queueEventsSubject.onCompleted()
	}
}