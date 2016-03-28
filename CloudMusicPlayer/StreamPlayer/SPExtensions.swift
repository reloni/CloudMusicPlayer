//
//  Extensions.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 17.03.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import AVFoundation

// AVAssetResourceLoadingRequestProtocol
public protocol AVAssetResourceLoadingRequestProtocol : NSObjectProtocol {
	func getContentInformationRequest() -> AVAssetResourceLoadingContentInformationRequestProtocol?
	func getDataRequest() -> AVAssetResourceLoadingDataRequestProtocol?
	func finishLoading()
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

extension AVAsset {
	public func getMetadata() -> [String: AnyObject?] {
		return Dictionary<String, AnyObject?>(metadata.filter { $0.commonKey != nil }.map { ($0.commonKey!, $0.value as? AnyObject)})
	}
}