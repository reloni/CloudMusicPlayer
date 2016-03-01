//
//  StreamPlayer.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 01.03.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import AVFoundation

public class StreamPlayer {
	public let allowCaching: Bool
	private var internalPlayer: AVPlayer?
	private var currentItem: StreamAudioItem?
	private var session: NSURLSession?
	
	init(session: NSURLSession? = nil, allowCaching: Bool = true) {
		self.session = session
		self.allowCaching = allowCaching
	}
	
	public func play(url: String) -> StreamAudioItem {
		currentItem = StreamAudioItem(player: self, url: url)
		
		if let playerItem = currentItem?.playerItem {
			internalPlayer = AVPlayer(playerItem: playerItem)
		}
		
		return currentItem!
	}
}