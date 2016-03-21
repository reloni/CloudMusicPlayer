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

public protocol ResourceLoadingRequest {
	func respondWithData(data: NSData)
}

public enum CacheDataResult {
	case Success
	case SuccessWithCache(NSURL)
	case Error(NSError)
}

public struct StreamDataCacheManager {
	private static var tasks = [String: (StreamDataCacheTask, Observable<CacheDataResult>)]()
	
	public static func createTask(internalRequest: NSMutableURLRequest, resourceLoadingRequest:
		AVAssetResourceLoadingRequest, saveCachedData: Bool = true) -> Observable<CacheDataResult>? {
		
		if let (task, observable) = tasks[internalRequest.URLString] {
			task.resourceLoadingRequests.append(resourceLoadingRequest)
			return observable
		}
			
		let streamTask = HttpUtilities.instance.createStreamDataTask(internalRequest, sessionConfiguration: NSURLSession.defaultConfig)
		
		let newTask = StreamDataCacheTask(resourceLoadingRequest: resourceLoadingRequest, streamDataTask: streamTask, saveCachedData: saveCachedData)
		
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

public protocol StreamDataCacheTaskProtocol : StreamTaskProtocol {
	var streamDataTask: StreamDataTaskProtocol { get }
	var taskProgress: Observable<CacheDataResult> { get }
}

public class StreamDataCacheTask {
	public let streamDataTask: StreamDataTaskProtocol
	
	private var bag = DisposeBag()
	private var response: NSHTTPURLResponseProtocol?
	private var resourceLoadingRequests = [AVAssetResourceLoadingRequestProtocol]()
	//private let streamTask: Observable<StreamDataResult>
	private let publishSubject = PublishSubject<CacheDataResult>()
	public let uid: String
	private var cacheData = NSMutableData()
	private let saveCachedData: Bool
	
	public lazy var taskProgress: Observable<CacheDataResult> = { [unowned self] in
		self.streamDataTask.taskProgress.bindNext { [unowned self] response in
			switch response {
			case .StreamedData(let data):
				self.cacheData.appendData(data)
				self.processRequests()
			case .StreamedResponse(let response):
				self.response = response
			case .Error(let error):
				self.processRequests()
				self.publishSubject.onNext(CacheDataResult.Error(error))
				self.publishSubject.onCompleted()
			case .Success:
				self.processRequests()
				if self.saveCachedData, let path = self.saveData() {
					self.publishSubject.onNext(CacheDataResult.SuccessWithCache(path))
				} else {
					self.publishSubject.onNext(CacheDataResult.Success)
				}
				self.publishSubject.onCompleted()
			default: break
			}
		}.addDisposableTo(self.bag)
	
		return self.publishSubject
	}()

//	private convenience init?(internalRequest: NSMutableURLRequest, resourceLoadingRequest: AVAssetResourceLoadingRequest, saveCachedData: Bool = true) {
//		guard let streamTask = StreamDataTaskManager.createTask(internalRequest) else {
//			return nil
//		}
//		self.init(uid: internalRequest.URLString, resourceLoadingRequest: resourceLoadingRequest, streamTask: streamTask, saveCachedData: saveCachedData)
//	}
	
	public init(resourceLoadingRequest: AVAssetResourceLoadingRequestProtocol, streamDataTask: StreamDataTaskProtocol, saveCachedData: Bool = true) {
		self.streamDataTask = streamDataTask
		self.uid = NSUUID().UUIDString
		self.resourceLoadingRequests.append(resourceLoadingRequest)
		self.saveCachedData = saveCachedData
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
			if let contentInformationRequest = request.getContentInformationRequest() {
				self.setResponseContentInformation(contentInformationRequest)
			}
			
			if let dataRequest = request.getDataRequest() {
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
	
	private func respondWithData(data: NSData, respondingDataRequest: AVAssetResourceLoadingDataRequestProtocol) -> Bool {
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
	
	private func setResponseContentInformation(request: AVAssetResourceLoadingContentInformationRequestProtocol) {
		guard let MIMEType = response?.MIMEType, contentLength = response?.expectedContentLength else {
			return
		}
		
		request.byteRangeAccessSupported = true
		request.contentLength = contentLength
		if let contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, MIMEType, nil) {
			request.contentType = contentType.takeUnretainedValue() as String
			//print(UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, "audio/mpeg", nil)?.takeUnretainedValue())
			
			request.contentType = "public.mp3"
		}
	}
}

extension StreamDataCacheTask : StreamDataCacheTaskProtocol {
	public func resume() {
		streamDataTask.resume()
	}
	
	public func suspend() {
		streamDataTask.suspend()
	}
	
	public func cancel() {
		streamDataTask.cancel()
	}
}
