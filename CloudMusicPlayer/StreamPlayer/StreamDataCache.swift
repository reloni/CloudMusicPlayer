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

public enum CacheDataResult {
	case Success
	case SuccessWithCache(NSURL)
	case Error(NSError)
}

public struct StreamDataCacheManager {
	private static var tasks = [String: StreamDataCacheTask]()
	
	public static func createTask(internalRequest: NSMutableURLRequest, resourceLoadingRequest: AVAssetResourceLoadingRequest) -> Observable<CacheDataResult>? {
		if let runningTask = tasks[internalRequest.URLString] {
			runningTask.resourceLoadingRequests.append(resourceLoadingRequest)
			return runningTask.taskResult
		}
		
		guard let task = StreamDataCacheTask(internalRequest: internalRequest, resourceLoadingRequest: resourceLoadingRequest) else {
			return nil
		}
		tasks[task.uid] = task
		task.taskResult.bindNext { next in
			switch next {
			case .Success:
				tasks.removeValueForKey(task.uid)
				print("tasks \(tasks.count)")
			case .SuccessWithCache(let url):
				tasks.removeValueForKey(task.uid)
			default: break
			}
		}.addDisposableTo(task.bag)
		task.resume()
		return task.taskResult
	}
}

public class StreamDataCacheTask {
	private var bag = DisposeBag()
	private var response: NSHTTPURLResponse?
	private var resourceLoadingRequests = [AVAssetResourceLoadingRequest]()
	private let streamTask: Observable<StreamDataResult>
	private let taskResult = PublishSubject<CacheDataResult>()
	public let uid: String
	private var cacheData = NSMutableData()

	private convenience init?(internalRequest: NSMutableURLRequest, resourceLoadingRequest: AVAssetResourceLoadingRequest) {
		guard let streamTask = StreamDataTaskManager.createTask(internalRequest) else {
			return nil
		}
		self.init(uid: internalRequest.URLString, resourceLoadingRequest: resourceLoadingRequest, streamTask: streamTask)
	}
	
	private init(uid: String, resourceLoadingRequest: AVAssetResourceLoadingRequest, streamTask: Observable<StreamDataResult>) {
		self.streamTask = streamTask
		self.uid = uid
		//self.resourceLoadingRequest = resourceLoadingRequest
		self.resourceLoadingRequests.append(resourceLoadingRequest)
	}
	
	public func resume() {
		streamTask.bindNext { [unowned self] response in
			switch response {
			case .StreamedData(let data):
				self.cacheData.appendData(data)
				self.processRequests()
			case .StreamedResponse(let response):
				self.response = response
			case .Error(let error):
				self.taskResult.onNext(CacheDataResult.Error(error))
				self.taskResult.onCompleted()
			case .Success:
				self.processRequests()
				self.taskResult.onNext(CacheDataResult.Success)
				self.taskResult.onCompleted()
			}
		}.addDisposableTo(bag)
	}
	
	private func processRequests() {
		self.self.resourceLoadingRequests = self.self.resourceLoadingRequests.filter { request in
			if let contentInformationRequest = request.contentInformationRequest {
				self.setResponseContentInformation(contentInformationRequest)
			}
			
			if let dataRequest = request.dataRequest {
				//print("Current offset: \(dataRequest.currentOffset) Requested length: \(dataRequest.requestedLength) Requested offset: \(dataRequest.requestedOffset)")
				if self.respondWithData(self.cacheData, respondingDataRequest: dataRequest) {
					request.finishLoading()
					print("Received data \(self.cacheData.length)")
					return false
				}
			}
			return true
		}
	}
	
	deinit {
		print("StreamDataCacheTask deinit")
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