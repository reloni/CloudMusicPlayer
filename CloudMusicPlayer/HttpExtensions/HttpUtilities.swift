//
//  HttpUtilities.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 15.03.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation

public protocol HttpUtilitiesProtocol {
	func createUrlRequest(baseUrl: String, parameters: [String: String]?) -> NSMutableURLRequestProtocol?
}

public class HttpUtilities {
	private static var _instance: HttpUtilitiesProtocol?
	private static var token: dispatch_once_t = 0
	
	public static var instance: HttpUtilitiesProtocol  {
		initWithInstance()
		return HttpUtilities._instance!
	}
	
	internal static func initWithInstance(instance: HttpUtilitiesProtocol? = nil) {
		dispatch_once(&token) {
			_instance = instance ?? HttpUtilities()
		}
	}
}

extension HttpUtilities : HttpUtilitiesProtocol {
	public func createUrlRequest(baseUrl: String, parameters: [String : String]?) -> NSMutableURLRequestProtocol? {
		guard let url = NSURL(baseUrl: baseUrl, parameters: parameters) else {
			return nil
		}
		return NSMutableURLRequest(URL: url)
	}
}