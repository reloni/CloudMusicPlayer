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
	private var cachingTask: Disposable?//Observable<CacheDataResult>?
	private var bag = DisposeBag()
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
//		guard let nsUrl = NSURL(string: self.url), component = NSURLComponents(URL: nsUrl, resolvingAgainstBaseURL: false) else {
//			return nil
//		}
//		
//		component.scheme = "streamPlayerFakeScheme"
		//return component.URL
		return NSURL(string: "fake://url.com")
	}()

	init(player: StreamAudioPlayer, url: String) {
		self.player = player
		self.url = url
	}
	
	deinit {
		print("StreamAudioItem deinit")
	}
}

extension StreamAudioItem : AVAssetResourceLoaderDelegate {
	public func resourceLoader(resourceLoader: AVAssetResourceLoader, didCancelLoadingRequest loadingRequest: AVAssetResourceLoadingRequest) {
		
	}
	
	public func resourceLoader(resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
		guard player.allowCaching, let nsUrl = NSURL(string: url) else {
			return false
		}
		
		let request = NSMutableURLRequest(URL: nsUrl)
		player.customHttpHeaders?.forEach { request.addValue($1, forHTTPHeaderField: $1) }
		
		if let newTask = StreamDataCacheManager.createTask(request, resourceLoadingRequest: loadingRequest)
			where cachingTask == nil {
			cachingTask = newTask.bindNext { [weak self] result in
				switch result {
				case .Success:
					print("success!!")
				case .SuccessWithCache(let url):
					print("success with url: \(url.path)")
				case .Error(let error):
					print("end with error: \(error)")
				}
				if let strongSelf = self {
					strongSelf.cachingTask?.dispose()
					strongSelf.cachingTask = nil
				}
			}
			cachingTask?.addDisposableTo(bag)
				
			return true
		}
		
		return true
	}
}