//
//  AssetResourceLoader.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 21.03.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import AVFoundation
import RxSwift
import MobileCoreServices

public protocol AssetResourceLoaderProtocol {
	var currentLoadingRequests: [AVAssetResourceLoadingRequestProtocol] { get }
}

extension AssetResourceLoader : AssetResourceLoaderProtocol {
	public var currentLoadingRequests: [AVAssetResourceLoadingRequestProtocol] {
		return Array(resourceLoadingRequests.values)
	}
}

extension Observable {
	public func observeOnIfExists(scheduler: ImmediateSchedulerType?) -> Observable<Observable.E> {
		if let scheduler = scheduler {
			return observeOn(scheduler)
		}
		return self
	}
}

public class AssetResourceLoader {
	private let cacheTask: StreamDataCacheTaskProtocol
	private var response: NSHTTPURLResponseProtocol?
	
	private var scheduler: SerialDispatchQueueScheduler? = nil
	private let bag = DisposeBag()
	private var resourceLoadingRequests = [Int: AVAssetResourceLoadingRequestProtocol]()
	
	public init(cacheTask: StreamDataCacheTaskProtocol, assetLoaderEvents: Observable<AssetLoadingEvents>, observeInNewScheduler: Bool = true) {
		self.cacheTask = cacheTask
		response = cacheTask.response
		
		if observeInNewScheduler {
			scheduler = SerialDispatchQueueScheduler(globalConcurrentQueueQOS: DispatchQueueSchedulerQOS.Utility)
		}
		
		assetLoaderEvents.observeOnIfExists(scheduler).bindNext { [unowned self] result in
			switch result {
			case .DidCancelLoading(let loadingRequest):
				self.resourceLoadingRequests.removeValueForKey(loadingRequest.hash)
			case .ShouldWaitForLoading(let loadingRequest):
				self.resourceLoadingRequests[loadingRequest.hash] = loadingRequest
			}
		}.addDisposableTo(bag)
		
		cacheTask.taskProgress.observeOnIfExists(scheduler).bindNext { [weak self] result in
			if case .Success = result {
				self?.processRequests()
			} else if case .SuccessWithCache = result {
				self?.processRequests()
			} else if case .CacheNewData = result {
				self?.processRequests()
			} else if case .ReceiveResponse(let resp) = result {
				self?.response = resp
			}
		}.addDisposableTo(bag)
	}
	
	deinit {
		print("AssetResourceLoader deinit")
	}
	
	private func processRequests() {
		resourceLoadingRequests.map { key, loadingRequest in
			if let contentInformationRequest = loadingRequest.getContentInformationRequest(), response = response {
				contentInformationRequest.byteRangeAccessSupported = true
				contentInformationRequest.contentLength = response.expectedContentLength
				contentInformationRequest.contentType = cacheTask.mimeType
			}
			
			if let dataRequest = loadingRequest.getDataRequest() {
				if respondWithData(cacheTask.getCachedData(), respondingDataRequest: dataRequest) {
					loadingRequest.finishLoading()
					return key
				}
			}
			return -1
			
			}.filter { $0 != -1 }.forEach { index in resourceLoadingRequests.removeValueForKey(index)
		}
	}
		
	private func respondWithData(data: NSData, respondingDataRequest: AVAssetResourceLoadingDataRequestProtocol) -> Bool {
		let startOffset = respondingDataRequest.currentOffset != 0 ? respondingDataRequest.currentOffset : respondingDataRequest.requestedOffset
		let dataLength = Int64(data.length)

		if dataLength < startOffset {
			return false
		}
		
		let unreadBytesLength = dataLength - startOffset
		let responseLength = min(Int64(respondingDataRequest.requestedLength), unreadBytesLength)
		
		if responseLength == 0 {
			return false
		}
		let range = NSMakeRange(Int(startOffset), Int(responseLength))
		
		respondingDataRequest.respondWithData(data.subdataWithRange(range))
		
		return Int64(respondingDataRequest.requestedLength) <= respondingDataRequest.currentOffset + responseLength - respondingDataRequest.requestedOffset
	}
}