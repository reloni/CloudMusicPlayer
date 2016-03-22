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
	//var request: NSMutableURLRequestProtocol { get }
	var dataTask: StreamDataTaskProtocol { get }
	var response: NSHTTPURLResponseProtocol? { get }
}

public class AssetResourceLoader {
	//public let request: NSMutableURLRequestProtocol
	public let cacheTask: StreamDataCacheTaskProtocol
	public var response: NSHTTPURLResponseProtocol?
	
	private let bag = DisposeBag()
	private var resourceLoadingRequests = [Int: AVAssetResourceLoadingRequestProtocol]()
	
	public init(cacheTask: StreamDataCacheTaskProtocol, assetLoaderEvents: Observable<AssetLoadingEvents>) {
		//self.request = request
		self.cacheTask = cacheTask
		response = cacheTask.response
		
		assetLoaderEvents.bindNext { [unowned self] result in
			switch result {
			case .DidCancelLoading(let loadingRequest):
				self.resourceLoadingRequests.removeValueForKey(loadingRequest.hash)
			case .ShouldWaitForLoading(let loadingRequest):
				self.resourceLoadingRequests[loadingRequest.hash] = loadingRequest
			}
		}.addDisposableTo(bag)
		
		cacheTask.taskProgress.bindNext { [unowned self] result in
			if case .Success = result {
				self.processRequests()
			} else if case .SuccessWithCache = result {
				self.processRequests()
			} else if case .CacheNewData = result {
				self.processRequests()
			} else if case .ReceiveResponse(let resp) = result {
				self.response = resp
			}
		}.addDisposableTo(bag)
	}
	
	deinit {
		print("AssetResourceLoader deinit")
	}
	
	private func processRequests() {
		//print("requests count: \(resourceLoadingRequests.count)")
		resourceLoadingRequests.map { key, loadingRequest in
			//print("Process key: \(key)")
			if let contentInformationRequest = loadingRequest.getContentInformationRequest(), response = response {
				setResponseContentInformation(response, request: contentInformationRequest)
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
		//print("requests count: \(resourceLoadingRequests.count)")
	}
	
	private func setResponseContentInformation(response: NSHTTPURLResponseProtocol, request: AVAssetResourceLoadingContentInformationRequestProtocol) {
		guard let MIMEType = response.MIMEType else {
			return
		}
		
		request.byteRangeAccessSupported = true
		request.contentLength = response.expectedContentLength
		if let contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, MIMEType, nil) {
			request.contentType = contentType.takeUnretainedValue() as String
			//print(UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, "audio/mpeg", nil)?.takeUnretainedValue())
			
			request.contentType = "public.mp3"
		}
	}
	
	internal func respondWithData(data: NSData, respondingDataRequest: AVAssetResourceLoadingDataRequestProtocol) -> Bool {
		//print("CurOffset: \(respondingDataRequest.currentOffset) ReqOffset \(respondingDataRequest.requestedOffset) ReqLen: \(respondingDataRequest.requestedLength)")
		
		let startOffset = respondingDataRequest.currentOffset != 0 ? respondingDataRequest.currentOffset : respondingDataRequest.requestedOffset
		let dataLength = Int64(data.length)
		
		if startOffset >= dataLength {
			return true
		} else if dataLength < startOffset {
			return false
		}
		
		let unreadBytesLength = dataLength - startOffset
		let responseLength = min(Int64(respondingDataRequest.requestedLength), unreadBytesLength)
		
		if responseLength == 0 {
			return false
		}
		let range = NSMakeRange(Int(startOffset), Int(responseLength))
		//print("respond with range: \(range)")
		
		respondingDataRequest.respondWithData(data.subdataWithRange(range))
		
		let endOffset = startOffset + respondingDataRequest.requestedLength
		return dataLength >= endOffset
	}
}