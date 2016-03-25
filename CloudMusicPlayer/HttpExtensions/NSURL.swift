//
//  NSURL.swift
//  CloudMusicPlayer
//
//  Created by Anton Efimenko on 14.03.16.
//  Copyright © 2016 Anton Efimenko. All rights reserved.
//

import Foundation

extension NSURL {
	public convenience init?(baseUrl: String, parameters: [String: String]?) {
		if let parameters = parameters, components = NSURLComponents(string: baseUrl) {
			components.queryItems = [NSURLQueryItem]()
			parameters.forEach { key, value in
				components.queryItems?.append(NSURLQueryItem(name: key, value: value))
				//value.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())))
			}
			self.init(string: components.URL!.absoluteString)
		} else {
			self.init(string: baseUrl)
		}
	}
}