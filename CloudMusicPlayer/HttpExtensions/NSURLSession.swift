//
//  NSURLSession.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 14.03.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation

public typealias DataTaskResult = (NSData?, NSURLResponse?, NSError?) -> Void

public protocol NSURLSessionProtocol {
	func dataTaskWithURL(url: NSURL, completionHandler: DataTaskResult)	-> NSURLSessionDataTaskProtocol
	func dataTaskWithRequest(request: NSMutableURLRequestProtocol, completionHandler: DataTaskResult) -> NSURLSessionDataTaskProtocol
}

extension NSURLSession : NSURLSessionProtocol {
	public func dataTaskWithURL(url: NSURL, completionHandler: DataTaskResult) -> NSURLSessionDataTaskProtocol {
		return dataTaskWithURL(url, completionHandler: completionHandler) as NSURLSessionDataTask
	}
	
	public func dataTaskWithRequest(request: NSMutableURLRequestProtocol, completionHandler: DataTaskResult) -> NSURLSessionDataTaskProtocol {
		return dataTaskWithRequest(request as! NSMutableURLRequest, completionHandler: completionHandler) as NSURLSessionDataTask
	}
}