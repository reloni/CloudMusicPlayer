//
//  StreamAudioItem.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 01.03.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import AVFoundation
import RxSwift
import RxCocoa

@objc public class StreamAudioItem : NSObject {
	private var cachingTask: Observable<CacheDataResult>?
	public let url: String
	public unowned let player: StreamAudioPlayer
	
	public lazy var playerItem: AVPlayerItem? = {
		guard let nsUrl = self.fakeUrl else {
			return nil
		}
		let asset = AVURLAsset(URL: nsUrl)
		asset.resourceLoader.setDelegate(self, queue: dispatch_get_main_queue())
		return AVPlayerItem(asset: asset)
	}()
	
	public lazy var fakeUrl: NSURL? = {
		guard let nsUrl = NSURL(string: self.url), component = NSURLComponents(URL: nsUrl, resolvingAgainstBaseURL: false) else {
			return nil
		}
		
		component.scheme = "streamPlayerFakeScheme"
		return component.URL
	}()

	init(player: StreamAudioPlayer, url: String) {
		self.player = player
		self.url = url
	}
}

extension StreamAudioItem : AVAssetResourceLoaderDelegate {
	public func resourceLoader(resourceLoader: AVAssetResourceLoader, didCancelLoadingRequest loadingRequest: AVAssetResourceLoadingRequest) {
		cachingTask = nil
	}
	
	public func resourceLoader(resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
		guard player.allowCaching, let nsUrl = NSURL(string: url) else {
			return false
		}
		
		cachingTask = StreamDataCacheManager.createTask(NSMutableURLRequest(URL: nsUrl), resourceLoadingRequest: loadingRequest)
		
		return true
	}
}