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

public enum PlayerStatus {
	case Playing
	case Stopped
	case Paused
}

public class StreamAudioPlayer {
	private var bag = DisposeBag()
	public let allowCaching: Bool
	private var internalPlayer: AVPlayer?
	public var currentItem = Variable<StreamAudioItem?>(nil)
	public let status = BehaviorSubject<PlayerStatus>(value: .Stopped)
	public let httpClient: HttpClientProtocol
	internal let utilities: StreamPlayerUtilitiesProtocol
	internal let queue = PlayerQueue()
		
	init(allowCaching: Bool = true, httpClient: HttpClientProtocol = HttpClient.instance,
	     utilities: StreamPlayerUtilitiesProtocol = StreamPlayerUtilities.instance) {
		self.allowCaching = allowCaching
		self.httpClient = httpClient
		self.utilities = utilities
	}
	
	public func play(url: String, customHttpHeaders: [String: String]? = nil) {
		stop()
		
		guard let urlRequest = httpClient.httpUtilities.createUrlRequest(url, parameters: nil, headers: customHttpHeaders) else {
			return
		}
		
		let newAudioItem = StreamAudioItem(player: self, urlRequest: urlRequest)
		
		guard let playerItem = newAudioItem.playerItem else {
			currentItem.value = nil
			return
		}
		
		currentItem.value = newAudioItem
		internalPlayer = AVPlayer(playerItem: playerItem as! AVPlayerItem)
		
		internalPlayer?.rx_observe(AVPlayerItemStatus.self, "status").subscribeNext { [weak self] status in
			if let strong = self {
				print("player status: \(status?.rawValue)")
				if status == .ReadyToPlay {
					strong.internalPlayer?.play()
					strong.status.onNext(.Playing)
				}
			}
		}.addDisposableTo(self.bag)
	}
	
	internal func playUrl(url: String, customHttpHeaders: [String: String]? = nil, resourceMimeType: String? = nil) {
		stop()
		guard let urlRequest = httpClient.httpUtilities.createUrlRequest(url, parameters: nil, headers: customHttpHeaders) else {
			return
		}
		let streamResource = utilities.createStreamResourceIdentifier(urlRequest, httpClient: httpClient,
											saveCachedData: allowCaching, targetMimeType: resourceMimeType)
		let streamItem = utilities.createStreamAudioItem(self, streamResourceIdentifier: streamResource)
		queue.initWithNewItems([streamItem])
		playNext()
	}
	
	public func playNext() {
		guard let next = queue.toNext(), player = utilities.createAVPlayer(next.streamItem) else { return }
		internalPlayer = player
		currentItem.value = next.streamItem
		internalPlayer?.rx_observe(AVPlayerItemStatus.self, "status").subscribeNext { [weak self] status in
			if let strong = self {
				print("player status: \(status?.rawValue)")
				if status == .ReadyToPlay {
					strong.internalPlayer?.play()
					strong.status.onNext(.Playing)
				}
			}
		}.addDisposableTo(self.bag)
	}
	
	public func pause() {
		internalPlayer?.rate = 0.0
		status.onNext(.Paused)
	}
	
	public func resume() {
		internalPlayer?.rate = 1.0
		status.onNext(.Playing)
	}

	public func stop() {
		internalPlayer?.replaceCurrentItemWithPlayerItem(nil)
		internalPlayer = nil
		status.onNext(.Stopped)
	}
}