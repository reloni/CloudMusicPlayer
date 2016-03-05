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
	private static var tasks = [String: (StreamDataCacheTask, Observable<CacheDataResult>)]()
	
	public static func createTask(internalRequest: NSMutableURLRequest, resourceLoadingRequest: AVAssetResourceLoadingRequest) -> Observable<CacheDataResult>? {
		if let (task, observable) = tasks[internalRequest.URLString] {
			task.resourceLoadingRequests.append(resourceLoadingRequest)
			return observable
		}
		
		guard let newTask = StreamDataCacheTask(internalRequest: internalRequest, resourceLoadingRequest: resourceLoadingRequest) else {
			return nil
		}
		
		let newObservable = Observable<CacheDataResult>.create { observer in
			newTask.taskProgress.bindNext { progress in
				observer.onNext(progress)
				tasks.removeValueForKey(newTask.uid)
			}.addDisposableTo(newTask.bag)
			
			newTask.resume()
			
			return AnonymousDisposable {
				newTask.cancel()
				tasks.removeValueForKey(newTask.uid)
			}
		}.shareReplay(1)
		
		tasks[newTask.uid] = (newTask, newObservable)
		
		return newObservable
	}
}

public class StreamDataCacheTask {
	private var bag = DisposeBag()
	private var response: NSHTTPURLResponse?
	private var resourceLoadingRequests = [AVAssetResourceLoadingRequest]()
	private let streamTask: Observable<StreamDataResult>
	private let taskProgress = PublishSubject<CacheDataResult>()
	public let uid: String
	private var cacheData = NSMutableData()
	private let saveCachedData: Bool

	private convenience init?(internalRequest: NSMutableURLRequest, resourceLoadingRequest: AVAssetResourceLoadingRequest, saveCachedData: Bool = true) {
		guard let streamTask = StreamDataTaskManager.createTask(internalRequest) else {
			return nil
		}
		self.init(uid: internalRequest.URLString, resourceLoadingRequest: resourceLoadingRequest, streamTask: streamTask, saveCachedData: saveCachedData)
	}
	
	private init(uid: String, resourceLoadingRequest: AVAssetResourceLoadingRequest, streamTask: Observable<StreamDataResult>, saveCachedData: Bool = true) {
		self.streamTask = streamTask
		self.uid = uid
		self.resourceLoadingRequests.append(resourceLoadingRequest)
		self.saveCachedData = saveCachedData
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
				self.processRequests()
				self.taskProgress.onNext(CacheDataResult.Error(error))
				self.taskProgress.onCompleted()
			case .Success:
				self.processRequests()
				if let path = self.saveData() where self.saveCachedData {
					self.taskProgress.onNext(CacheDataResult.SuccessWithCache(path))
				} else {
					self.taskProgress.onNext(CacheDataResult.Success)
				}
				self.taskProgress.onCompleted()
			default: break
			}
		}.addDisposableTo(bag)
	}
	
	public func cancel() {
	}
	
	private func saveData() -> NSURL? {
		let path = NSFileManager.mediaCacheDirectory.URLByAppendingPathComponent(NSUUID().UUIDString + ".mp3")
		if cacheData.writeToURL(path, atomically: true) {
			return path
		}
		return nil
	}
	
	private func processRequests() {
		self.resourceLoadingRequests = self.resourceLoadingRequests.filter { request in
			if let contentInformationRequest = request.contentInformationRequest {
				self.setResponseContentInformation(contentInformationRequest)
			}
			
			if let dataRequest = request.dataRequest {
				if self.respondWithData(self.cacheData, respondingDataRequest: dataRequest) {
					request.finishLoading()
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
	
	private func setResponseContentInformation(request: AVAssetResourceLoadingContentInformationRequest) {
		guard let MIMEType = response?.MIMEType, contentLength = response?.expectedContentLength else {
			return
		}
		
		request.byteRangeAccessSupported = true
		request.contentLength = contentLength
		if let contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, MIMEType, nil) {
			//request.contentType = contentType.takeUnretainedValue() as String
			//print(UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, "audio/mpeg", nil)?.takeUnretainedValue())
			
			request.contentType = "public.mp3"
		}
	}
}
