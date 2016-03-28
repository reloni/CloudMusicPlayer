//
//  PlayerQueue.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 28.03.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation

public protocol PlayerQueueItemProtocol {
	var parent: PlayerQueueItemProtocol? { get }
	var child: PlayerQueueItemProtocol? { get }
	var playerItem: StreamAudioItemProtocol { get }
}

public protocol PlayerQueueProtocol {
	var root: PlayerQueueItemProtocol { get }
	var last: PlayerQueueItemProtocol { get }
	var current: PlayerQueueItemProtocol? { get }
	var count: UInt { get }
}

public class PlayerQueue : PlayerQueueProtocol {
	public private(set) var root: PlayerQueueItemProtocol
	public private(set) var last: PlayerQueueItemProtocol
	public private(set) var current: PlayerQueueItemProtocol?
	public private(set) var count: UInt
	
	private init(root: PlayerQueueItemProtocol, last: PlayerQueueItemProtocol, count: UInt) {
		self.root = root
		self.last = last
		self.count = count
	}
	
	public convenience init?(items: [StreamAudioItemProtocol]) {
		guard items.count > 0 else { return nil }
		let (first, last, count) = PlayerQueue.initWithItems(items)
		self.init(root: first, last: last, count: count)
	}
	
	internal static func initWithItems(items: [StreamAudioItemProtocol], shuffle: Bool = false) ->
		(first: PlayerQueueItemProtocol, last: PlayerQueueItemProtocol, count: UInt){
			guard items.count > 1 else {
				let item = PlayerQueueItem(playerItem: items.first!)
				return (item, item, 1)
			}
			
			var queueItems = items.map { PlayerQueueItem(playerItem: $0) }
			if shuffle {
				queueItems = queueItems.shuffle()
			}
			
			let last = queueItems.reduce(queueItems.first!) { item, next in
				item.child = next
				next.parent = item
				return next
			}
			
			return (queueItems.first!, last, UInt(items.count))
	}
}

public class PlayerQueueItem : PlayerQueueItemProtocol {
	public var parent: PlayerQueueItemProtocol?
	public var child: PlayerQueueItemProtocol?
	public let playerItem: StreamAudioItemProtocol
	
	public init(playerItem: StreamAudioItemProtocol) {
		self.playerItem = playerItem
	}
}