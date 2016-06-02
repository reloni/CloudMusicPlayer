//
//  PlayerStatePersistanceProvider.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 02.06.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import Realm
import RealmSwift

public protocol RxPlayerPersistanceProviderType {
	func savePlayerState(player: RxPlayer) throws
	func loadPlayerState(player: RxPlayer) throws
}

public class RealmRxPlayerPersistanceProvider {
	internal func getOrCreatePlayerState(realm: Realm) -> RealmPlayerState {
		if let state = realm.objects(RealmPlayerState).first {
			return state
		}
		let state = RealmPlayerState()
		realm.add(state)
		return state
	}
}

extension RealmRxPlayerPersistanceProvider : RxPlayerPersistanceProviderType {
	public func savePlayerState(player: RxPlayer) throws {
		
	}
	
	public func loadPlayerState(player: RxPlayer) throws {
		let realm = try Realm()
		
		realm.beginWrite()
		
		let state = getOrCreatePlayerState(realm)
		state.shuffle = player.shuffleQueue
		state.repeatQueue = player.repeatQueue
		
		realm.delete(realm.objects(RealmPlayerQueueItem))
		
		player.currentItems.forEach {
			let newItem = RealmPlayerQueueItem()
			newItem.uid = $0.streamIdentifier.streamResourceUid
			realm.add(newItem)
			state.queueItems.append(newItem)
			
			if player.current?.streamIdentifier.streamResourceUid == $0.streamIdentifier.streamResourceUid {
				state.currentItem = newItem
				if let currentTime = player.getCurrentItemTimeAndDuration()?.currentTime.safeSeconds {
					state.currentItemTime.value = Float(currentTime)
				}
			}
		}
		
		try realm.commitWrite()
	}
}

public class RealmPlayerState: Object {
	public internal(set) dynamic var shuffle = false
	public internal(set) dynamic var repeatQueue = false
	public let queueItems = List<RealmPlayerQueueItem>()
	public dynamic var currentItem: RealmPlayerQueueItem?
	public var currentItemTime = RealmOptional<Float>(nil)
	
	required public init() {
		super.init()
	}
	
	public required init(realm: RLMRealm, schema: RLMObjectSchema) {
		super.init(realm: realm, schema: schema)
	}
	
	public required init(value: AnyObject, schema: RLMSchema) {
		super.init(value: value, schema: schema)
	}
	
}

public class RealmPlayerQueueItem: Object {
	public dynamic var uid: String = ""
	
	required public init() {
		super.init()
	}
	
	public required init(realm: RLMRealm, schema: RLMObjectSchema) {
		super.init(realm: realm, schema: schema)
	}
	
	public required init(value: AnyObject, schema: RLMSchema) {
		super.init(value: value, schema: schema)
	}
	
	override public static func primaryKey() -> String? {
		return "uid"
	}
}