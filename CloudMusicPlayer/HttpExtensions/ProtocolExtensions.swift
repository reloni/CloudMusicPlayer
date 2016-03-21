//
//  ProtocolExtensions.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 17.03.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation
import AVFoundation


// NSHTTPURLResponseProtocol
public protocol NSHTTPURLResponseProtocol {
	var expectedContentLength: Int64 { get }
	var MIMEType: String? { get }
}
extension NSHTTPURLResponse : NSHTTPURLResponseProtocol { }


// NSURLResponse
public protocol NSURLResponseProtocol { }
extension NSURLResponse : NSURLResponseProtocol { }


// NSURLRequestProtocol
public protocol NSURLRequestProtocol { }
extension NSURLRequest : NSURLRequestProtocol { }


// AVAssetResourceLoadingRequestProtocol
public protocol AVAssetResourceLoadingRequestProtocol {
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
extension AVAssetResourceLoadingDataRequest : AVAssetResourceLoadingDataRequestProtocol {
	public func test() {
		
	}
}


// NSMutableURLRequestProtocol
public protocol NSMutableURLRequestProtocol : NSURLRequestProtocol {
	func addValue(value: String, forHTTPHeaderField: String)
	var URL: NSURL? { get }
	var allHTTPHeaderFields: [String: String]? { get }
}
extension NSMutableURLRequest : NSMutableURLRequestProtocol { }


public protocol NSURLSessionTaskProtocol { }
extension NSURLSessionTask : NSURLSessionTaskProtocol { }

// NSURLSessionDataTaskProtocol
public protocol NSURLSessionDataTaskProtocol : NSURLSessionTaskProtocol {
	func resume()
	func suspend()
	func cancel()
	func getOriginalMutableUrlRequest() -> NSMutableURLRequestProtocol?
}
extension NSURLSessionDataTask : NSURLSessionDataTaskProtocol {
	public func getOriginalMutableUrlRequest() -> NSMutableURLRequestProtocol? {
		return originalRequest as? NSMutableURLRequestProtocol
	}
}


// NSURLSessionProtocol
public typealias DataTaskResult = (NSData?, NSURLResponse?, NSError?) -> Void
public protocol NSURLSessionProtocol {
	func invalidateAndCancel()
	func dataTaskWithURL(url: NSURL, completionHandler: DataTaskResult)	-> NSURLSessionDataTaskProtocol
	func dataTaskWithRequest(request: NSMutableURLRequestProtocol, completionHandler: DataTaskResult) -> NSURLSessionDataTaskProtocol
	func dataTaskWithRequest(request: NSMutableURLRequestProtocol) -> NSURLSessionDataTaskProtocol
}
extension NSURLSession : NSURLSessionProtocol {
	public func dataTaskWithURL(url: NSURL, completionHandler: DataTaskResult) -> NSURLSessionDataTaskProtocol {
		return dataTaskWithURL(url, completionHandler: completionHandler) as NSURLSessionDataTask
	}
	
	public func dataTaskWithRequest(request: NSMutableURLRequestProtocol, completionHandler: DataTaskResult) -> NSURLSessionDataTaskProtocol {
		return dataTaskWithRequest(request as! NSMutableURLRequest, completionHandler: completionHandler) as NSURLSessionDataTask
	}
	
	public func dataTaskWithRequest(request: NSMutableURLRequestProtocol) -> NSURLSessionDataTaskProtocol {
		return dataTaskWithRequest(request as! NSURLRequest) as NSURLSessionDataTask
	}
}
extension NSURLSession {
	public static var defaultConfig: NSURLSessionConfiguration {
		return .defaultSessionConfiguration()
	}
}


// NSURL
extension NSURL {
	public convenience init?(baseUrl: String, parameters: [String: String]?) {
		if let parameters = parameters, components = NSURLComponents(string: baseUrl) {
			components.queryItems = [NSURLQueryItem]()
			parameters.forEach { key, value in
				components.queryItems?.append(NSURLQueryItem(name: key, value: value))
				//value.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())))
			}
			self.init(string: components.URLString)
		} else {
			self.init(string: baseUrl)
		}
	}
}