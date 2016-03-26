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
	
		observer.loaderEvents.bindNext { [unowned self] result in
			if case .StartLoading = result {
				self.cachingTask?.bindNext { [unowned self ]result in
					if case .Success = result {
						print("Success")
						self.assetLoader = nil
					} else if case .SuccessWithCache = result {
						print("SuccessWithCache")
						self.assetLoader = nil
					} else if case .Error = result {
						print("Error")
						self.assetLoader = nil
					}
				}.addDisposableTo(self.bag)
			}
		}.addDisposableTo(bag)
	}
	
	deinit {
		print("StreamAudioItem deinit")
	}
	
	internal lazy var cachingTask: Observable<CacheDataResult>? = { [unowned self] in
		guard let urlRequest = self.urlRequest else { return nil }
		
		return Observable.create { [unowned self] observer in
			let cacheTask = self.player.httpUtilities.createCacheDataTask(urlRequest, sessionConfiguration: NSURLSession.defaultConfig,
				saveCachedData: self.player.allowCaching, targetMimeType: "audio/mpeg")
			
			self.assetLoader = AssetResourceLoader(cacheTask: cacheTask, assetLoaderEvents: self.observer.loaderEvents)
			
			cacheTask.taskProgress.bindNext { result in
				observer.onNext(result)
				if case .Success = result {
					observer.onCompleted()
				} else if case .SuccessWithCache = result {
					observer.onCompleted()
				} else if case .Error = result {
					observer.onCompleted()
				}
			}.addDisposableTo(self.bag)
			
			cacheTask.resume()
			
			return AnonymousDisposable {
				print("dispose!!")
				cacheTask.cancel()
			}
		}.shareReplay(1)
	}()
	
	
	internal lazy var urlRequest: NSMutableURLRequestProtocol? = {
		return self.player.httpUtilities.createUrlRequest(self.url, parameters: nil, headers: self.customHttpHeaders)
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