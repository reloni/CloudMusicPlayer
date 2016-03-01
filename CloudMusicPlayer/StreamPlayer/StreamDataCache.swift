//
//  StreamPlayerCacheManager.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 01.03.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import AVFoundation
import RxSwift
import RxCocoa
import MobileCoreServices

public struct StreamDataCache {
	
}

public class StreamDataCacheTask {
	private var bag = DisposeBag()
	private var response: NSHTTPURLResponse?
	private let resourceLoadingRequest: AVAssetResourceLoadingRequest

	init(session: NSURLSession, internalRequest: NSMutableURLRequest, resourceLoadingRequest: AVAssetResourceLoadingRequest) {
		self.resourceLoadingRequest = resourceLoadingRequest
		StreamDataTaskManager.createTask(session, request: internalRequest)?.bindNext { response in
			switch response {
			case .StreamedData(let data):
				if let contentRequest = resourceLoadingRequest.contentInformationRequest {
					self.setResponseContentInformation(contentRequest)
				}
				if let dataRequest = resourceLoadingRequest.dataRequest {
					self.respondWithData(data, respondingDataRequest: dataRequest)
				}
			case .StreamedResponse(let response):
				self.response = response
			default:
				break
			}
		}.addDisposableTo(bag)
	}
	
	private func respondWithData(data: NSData, respondingDataRequest: AVAssetResourceLoadingDataRequest) -> Bool {
		let startOffset = respondingDataRequest.currentOffset != 0 ? respondingDataRequest.currentOffset : respondingDataRequest.requestedOffset
		
		if Int64(data.length) < startOffset {
			return false
		}
		
		let unreadBytesLength = Int64(data.length) - startOffset
		let responseLength = min(Int64(respondingDataRequest.requestedLength), unreadBytesLength)

		if responseLength == 0 {
			return false
		}
		let range = NSMakeRange(Int(startOffset), Int(responseLength))

		respondingDataRequest.respondWithData(data.subdataWithRange(range))
		
		let endOffset = startOffset + respondingDataRequest.requestedLength
		//let didRespondFully = (Int64(data.length) >= endOffset)
		return Int64(data.length) >= endOffset ? true : false
	}
	
	private func setResponseContentInformation(request: AVAssetResourceLoadingContentInformationRequest) {
		guard let MIMEType = response?.MIMEType, contentLength = response?.expectedContentLength else {
			return
		}
		
		request.byteRangeAccessSupported = true
		request.contentLength = contentLength
		if let contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, MIMEType, nil) {
			request.contentType = contentType.takeUnretainedValue() as String
		}
	}
}