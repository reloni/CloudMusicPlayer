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
	case Success(totalCashedData: UInt64)
	case SuccessWithCache(NSURL)
	case CacheNewData
	case ReceiveResponse(NSHTTPURLResponseProtocol)
	case Error(NSError)
}

public protocol StreamDataCacheTaskProtocol : StreamTaskProtocol {
	var streamDataTask: StreamDataTaskProtocol { get }
	var taskProgress: Observable<CacheDataResult> { get }
	func getCachedData() -> NSData
	var response: NSHTTPURLResponseProtocol? { get }
	var mimeType: String? { get }
	var fileExtension: String? { get }
}

public class StreamDataCacheTask {
	public let streamDataTask: StreamDataTaskProtocol
	
	private var bag = DisposeBag()
	public private(set) var response: NSHTTPURLResponseProtocol?
	private var resourceLoadingRequests = [AVAssetResourceLoadingRequestProtocol]()
	private let publishSubject = PublishSubject<CacheDataResult>()
	public let uid: String
	private var cacheData = NSMutableData()
	private let saveCachedData: Bool
	private let targetMimeType: String?
	
	public init(streamDataTask: StreamDataTaskProtocol, saveCachedData: Bool = true, targetMimeType: String? = nil) {
		self.streamDataTask = streamDataTask
		self.uid = NSUUID().UUIDString
		self.saveCachedData = saveCachedData
		self.targetMimeType = targetMimeType
		
		bindToEvents()
	}
	
	private func bindToEvents() {
		// not use [unowned self] here toprevent disposing before completion
		self.streamDataTask.taskProgress.bindNext { response in
			switch response {
			case .StreamedData(let data):
				self.cacheData.appendData(data)
				self.publishSubject.onNext(.CacheNewData)
			case .StreamedResponse(let response):
				self.response = response
				self.publishSubject.onNext(.ReceiveResponse(response))
			case .Error(let error):
				self.publishSubject.onNext(CacheDataResult.Error(error))
				self.publishSubject.onCompleted()
			case .Success:
				if self.saveCachedData, let path = self.saveData() {
					self.publishSubject.onNext(CacheDataResult.SuccessWithCache(path))
				} else {
					self.publishSubject.onNext(CacheDataResult.Success(totalCashedData: UInt64(self.cacheData.length)))
				}
				self.publishSubject.onCompleted()
			default: break
			}
		}.addDisposableTo(self.bag)
	}
	
	private func saveData() -> NSURL? {
		//let path = NSFileManager.streamCacheDirectory.URLByAppendingPathComponent(NSUUID().UUIDString + ".mp3")
		let path = NSFileManager.streamCacheDirectory.URLByAppendingPathComponent("\(NSUUID().UUIDString).\(fileExtension ?? "dat")")
		if cacheData.writeToURL(path, atomically: true) {
			return path
		}
		return nil
	}
	
	deinit {
		print("StreamDataCacheTask deinit")
	}
}

extension StreamDataCacheTask : StreamDataCacheTaskProtocol {
	public var taskProgress: Observable<CacheDataResult>  {
		return publishSubject.shareReplay(1)
	}
	
	public func resume() {
		streamDataTask.resume()
	}
	
	public func suspend() {
		streamDataTask.suspend()
	}
	
	public func cancel() {
		streamDataTask.cancel()
	}
	
	public func getCachedData() -> NSData {
		return cacheData
	}
	
	public var mimeType: String? {
		guard let mime = targetMimeType ?? response?.MIMEType,
			contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mime, nil) else { return nil }
		
		return contentType.takeUnretainedValue() as String
	}
	
	public var fileExtension: String? {
		guard let mime = mimeType, ext = UTTypeCopyPreferredTagWithClass(mime, kUTTagClassFilenameExtension) else { return nil }
		
		return ext.takeUnretainedValue() as String
	}
}