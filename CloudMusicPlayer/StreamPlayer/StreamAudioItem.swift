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
import UIKit

@objc public class StreamAudioItem : NSObject {
	private var cachingTask: Disposable?
	private var bag = DisposeBag()
	public let url: String
	public weak var player: StreamAudioPlayer?
	private let customHttpHeaders: [String: String]?
	
	public lazy var playerItem: AVPlayerItem? = {
		guard let nsUrl = self.fakeUrl ?? NSURL(string: self.url) else {
			return nil
		}
		
		let asset = AVURLAsset(URL: nsUrl)
		asset.resourceLoader.setDelegate(self, queue: dispatch_get_global_queue(QOS_CLASS_UTILITY, 0))
		
		let item = AVPlayerItem(asset: asset)
		return item
	}()
	
	public lazy var fakeUrl: NSURL? = {
		guard let nsUrl = NSURL(string: self.url), component = NSURLComponents(URL: nsUrl, resolvingAgainstBaseURL: false) else {
			return nil
		}

		if (component.scheme == "http" || component.scheme == "https") {
				return NSURL(string: "fake://url.com")
		}
		
		return nil
	}()

	init(player: StreamAudioPlayer, url: String, customHttpHeaders: [String: String]? = nil) {
		self.player = player
		self.url = url
		self.customHttpHeaders = customHttpHeaders
	}
	
	deinit {
		print("StreamAudioItem deinit")
	}
	
	private lazy var metadata: [String: AnyObject?] = {
		guard let metadataList = self.playerItem?.asset.metadata else {
			return [String: AnyObject]()
		}
		return Dictionary<String, AnyObject?>(metadataList.filter { $0.commonKey != nil }.map { ($0.commonKey!, $0.value as? AnyObject)})
	}()
	
	public lazy var title: String? = {
		return self.metadata["title"] as? String
	}()
	
	public lazy var artist: String? = {
		return self.metadata["artist"] as? String
	}()
	
	public lazy var album: String? = {
		return self.metadata["albumName"] as? String
	}()
	
	public lazy var artwork: UIImage? = {
		guard let data = self.metadata["artwork"] as? NSData else {
			return nil
		}
		return UIImage(data: data)
	}()
	
	public var duration: CMTime? {
		return playerItem?.duration
	}
	
	public var durationString: String? {
		guard let dur = duration else { return nil }
		return dur.asString
	}
	
	public lazy var currentTime: Observable<CMTime> = {
		return Observable.create { [unowned self] observer in
			let timer = NSTimer.schedule(repeatInterval: 1) { timer in
				guard let item = self.playerItem else {
					return
				}
				observer.onNext(item.currentTime())
			}
			return AnonymousDisposable {
				timer.invalidate()
			}
		}
	}()
	
	//public let currentTime = Variable<CMTime?>(nil)
}

extension StreamAudioItem : AVAssetResourceLoaderDelegate {
	public func resourceLoader(resourceLoader: AVAssetResourceLoader, didCancelLoadingRequest loadingRequest: AVAssetResourceLoadingRequest) {
		print("didCancelLoadingRequest")
	}
	
	public func resourceLoader(resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
		print("shouldWaitForLoadingOfRequestedResource")
		
		guard let player = player, let nsUrl = NSURL(string: url) else {
			return false
		}
		
		let request = NSMutableURLRequest(URL: nsUrl)
		customHttpHeaders?.forEach { request.addValue($1, forHTTPHeaderField: $1) }
		
		if let newTask = StreamDataCacheManager.createTask(request, resourceLoadingRequest: loadingRequest, saveCachedData: player.allowCaching)
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