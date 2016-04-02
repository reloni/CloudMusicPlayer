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

public struct DataTypeDefinition {
	public let MIME: String
	public let UTI: String
	public let fileExtension: String
	public init(mime: String, uti: String, fileExtension: String) {
		self.MIME = mime
		self.UTI = uti
		self.fileExtension = fileExtension
	}
}

public enum AudioFormat: String {
	case mp3 = "mp3"
	case aac = "aac"
	public var definition: DataTypeDefinition {
		switch self {
		case .mp3:
			return DataTypeDefinition(mime: "audio/mpeg", uti: "public.mp3", fileExtension: "mp3")
		case .aac:
			return DataTypeDefinition(mime: "audio/aac", uti: "public.aac-audio", fileExtension: "aac")
		//default:
		//	return DataTypeDefinition(mime: "octet/stream", uti: "data", fileExtension: "dat")
		}
	}
	
	public static func getUtiFromMime(mimeType: String) -> String? {
		guard let contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mimeType, nil) else { return nil }
		
		return contentType.takeUnretainedValue() as String
	}
	
	public static func getFileExtensionFromUti(utiType: String) -> String? {
		guard let ext = UTTypeCopyPreferredTagWithClass(utiType, kUTTagClassFilenameExtension) else { return nil }
		
		return ext.takeUnretainedValue() as String
	}
}

public protocol AssetResourceLoaderProtocol {
	var currentLoadingRequests: [AVAssetResourceLoadingRequestProtocol] { get }
}

extension AssetResourceLoader : AssetResourceLoaderProtocol {
	public var currentLoadingRequests: [AVAssetResourceLoadingRequestProtocol] {
		return Array(resourceLoadingRequests.values)
	}
}

public class AssetResourceLoader {
	internal var response: NSHTTPURLResponseProtocol?
	internal var targetAudioFormat: AudioFormat?
	
	private var scheduler = SerialDispatchQueueScheduler(globalConcurrentQueueQOS: DispatchQueueSchedulerQOS.Utility)
	private let bag = DisposeBag()
	private var resourceLoadingRequests = [Int: AVAssetResourceLoadingRequestProtocol]()
	
	public init(cacheTask: Observable<StreamTaskEvents>, assetLoaderEvents: Observable<AssetLoadingEvents>,
	            targetAudioFormat: AudioFormat? = nil) {
		self.targetAudioFormat = targetAudioFormat
		
		assetLoaderEvents.observeOn(scheduler).bindNext { [weak self]result in
			switch result {
			case .DidCancelLoading(let loadingRequest):
				self?.resourceLoadingRequests.removeValueForKey(loadingRequest.hash)
			case .ShouldWaitForLoading(let loadingRequest):
				self?.resourceLoadingRequests[loadingRequest.hash] = loadingRequest
			default: break
			}
		}.addDisposableTo(bag)
		
		cacheTask.observeOn(scheduler).bindNext { [weak self] result in
			switch result {
			case .Success(let cacheProvider) where cacheProvider != nil: self?.processRequests(cacheProvider!)
			case .ReceiveResponse(let response): self?.response = response
			case .CacheData(let cacheProvider): self?.processRequests(cacheProvider)
			//case .ReceiveData(let cacheProvider) where cacheProvider != nil:
			default: break
			}
//			if case .Success(let cacheProvider) = result {
//				//self?.response = successResult.task.response
//				guard let cacheProvider = cacheProvider else { return }
//				self?.processRequests(cacheProvider)
//			} else if case .SuccessWithCache(let successResult) = result {
//				self?.response = successResult.task.response
//				self?.processRequests(successResult.task)
//			} else if case .CacheNewData(let task) = result {
//				self?.response = task.response
//				self?.processRequests(task)
//			} else if case .ReceiveResponse(_, let resp) = result {
//				self?.response = resp
//			}
		}.addDisposableTo(bag)
	}
	
	deinit {
		print("AssetResourceLoader deinit")
	}
	
	private func processRequests(cacheProvider: CacheProvider) {
		resourceLoadingRequests.map { key, loadingRequest in
			if let contentInformationRequest = loadingRequest.getContentInformationRequest(), response = response {
				contentInformationRequest.byteRangeAccessSupported = true
				contentInformationRequest.contentLength = response.expectedContentLength
				contentInformationRequest.contentType = self.targetAudioFormat?.definition.UTI ?? AudioFormat.getUtiFromMime(response.getMimeType())
			}
			
			if let dataRequest = loadingRequest.getDataRequest() {
				//if respondWithData(cacheTask.getCachedData(), respondingDataRequest: dataRequest) {
				if respondWithData(cacheProvider.getData(), respondingDataRequest: dataRequest) {
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