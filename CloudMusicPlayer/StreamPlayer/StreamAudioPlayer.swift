//
//  StreamPlayer.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 01.03.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import AVFoundation
import RxSwift
import RxCocoa

public class StreamAudioPlayer {
	private var bag = DisposeBag()
	public let allowCaching: Bool
	private var internalPlayer: AVPlayer?
	private var currentItem: StreamAudioItem?
	private var session: NSURLSession?
	
	init(session: NSURLSession? = nil, allowCaching: Bool = true) {
		self.session = session
		self.allowCaching = allowCaching
	}
	
	public func play(url: String) -> StreamAudioItem? {
		guard let playerItem = currentItem?.playerItem else {
			return nil
		}
		
		currentItem = StreamAudioItem(player: self, url: url)
		internalPlayer = AVPlayer(playerItem: playerItem)
		internalPlayer?.rx_observe(AVPlayerItemStatus.self, "status").subscribeNext { [weak self] status in
			if let strong = self {
				print("player status: \(status?.rawValue)")
				if status == .ReadyToPlay {
					strong.internalPlayer?.play()
				}
			}
			}.addDisposableTo(self.bag)

		return currentItem!
	}
}