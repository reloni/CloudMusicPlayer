//
//  Extensions.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 17.03.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import AVFoundation
import RxSwift

// AVAssetResourceLoadingRequestProtocol
public protocol AVAssetResourceLoadingRequestProtocol : NSObjectProtocol {
	func getContentInformationRequest() -> AVAssetResourceLoadingContentInformationRequestProtocol?
	func getDataRequest() -> AVAssetResourceLoadingDataRequestProtocol?
	func finishLoading()
	var finished: Bool { get }
}
extension AVAssetResourceLoadingRequest : AVAssetResourceLoadingRequestProtocol {
	public func getContentInformationRequest() -> AVAssetResourceLoadingContentInformationRequestProtocol? {
		return contentInformationRequest
	}
	
	public func getDataRequest() -> AVAssetResourceLoadingDataRequestProtocol? {
		return dataRequest
	}
}


// AVAssetResourceLoadingContentInformationRequestProtocol
public protocol AVAssetResourceLoadingContentInformationRequestProtocol : class {
	var byteRangeAccessSupported: Bool { get set }
	var contentLength: Int64 { get set }
	var contentType: String? { get set }
}
extension AVAssetResourceLoadingContentInformationRequest : AVAssetResourceLoadingContentInformationRequestProtocol { }


// AVAssetResourceLoadingDataRequestProtocol
public protocol AVAssetResourceLoadingDataRequestProtocol {
	var currentOffset: Int64 { get }
	var requestedOffset: Int64 { get }
	var requestedLength: Int { get }
	func respondWithData(data: NSData)
}
extension AVAssetResourceLoadingDataRequest : AVAssetResourceLoadingDataRequestProtocol { }


// AVAsset
public protocol AVAssetProtocol {
	var duration: CMTime { get }
	func getMetadata() -> [String: AnyObject?]
	func loadValuesAsynchronouslyForKeys(keys: [String], completionHandler: (() -> Void)?)
}
extension AVAsset: AVAssetProtocol {
	public func getMetadata() -> [String: AnyObject?] {
		// http://stackoverflow.com/questions/10292913/avmetadataitem-getting-the-tracknumber-from-an-itunes-or-id3-metadata-on-ios
		//return Dictionary<String, AnyObject?>(metadata.filter { $0.commonKey != nil }.map { ($0.commonKey!, $0.value as? AnyObject)})
		let a = metadataForFormat(AVMetadataKeySpaceID3).map { item -> (String, AnyObject?)? in
			if let key = item.commonKey {
				return (key, item.value as? AnyObject)
			} else if let key = item.key as? String {
				return (key, item.value)
			}
			return nil
			}.filter { $0 != nil }.map { $0! }
		
		return Dictionary<String, AnyObject?>(a)
	}
}


// AVURLAsset
public protocol AVURLAssetProtocol: AVAssetProtocol {
	var URL: NSURL { get }
	func getResourceLoader() -> AVAssetResourceLoaderProtocol
}
extension AVURLAsset: AVURLAssetProtocol {
	public func getResourceLoader() -> AVAssetResourceLoaderProtocol {
		return resourceLoader
	}
}


// AVAssetResourceLoader
public protocol AVAssetResourceLoaderProtocol {
	func setDelegate(delegate: AVAssetResourceLoaderDelegate?, queue: dispatch_queue_t?)
}
extension AVAssetResourceLoader: AVAssetResourceLoaderProtocol { }


// AVPlayer
public protocol AVPlayerProtocol {
	var internalItemStatus: Observable<AVPlayerItemStatus?> { get }
	var rate: Float { get set }
	func replaceCurrentItemWithPlayerItem(item: AVPlayerItemProtocol?)
	func play()
	func setPlayerRate(rate: Float)
}
extension AVPlayer : AVPlayerProtocol {
	public var internalItemStatus: Observable<AVPlayerItemStatus?> {
		return self.rx_observe(AVPlayerItemStatus.self, "status").shareReplay(1)
	}
	public func replaceCurrentItemWithPlayerItem(item: AVPlayerItemProtocol?) {
		replaceCurrentItemWithPlayerItem(item as? AVPlayerItem)
	}
	public func setPlayerRate(rate: Float) {
		self.rate = rate
	}
}


// AVPlayerItem
public protocol AVPlayerItemProtocol {
	func getAsset() -> AVAssetProtocol
	var duration: CMTime { get }
	func currentTime() -> CMTime
}
extension AVPlayerItem: AVPlayerItemProtocol {
	public func getAsset() -> AVAssetProtocol {
		return asset
	}
}