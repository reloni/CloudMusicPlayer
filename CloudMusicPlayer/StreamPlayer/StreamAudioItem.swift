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
	public let url: String
	public unowned let player: StreamAudioPlayer
	public private (set) var cachedData = Variable<NSURL?>(nil)
	public lazy var playerItem: AVPlayerItem? = {
		guard let nsUrl = NSURL(string: self.url) else {
			return nil
		}
		let asset = AVURLAsset(URL: nsUrl)
		asset.resourceLoader.setDelegate(self, queue: dispatch_get_main_queue())
		return AVPlayerItem(asset: asset)
	}()

	init(player: StreamAudioPlayer, url: String) {
		self.player = player
		self.url = url
	}
	
	
	
	public func cache() {
		cachedData.value = NSURL(string: "https://ya.ru")
		//NSURLComponents *components = [[NSURLComponents alloc] initWithURL:[self songURL] resolvingAgainstBaseURL:NO];
		//components.scheme = scheme;
	}
}

extension StreamAudioItem : AVAssetResourceLoaderDelegate {
	public func resourceLoader(resourceLoader: AVAssetResourceLoader, didCancelLoadingRequest loadingRequest: AVAssetResourceLoadingRequest) {
		
	}
	
	public func resourceLoader(resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
		if let nsUrl = NSURL(string: url), component = NSURLComponents(URL: nsUrl, resolvingAgainstBaseURL: false) {
			//let task = StreamDataCacheManager.createTask(NSMutableURLRequest(URL: nsUrl), resourceLoadingRequest: loadingRequest)
			
		}
		
		return true
	}
}