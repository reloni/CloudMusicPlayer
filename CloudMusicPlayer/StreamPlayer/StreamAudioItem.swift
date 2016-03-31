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

public func ==(lhs: StreamAudioItem, rhs: StreamAudioItem) -> Bool {
	return lhs.hashValue == rhs.hashValue
}

extension StreamAudioItem : Hashable {
	public var hashValue: Int {
		return resourceIdentifier.uid.hashValue
	}
}

extension StreamAudioItem : CustomStringConvertible {
	public var description: String {
		return "Uid = \(resourceIdentifier.uid)"
	}
}

public class StreamAudioItem {
	private var bag = DisposeBag()
	private let fakeUrl = NSURL(string:"fake://url.com")!
	public unowned var player: StreamAudioPlayer
	internal var observer = AVAssetResourceLoaderEventsObserver()
	internal var assetLoader: AssetResourceLoader?
	internal let resourceIdentifier: StreamResourceIdentifier
	
	internal init(resourceIdentifier: StreamResourceIdentifier, player: StreamAudioPlayer) {
		self.player = player
		self.resourceIdentifier = resourceIdentifier
	
		observer.loaderEvents.filter { if case .StartLoading = $0 { return true } else { return false } }.flatMapLatest { _ -> Observable<CacheDataResult> in
			let task = resourceIdentifier.getCacheTaskForResource()
			self.assetLoader = AssetResourceLoader(cacheTask: task, assetLoaderEvents: self.observer.loaderEvents)
			return task
		}.subscribe().addDisposableTo(bag)
	}
	
	internal convenience init(player: StreamAudioPlayer, urlRequest: NSMutableURLRequestProtocol) {
		let urlIdentifier = StreamUrlResourceIdentifier(urlRequest: urlRequest, httpClient: player.httpClient,
											sessionConfiguration: NSURLSession.defaultConfig, saveCachedData: player.allowCaching, targetMimeType: "audio/mpeg")
		self.init(resourceIdentifier: urlIdentifier, player: player)
	}
	
	deinit {
		print("StreamAudioItem deinit")
	}
	
	internal lazy var urlAsset: AVURLAssetProtocol? = {
		return self.player.utilities.createavUrlAsset(self.fakeUrl)
	}()
	
	public lazy var playerItem: AVPlayerItemProtocol? = {
		guard let asset = self.urlAsset else { return nil }
		asset.getResourceLoader().setDelegate(self.observer, queue: dispatch_get_global_queue(QOS_CLASS_UTILITY, 0))
		return self.player.utilities.createavPlayerItem(asset)
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