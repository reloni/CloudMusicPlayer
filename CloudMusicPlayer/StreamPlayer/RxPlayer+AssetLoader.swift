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

extension Observable where Element : StreamTaskEventsProtocol {
	internal func loadWithAsset(assetEvents assetLoaderEvents: Observable<AssetLoadingEvents>,
	                                        targetAudioFormat: ContentType? = nil)
		-> Observable<(receivedResponse: NSHTTPURLResponseProtocol?, utiType: String?, resultRequestCollection: [Int: AVAssetResourceLoadingRequestProtocol])> {
			
			// local variables
			var resourceLoadingRequests = [Int: AVAssetResourceLoadingRequestProtocol]()
			var response: NSHTTPURLResponseProtocol?
			
			
			// functions
			// get uti type of request or from targetAudioFormat
			func getUtiType() -> String? {
				return targetAudioFormat?.definition.UTI ?? {
					guard let response = response else { return nil }
					return ContentTypeDefinition.getUtiFromMime(response.getMimeType())
					}()
			}
			
			
			// processing requests
			func processRequests(cacheProvider: CacheProvider) {
				resourceLoadingRequests.map { key, loadingRequest in
					if let contentInformationRequest = loadingRequest.getContentInformationRequest(), response = response {
						contentInformationRequest.byteRangeAccessSupported = true
						contentInformationRequest.contentLength = response.expectedContentLength
						contentInformationRequest.contentType = getUtiType()
					}
					
					if let dataRequest = loadingRequest.getDataRequest() {
						if respondWithData(cacheProvider.getData(), respondingDataRequest: dataRequest) {
							loadingRequest.finishLoading()
							return key
						}
					}
					return -1
					
					}.filter { $0 != -1 }.forEach { index in resourceLoadingRequests.removeValueForKey(index)
				}
			}
			
			
			// responding to request with data
			func respondWithData(data: NSData, respondingDataRequest: AVAssetResourceLoadingDataRequestProtocol) -> Bool {
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
			
			return Observable<Void>.create { observer in
				let assetEvents = assetLoaderEvents.bindNext { e in
					switch e {
					case .DidCancelLoading(let loadingRequest):
						resourceLoadingRequests.removeValueForKey(loadingRequest.hash)
					case .ShouldWaitForLoading(let loadingRequest):
						if !loadingRequest.finished {
							resourceLoadingRequests[loadingRequest.hash] = loadingRequest
						}
					}
				}
				
				let streamEvents = self.bindNext { e in
					switch e as! StreamTaskEvents {
					case .Success(let cacheProvider):
						if let cacheProvider = cacheProvider { processRequests(cacheProvider) }
						observer.onNext(); observer.onCompleted()
					case .ReceiveResponse(let receivedResponse): response = receivedResponse
					case .CacheData(let cacheProvider): processRequests(cacheProvider)
					case .Error: observer.onNext(); observer.onCompleted()
					default: break
					}
				}
				
				return AnonymousDisposable {
					assetEvents.dispose()
					streamEvents.dispose()
				}
				
				}.flatMapLatest { _ -> Observable<(receivedResponse: NSHTTPURLResponseProtocol?, utiType: String?, resultRequestCollection: [Int: AVAssetResourceLoadingRequestProtocol])> in
					print("return final data")
					return Observable<(receivedResponse: NSHTTPURLResponseProtocol?, utiType: String?, resultRequestCollection: [Int: AVAssetResourceLoadingRequestProtocol])>
						.just((receivedResponse: response, utiType: getUtiType(), resultRequestCollection: resourceLoadingRequests))
				}.shareReplay(1)
	}
}