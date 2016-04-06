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

public struct ContentTypeDefinition {
	public let MIME: String
	public let UTI: String
	public let fileExtension: String

	public init(mime: String, uti: String, fileExtension: String) {
		self.MIME = mime
		self.UTI = uti
		self.fileExtension = fileExtension
	}
	
	public static func getUtiFromMime(mimeType: String) -> String? {
		guard let contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mimeType, nil) else { return nil }
		
		return contentType.takeUnretainedValue() as String
	}
	
	public static func getFileExtensionFromUti(utiType: String) -> String? {
		guard let ext = UTTypeCopyPreferredTagWithClass(utiType, kUTTagClassFilenameExtension) else { return nil }
		
		return ext.takeUnretainedValue() as String
	}
	
	public static func getFileExtensionFromMime(mimeType: String) -> String? {
		guard let uti = getUtiFromMime(mimeType) else { return nil }
		return getFileExtensionFromUti(uti)
	}
	
	public static func getTypeDefinitionFromMime(mimeType: String) -> ContentTypeDefinition? {
		guard let uti = getUtiFromMime(mimeType), ext = getFileExtensionFromUti(uti) else { return nil }
		return ContentTypeDefinition(mime: mimeType, uti: uti, fileExtension: ext)
	}
}

public enum ContentType: String {
	case mp3 = "audio/mpeg"
	case aac = "audio/aac"
	public var definition: ContentTypeDefinition {
		switch self {
		case .mp3:
			return ContentTypeDefinition(mime: "audio/mpeg", uti: "public.mp3", fileExtension: "mp3")
		case .aac:
			return ContentTypeDefinition(mime: "audio/aac", uti: "public.aac-audio", fileExtension: "aac")
		}
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
	internal var targetAudioFormat: ContentType?
	private var resourceLoadingRequests = [Int: AVAssetResourceLoadingRequestProtocol]()
	internal var work: Observable<Void>?
	
	private init(taskEvents cacheTask: Observable<StreamTaskEvents>, assetEvents assetLoaderEvents: Observable<AssetLoadingEvents>,
	            targetAudioFormat: ContentType? = nil) {
		self.targetAudioFormat = targetAudioFormat
		
		work = Observable.combineLatest (cacheTask, assetLoaderEvents) { [weak self] e in
			switch e.1 {
			case .DidCancelLoading(let loadingRequest):
				self?.resourceLoadingRequests.removeValueForKey(loadingRequest.hash)
			case .ShouldWaitForLoading(let loadingRequest):
				if !loadingRequest.finished {
					self?.resourceLoadingRequests[loadingRequest.hash] = loadingRequest
				}
				default: break
			}
			
			switch e.0 {
			case .Success(let cacheProvider) where cacheProvider != nil: self?.processRequests(cacheProvider!)
			case .ReceiveResponse(let response): self?.response = response
			case .CacheData(let cacheProvider): self?.processRequests(cacheProvider)
			default: break
			}
		}
	}
	
	///Create new instance of AssetResourceLoader
	/// cacheTask: Observable if events object that perform data loading
	/// assetLoaderEvents: Observable of events that perform AVAssetResourceLoader
	/// targetAudioFormat: Format of data that will be streamed
	/// createSchedulerForObserving: If true - new SerialDispatchQueueScheduler will be created to observe
	/// events from cacheTask and assetLoader, otherwise observation will be performed in the same thread
	internal convenience init(cacheTask: Observable<StreamTaskEvents>, assetLoaderEvents: Observable<AssetLoadingEvents>,
														targetAudioFormat: ContentType? = nil, createSchedulerForObserving: Bool = true) {
		if createSchedulerForObserving {
			let scheduler = SerialDispatchQueueScheduler(globalConcurrentQueueQOS: DispatchQueueSchedulerQOS.Utility)
			self.init(taskEvents: cacheTask.observeOn(scheduler), assetEvents: assetLoaderEvents.observeOn(scheduler),
			          targetAudioFormat: targetAudioFormat)
		} else {
			self.init(taskEvents: cacheTask, assetEvents: assetLoaderEvents,
			          targetAudioFormat: targetAudioFormat)
		}
	}
	
	deinit {
		print("AssetResourceLoader deinit")
	}
	
	internal var contentUti: String? {
		return targetAudioFormat?.definition.UTI ?? {
			guard let response = response else { return nil }
			return ContentTypeDefinition.getUtiFromMime(response.getMimeType())
		}()
	}
	
	private func processRequests(cacheProvider: CacheProvider) {
		resourceLoadingRequests.map { key, loadingRequest in
			if let contentInformationRequest = loadingRequest.getContentInformationRequest(), response = response {
				contentInformationRequest.byteRangeAccessSupported = true
				contentInformationRequest.contentLength = response.expectedContentLength
				//contentInformationRequest.contentType = self.targetAudioFormat?.definition.UTI ?? ContentType.getUtiFromMime(response.getMimeType())
				contentInformationRequest.contentType = contentUti
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