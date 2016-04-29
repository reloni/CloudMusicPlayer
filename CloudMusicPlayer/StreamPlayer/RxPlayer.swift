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
	case Unknown
}

public class RxPlayer {
	internal let internalPlayer: InternalPlayerType
	internal let downloadManager: DownloadManagerType
	internal let mediaLibrary: MediaLibraryType
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
	
	public lazy var playerEvents: Observable<PlayerEvents> = {
		return Observable.create { [weak self] observer in
			guard let object = self else { observer.onCompleted(); return NopDisposable.instance }
			
			let first = object.queueEventsSubject.shareReplay(0).doOnError { print("Player event error \($0)") }.observeOn(object.serialScheduler).bindNext { e in
				print("new player event: \(e)")
				observer.onNext(e)
			}
			let second = object.internalPlayer.events.shareReplay(0).doOnError { print("Player event error \($0)") }.observeOn(object.serialScheduler).bindNext { e in
				print("new player event: \(e)")
				observer.onNext(e)
			}
			
			return AnonymousDisposable {
				print("Dispose player events")
				first.dispose()
				second.dispose()
			}
		}.shareReplay(0)
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
	              streamPlayerUtilities: StreamPlayerUtilitiesProtocol, mediaLibrary: MediaLibraryType) {
		self.repeatQueue = repeatQueue
		self.internalPlayer = internalPlayer
		self.downloadManager = downloadManager
		self.streamPlayerUtilities = streamPlayerUtilities
		self.mediaLibrary = mediaLibrary
	}
	
	public convenience init(repeatQueue: Bool = false, saveData: Bool = false) {
		self.init(repeatQueue: repeatQueue, internalPlayer: InternalPlayer(),
		          downloadManager: DownloadManager(saveData: saveData, fileStorage: LocalNsUserDefaultsStorage(persistInformationAboutSavedFiles: saveData),
								httpUtilities: HttpUtilities()), streamPlayerUtilities: StreamPlayerUtilities(), mediaLibrary: NonRetentiveMediaLibrary())
	}
	
	internal convenience init(repeatQueue: Bool = false, internalPlayer: InternalPlayerType, downloadManager: DownloadManagerType) {
		self.init(repeatQueue: repeatQueue, internalPlayer: internalPlayer,
		          downloadManager: downloadManager, streamPlayerUtilities: StreamPlayerUtilities(), mediaLibrary: NonRetentiveMediaLibrary())
	}
	
	deinit {
		print("Rx player deinit")
		//queueEventsSubject.onCompleted()
		//currentItemSubject.onCompleted()
	}
}