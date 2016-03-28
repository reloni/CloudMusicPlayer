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

public protocol StreamAudioItemProtocol { }
extension StreamAudioItem : StreamAudioItemProtocol { }

public class StreamAudioItem {
	private var bag = DisposeBag()
	public unowned var player: StreamAudioPlayer
	internal var observer = AVAssetResourceLoaderEventsObserver()
	internal var assetLoader: AssetResourceLoader?
	internal let urlRequest: NSMutableURLRequestProtocol
	
	init(player: StreamAudioPlayer, urlRequest: NSMutableURLRequestProtocol) {
		self.player = player
		self.urlRequest = urlRequest
	
		observer.loaderEvents.filter { if case .StartLoading = $0 { return true } else { return false } }.flatMapLatest { _ -> Observable<CacheDataResult> in
			let task = self.player.httpClient.loadAndCacheData(self.urlRequest, sessionConfiguration: NSURLSession.defaultConfig, saveCacheData: false,
				targetMimeType: "audio/mpeg")
			self.assetLoader = AssetResourceLoader(cacheTask: task, assetLoaderEvents: self.observer.loaderEvents)
			return task
		}.subscribe().addDisposableTo(bag)
	}
	
	deinit {
		print("StreamAudioItem deinit")
	}
	
	internal lazy var urlAsset: AVURLAssetProtocol? = {
		guard let nsUrl = self.fakeUrl ?? self.urlRequest.URL else { return nil }
		return self.player.utilities.createavUrlAsset(nsUrl)
	}()
	
	public lazy var playerItem: AVPlayerItemProtocol? = {
		guard let asset = self.urlAsset else { return nil }
		asset.getResourceLoader().setDelegate(self.observer, queue: dispatch_get_global_queue(QOS_CLASS_UTILITY, 0))
		return self.player.utilities.createavPlayerItem(asset)
	}()
	
	public lazy var fakeUrl: NSURL? = {
		guard let nsUrl = self.urlRequest.URL, component = NSURLComponents(URL: nsUrl, resolvingAgainstBaseURL: false) else {
			return nil
		}

		if (component.scheme == "http" || component.scheme == "https") {
				return NSURL(string: "fake://url.com")
		}
		
		return nil
	}()
	
	internal lazy var metadata: AudioItemMetadata? = {
		guard let meta = self.playerItem?.getAsset().getMetadata() else { return nil }
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