//
//  FakeStreamPlayer.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 24.03.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
@testable import CloudMusicPlayer
import RxSwift
import AVFoundation

public class FakeStreamResourceIdentifier : StreamResourceIdentifier {
	public var streamResourceUid: String
	init(uid: String) {
		streamResourceUid = uid
	}
	
	public var streamResourceUrl: Observable<String> {
		return Observable.create { observer in
			observer.onNext(self.streamResourceUid)
			
			return NopDisposable.instance
		}.observeOn(ConcurrentDispatchQueueScheduler(globalConcurrentQueueQOS: DispatchQueueSchedulerQOS.Utility))
	}
	
	public var streamResourceContentType: ContentType? {
		return nil
	}
}

public class FakeStreamResourceLoader : StreamResourceLoaderType {
	var items: [String]
	public func loadStreamResourceByUid(uid: String) -> StreamResourceIdentifier? {
		if items.contains(uid) {
			return FakeStreamResourceIdentifier(uid: uid)
		}
		return nil
	}
	public init(items: [String] = []) {
		self.items = items
	}
}

public class FakeAVAssetResourceLoadingContentInformationRequest : AVAssetResourceLoadingContentInformationRequestProtocol {
	public var byteRangeAccessSupported = false
	public var contentLength: Int64 = 0
	public var contentType: String? = nil
}

public class FakeAVAssetResourceLoadingDataRequest : AVAssetResourceLoadingDataRequestProtocol {
	public let respondedData = NSMutableData()
	public var currentOffset: Int64 = 0
	public var requestedOffset: Int64 = 0
	public var requestedLength: Int = 0
	public func respondWithData(data: NSData) {
		respondedData.appendData(data)
		currentOffset += data.length
	}
}

public class FakeAVAssetResourceLoadingRequest : NSObject, AVAssetResourceLoadingRequestProtocol {
	public var contentInformationRequest: AVAssetResourceLoadingContentInformationRequestProtocol
	public var dataRequest: AVAssetResourceLoadingDataRequestProtocol
	public var finished = false

	public init(contentInformationRequest: AVAssetResourceLoadingContentInformationRequestProtocol, dataRequest: AVAssetResourceLoadingDataRequestProtocol) {
		self.contentInformationRequest = contentInformationRequest
		self.dataRequest = dataRequest
	}

	public func getContentInformationRequest() -> AVAssetResourceLoadingContentInformationRequestProtocol? {
		return contentInformationRequest
	}

	public func getDataRequest() -> AVAssetResourceLoadingDataRequestProtocol? {
		return dataRequest
	}

	public func finishLoading() {
		finished = true
	}
}

public class FakeInternalPlayer : InternalPlayerType {
	//public let publishSubject = PublishSubject<PlayerEvents>()
	//public let metadataSubject = BehaviorSubject<AudioItemMetadata?>(value: nil)
	public let durationSubject = BehaviorSubject<CMTime?>(value: nil)
	public let currentTimeSubject = BehaviorSubject<(currentTime: CMTime?, duration: CMTime?)?>(value: nil)
	public let hostPlayer: RxPlayer
	public let eventsCallback: (PlayerEvents) -> ()
	
	public var nativePlayer: AVPlayerProtocol?
	
	//public var events: Observable<PlayerEvents> { return publishSubject }
	//public var metadata: Observable<AudioItemMetadata?> { return metadataSubject.shareReplay(1) }
	public var currentTime: Observable<(currentTime: CMTime?, duration: CMTime?)?> { return currentTimeSubject.shareReplay(1) }
	
	public func resume() {
		//publishSubject.onNext(.Resumed)
		eventsCallback(.Resumed)
	}
	
	public func pause() {
		//publishSubject.onNext(.Paused)
		eventsCallback(.Paused)
	}
	
	public func play(resource: StreamResourceIdentifier) -> Observable<Result<Void>> {
		eventsCallback(.Started)
		return Observable.empty()
	}
	
	public func stop() {
		//publishSubject.onNext(.Stopped)
		eventsCallback(.Stopped)
	}
	
	public func finishPlayingCurrentItem() {
		eventsCallback(.FinishPlayingCurrentItem)
		hostPlayer.toNext(true)
	}
	
	init(hostPlayer: RxPlayer, callback: (PlayerEvents) -> (), nativePlayer: AVPlayerProtocol? = nil) {
		self.hostPlayer = hostPlayer
		self.eventsCallback = callback
		self.nativePlayer = nativePlayer
	}
	
	public func getCurrentTimeAndDuration() -> (currentTime: CMTime, duration: CMTime)? {
		fatalError("getCurrentTimeAndDuration not implemented")
	}
}

public class FakeNativePlayer: AVPlayerProtocol {
	public var internalItemStatus: Observable<AVPlayerItemStatus?> {
		return Observable.just(nil)
	}
	public var rate: Float = 0.0
	public func replaceCurrentItemWithPlayerItem(item: AVPlayerItemProtocol?) {
		
	}
	public func play() {
		
	}
	public func setPlayerRate(rate: Float) {
		
	}
}

public class FakeStreamPlayerUtilities : StreamPlayerUtilitiesProtocol {
	init() {
		
	}
	
	public func createavUrlAsset(url: NSURL) -> AVURLAssetProtocol {
		return StreamPlayerUtilities().createavUrlAsset(url)
	}
	
	public func createavPlayerItem(url: NSURL) -> AVPlayerItemProtocol {
		return StreamPlayerUtilities().createavPlayerItem(url)
	}
	
	public func createavPlayerItem(asset: AVURLAssetProtocol) -> AVPlayerItemProtocol {
		return StreamPlayerUtilities().createavPlayerItem(asset)
	}
	
	public func createInternalPlayer(hostPlayer: RxPlayer, eventsCallback: (PlayerEvents) -> ()) -> InternalPlayerType {
		return FakeInternalPlayer(hostPlayer: hostPlayer, callback: eventsCallback)
	}
}