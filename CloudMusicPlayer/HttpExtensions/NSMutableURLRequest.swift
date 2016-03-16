//
//  NSURLRequest.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 14.03.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation

public protocol NSMutableURLRequestProtocol {
	func addValue(value: String, forHTTPHeaderField: String)
	var URL: NSURL? { get }
}

extension NSMutableURLRequest : NSMutableURLRequestProtocol { }