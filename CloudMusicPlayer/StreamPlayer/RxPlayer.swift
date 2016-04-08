//
//  RxPlayer.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 08.04.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import RxSwift

public protocol PlayerEventType { }

public enum PlayerEvents : PlayerEventType {
	case AddNewItem(RxPlayerQueueItem)
	case RemoveItem(RxPlayerQueueItem)
	case Shuflle([RxPlayerQueueItem])
	case InitWithNewItems([RxPlayerQueueItem])
	case CurrentItemChanged(RxPlayerQueueItem?)
	case RepeatChanged(Bool)
	case ChangeItemsOrder(RxPlayer)
	case PreparingToPlay(RxPlayerQueueItem, ContentType?)
	case Started(RxPlayerQueueItem)
	case Stopped
	case Paused
}

public class RxPlayer {
	internal var itemsSet = NSMutableOrderedSet()
	internal var queueEventsSubject = PublishSubject<PlayerEvents>()
	
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
}