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
	public let publishSubject = PublishSubject<PlayerEvents>()
	public let metadataSubject = BehaviorSubject<AudioItemMetadata?>(value: nil)
	public let durationSubject = BehaviorSubject<CMTime?>(value: nil)
	
	public var nativePlayer: AVPlayerProtocol?
	
	public var events: Observable<PlayerEvents> { return publishSubject }
	public var metadata: Observable<AudioItemMetadata?> { return metadataSubject.shareReplay(1) }
	public var duration: Observable<CMTime?> { return durationSubject.shareReplay(1) }
	
	public func resume() {
		publishSubject.onNext(.Resumed)
	}
	
	public func pause() {
		publishSubject.onNext(.Paused)
	}
	
	public func play(playerItem: AVPlayerItemProtocol, asset: AVURLAssetProtocol, observer: AVAssetResourceLoaderEventsObserverProtocol,
	                 loadMetadata: Bool) {
		publishSubject.onNext(.Started)
	}
	
	public func stop() {
		publishSubject.onNext(.Stopped)
	}
	
	deinit {
		publishSubject.onCompleted()
	}
}