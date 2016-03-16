//
//  NSURLSessionDataTask.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 14.03.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation

public protocol NSURLSessionDataTaskProtocol {
	func resume()
	func suspend()
	func getOriginalMutableUrlRequest() -> NSMutableURLRequestProtocol?
}

extension NSURLSessionDataTask : NSURLSessionDataTaskProtocol {
	public func getOriginalMutableUrlRequest() -> NSMutableURLRequestProtocol? {
		return originalRequest as? NSMutableURLRequestProtocol
	}
}