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

public class StreamAudioItem {
	private var bag = DisposeBag()
	public let url: String
	public unowned var player: StreamAudioPlayer
	private let customHttpHeaders: [String: String]?
	private var observer = AVAssetResourceLoaderEventsObserver()
	private var assetLoader: AssetResourceLoader?
	
	init(player: StreamAudioPlayer, url: String, customHttpHeaders: [String: String]? = nil) {
		self.player = player
		self.url = url
		self.customHttpHeaders = customHttpHeaders
	
		observer.loaderEvents.filter { if case .StartLoading = $0 { return true } else { return false } }.flatMapLatest { _ -> Observable<CacheDataResult> in
			let task = self.player.httpClient.loadAndCacheData(self.urlRequest!, sessionConfiguration: NSURLSession.defaultConfig, saveCacheData: false,
				targetMimeType: "audio/mpeg")
			self.assetLoader = AssetResourceLoader(cacheTask: task, assetLoaderEvents: self.observer.loaderEvents)
			return task
		}.subscribe().addDisposableTo(bag)
	}
	
	deinit {
		print("StreamAudioItem deinit")
	}
	
	internal lazy var urlRequest: NSMutableURLRequestProtocol? = {
		return self.player.httpClient.httpUtilities.createUrlRequest(self.url, parameters: nil, headers: self.customHttpHeaders)
	}()
	
	internal lazy var urlAsset: AVURLAsset? = {
		guard let nsUrl = self.fakeUrl ?? self.urlRequest?.URL else { return nil }
		return AVURLAsset(URL: nsUrl)
	}()
	
	public lazy var playerItem: AVPlayerItem? = {
		guard let asset = self.urlAsset else { return nil }
		asset.resourceLoader.setDelegate(self.observer, queue: dispatch_get_global_queue(QOS_CLASS_UTILITY, 0))
		return AVPlayerItem(asset: asset)
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
	
	internal lazy var metadata: AudioItemMetadata? = {
		guard let meta = self.playerItem?.asset.getMetadata() else { return nil }
		return AudioItemMetadata(metadata: meta)
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
}