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

//public class FakeCacheItem : CacheItem {
//	public var cacheDispatcher: PlayerCacheDispatcherProtocol
//	public var resourceIdentifier: StreamResourceIdentifier
//	public var task: StreamDataTaskProtocol?
//	public var targetContentType: ContentType?
////	public func getCacheTask() -> Observable<CacheDataResult> {
////		return task!.taskProgress
////	}
//	public func getLoadTask() -> Observable<StreamTaskEvents> {
//		return task?.taskProgress ?? Observable<StreamTaskEvents>.empty()
//	}
//	public init(resourceIdeitifier: StreamResourceIdentifier, task: StreamDataTaskProtocol?, cacheDispatcher: PlayerCacheDispatcherProtocol = PlayerCacheDispatcher()) {
//		self.resourceIdentifier = resourceIdeitifier
//		self.task = task
//		self.cacheDispatcher = cacheDispatcher
//	}
//}