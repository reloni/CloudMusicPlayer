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
	var request: NSMutableURLRequestProtocol { get }
	var dataTask: StreamDataTaskProtocol { get }
	var response: NSHTTPURLResponseProtocol? { get }
}

public class AssetResourceLoader : NSObject {
	public let request: NSMutableURLRequestProtocol
	public let cacheTask: StreamDataCacheTaskProtocol
	public var response: NSHTTPURLResponseProtocol?
	
	private let bag = DisposeBag()
	private var resourceLoadingRequests = [AVAssetResourceLoadingRequestProtocol]()
	
	public init(request: NSMutableURLRequestProtocol, cacheTask: StreamDataCacheTaskProtocol) {
		self.request = request
		self.cacheTask = cacheTask
	}
	
	private func processRequests() {
		self.resourceLoadingRequests = resourceLoadingRequests.filter { request in
			if let contentInformationRequest = request.getContentInformationRequest(), response = response {
				setResponseContentInformation(response, request: contentInformationRequest)
			}
			
			if let dataRequest = request.getDataRequest() {
				if respondWithData(cacheTask.getCachedData(), respondingDataRequest: dataRequest) {
					request.finishLoading()
					return false
				}
			}
			return true
		}
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
		
		respondingDataRequest.respondWithData(data.subdataWithRange(range))
		
		let endOffset = startOffset + respondingDataRequest.requestedLength
		return dataLength >= endOffset
	}
}

extension AssetResourceLoader : AVAssetResourceLoaderDelegate {
	public func resourceLoader(resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
		cacheTask.taskProgress.bindNext { result in
			
			}.addDisposableTo(bag)
		
		return true
	}
	
	public func resourceLoader(resourceLoader: AVAssetResourceLoader, didCancelLoadingRequest loadingRequest: AVAssetResourceLoadingRequest) {

	}
}