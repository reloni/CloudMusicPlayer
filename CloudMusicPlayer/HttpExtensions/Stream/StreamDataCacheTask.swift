////
////  StreamPlayerCacheManager.swift
////  CloudMusicPlayer
////
////  Created by Anton Efimenko on 01.03.16.
////  Copyright © 2016 Anton Efimenko. All rights reserved.
////
//
//import Foundation
//import AVFoundation
//import RxSwift
//import RxCocoa
//import MobileCoreServices
//
//public protocol ResourceLoadingRequest {
//	func respondWithData(data: NSData)
//}
//
//public enum CacheDataResult {
//	case Success(task: StreamDataCacheTask, totalCashedData: UInt64)
//	case SuccessWithCache(task: StreamDataCacheTask, url: NSURL)
//	case CacheNewData(task: StreamDataCacheTask)
//	case ReceiveResponse(task: StreamDataCacheTask, response: NSHTTPURLResponseProtocol)
//	case Error(task: StreamDataCacheTask, error: NSError)
//}
//
//public protocol StreamDataCacheTaskProtocol : StreamTaskProtocol {
//	var streamDataTask: StreamDataTaskProtocol { get }
//	var taskProgress: Observable<CacheDataResult> { get }
//	var cacheProvider: CacheProvider { get }
//	var response: NSHTTPURLResponseProtocol? { get }
//	var mimeType: String? { get }
//	var fileExtension: String? { get }
//}
//
//public class StreamDataCacheTask {
//	public let streamDataTask: StreamDataTaskProtocol
//	
//	private var bag = DisposeBag()
//	public private(set) var response: NSHTTPURLResponseProtocol?
//	private var resourceLoadingRequests = [AVAssetResourceLoadingRequestProtocol]()
//	private let publishSubject = PublishSubject<CacheDataResult>()
//	public let uid: String
//	private let saveCachedData: Bool
//	private let targetMimeType: String?
//	public let cacheProvider: CacheProvider
//	
//	public init(streamDataTask: StreamDataTaskProtocol, saveCachedData: Bool = true, cacheProvider: CacheProvider = MemoryCacheProvider(),
//	            targetMimeType: String? = nil) {
//		self.streamDataTask = streamDataTask
//		self.uid = NSUUID().UUIDString
//		self.saveCachedData = saveCachedData
//		self.targetMimeType = targetMimeType
//		self.cacheProvider = cacheProvider
//		
//		bindToEvents()
//	}
//	
//	private func bindToEvents() {
//		// not use [unowned self] here toprevent disposing before completion
//		self.streamDataTask.taskProgress.bindNext { response in
//			switch response {
//			case .StreamedData(let data):
//				self.cacheProvider.appendData(data)
//				self.publishSubject.onNext(.CacheNewData(task: self))
//			case .StreamedResponse(let response):
//				self.response = response
//				self.publishSubject.onNext(.ReceiveResponse(task: self, response: response))
//			case .Error(let error):
//				self.publishSubject.onNext(CacheDataResult.Error(task: self, error: error))
//				self.publishSubject.onCompleted()
//			case .Success:
//				if self.saveCachedData, let path = self.cacheProvider.saveData(self.fileExtension ?? "dat") {
//					self.publishSubject.onNext(CacheDataResult.SuccessWithCache(task: self, url: path))
//				} else {
//					self.publishSubject.onNext(CacheDataResult.Success(task: self, totalCashedData: self.cacheProvider.currentDataLength))
//				}
//				self.publishSubject.onCompleted()
//			default: break
//			}
//		}.addDisposableTo(self.bag)
//	}
//	
//	deinit {
//		print("StreamDataCacheTask deinit")
//	}
//}
//
//extension StreamDataCacheTask : StreamDataCacheTaskProtocol {
//	public var taskProgress: Observable<CacheDataResult>  {
//		return publishSubject.shareReplay(1)
//	}
//	
//	public func resume() {
//		streamDataTask.resume()
//	}
//	
//	public func suspend() {
//		streamDataTask.suspend()
//	}
//	
//	public func cancel() {
//		streamDataTask.cancel()
//	}
//	
//	public var mimeType: String? {
//		guard let mime = targetMimeType ?? response?.MIMEType,
//			contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mime, nil) else { return nil }
//		
//		return contentType.takeUnretainedValue() as String
//	}
//	
//	public var fileExtension: String? {
//		guard let mime = mimeType, ext = UTTypeCopyPreferredTagWithClass(mime, kUTTagClassFilenameExtension) else { return nil }
//		
//		return ext.takeUnretainedValue() as String
//	}
//}
